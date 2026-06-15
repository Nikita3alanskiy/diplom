import {
  Controller, Get, Post, Put, Delete,
  Param, ParseIntPipe, Body, Req, UseGuards, BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PlaylistsService } from './playlists.service';

@ApiTags('Плейлісти')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('playlists')
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  private getUserId(req: any): number {
    const id = Number(req.user?.sub ?? req.user?.id);
    if (!id || isNaN(id)) throw new BadRequestException('Invalid token. Please re-login.');
    return id;
  }

  @Get()
  @ApiOperation({ summary: 'Всі плейлісти користувача' })
  getPlaylists(@Req() req) {
    return this.playlistsService.getPlaylists(this.getUserId(req));
  }

  @Post()
  @ApiOperation({ summary: 'Створити плейліст' })
  createPlaylist(@Req() req, @Body() body: { title: string }) {
    return this.playlistsService.createPlaylist(this.getUserId(req), body.title);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Перейменувати плейліст' })
  rename(@Req() req, @Param('id', ParseIntPipe) id: number, @Body() body: { title: string }) {
    return this.playlistsService.renamePlaylist(this.getUserId(req), id, body.title);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Видалити плейліст' })
  delete(@Req() req, @Param('id', ParseIntPipe) id: number) {
    return this.playlistsService.deletePlaylist(this.getUserId(req), id);
  }

  @Get(':id/songs')
  @ApiOperation({ summary: 'Пісні плейліста' })
  getSongs(@Req() req, @Param('id', ParseIntPipe) id: number) {
    return this.playlistsService.getPlaylistSongs(this.getUserId(req), id);
  }

  @Post(':id/songs/:songId')
  @ApiOperation({ summary: 'Додати пісню в плейліст' })
  addSong(
    @Req() req,
    @Param('id', ParseIntPipe) id: number,
    @Param('songId', ParseIntPipe) songId: number,
  ) {
    return this.playlistsService.addSong(this.getUserId(req), id, songId);
  }

  @Delete(':id/songs/:songId')
  @ApiOperation({ summary: 'Видалити пісню з плейліста' })
  removeSong(
    @Req() req,
    @Param('id', ParseIntPipe) id: number,
    @Param('songId', ParseIntPipe) songId: number,
  ) {
    return this.playlistsService.removeSong(this.getUserId(req), id, songId);
  }
}
