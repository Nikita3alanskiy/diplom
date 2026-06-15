import {
  Controller, Get, Post, Delete,
  Param, Req, UseGuards, ParseIntPipe, BadRequestException,
} from '@nestjs/common';
import { PlayedService } from './played.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';

@ApiTags('Зіграні пісні')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('played')
export class PlayedController {
  constructor(private readonly playedService: PlayedService) {}

  private getUserId(req: any): number {
    const id = Number(req.user?.sub ?? req.user?.id);
    if (!id || isNaN(id)) {
      throw new BadRequestException('Invalid token. Please re-login.');
    }
    return id;
  }

  @Get()
  @ApiOperation({ summary: 'Список зіграних пісень поточного користувача' })
  getPlayedSongs(@Req() req) {
    return this.playedService.getPlayedSongs(this.getUserId(req));
  }

  @Post(':songId')
  @ApiOperation({ summary: 'Позначити пісню як зіграну' })
  markAsPlayed(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    return this.playedService.markAsPlayed(this.getUserId(req), songId);
  }

  @Delete(':songId')
  @ApiOperation({ summary: 'Зняти позначку "зіграна"' })
  unmarkAsPlayed(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    return this.playedService.unmarkAsPlayed(this.getUserId(req), songId);
  }

  @Get(':songId/status')
  @ApiOperation({ summary: 'Перевірити чи пісня зіграна' })
  async isPlayed(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    const played = await this.playedService.isPlayed(this.getUserId(req), songId);
    return { played };
  }
}
