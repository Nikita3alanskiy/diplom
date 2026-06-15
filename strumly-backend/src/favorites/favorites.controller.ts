import { Controller, Get, Post, Delete, Param, ParseIntPipe, Req, UseGuards, BadRequestException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';

@ApiTags('Обрані')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  private getUserId(req: any): number {
    const id = Number(req.user?.sub ?? req.user?.id);
    if (!id || isNaN(id)) throw new BadRequestException('Invalid token. Please re-login.');
    return id;
  }

  @Get()
  @ApiOperation({ summary: 'Список обраних пісень' })
  getFavorites(@Req() req) {
    return this.favoritesService.getFavorites(this.getUserId(req));
  }

  @Post(':songId')
  @ApiOperation({ summary: 'Додати пісню в обрані' })
  addFavorite(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    return this.favoritesService.addFavorite(this.getUserId(req), songId);
  }

  @Delete(':songId')
  @ApiOperation({ summary: 'Прибрати пісню з обраних' })
  removeFavorite(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    return this.favoritesService.removeFavorite(this.getUserId(req), songId);
  }

  @Get(':songId/status')
  @ApiOperation({ summary: 'Перевірити чи пісня в обраних' })
  async isFavorite(@Req() req, @Param('songId', ParseIntPipe) songId: number) {
    const favorite = await this.favoritesService.isFavorite(this.getUserId(req), songId);
    return { favorite };
  }
}
