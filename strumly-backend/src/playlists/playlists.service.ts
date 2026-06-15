import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class PlaylistsService {
  constructor(private prisma: PrismaService) {}

  async getPlaylists(userId: number) {
    return this.prisma.playlist.findMany({
      where: { userId },
      include: {
        songs: {
          orderBy: { order: 'asc' },
          include: {
            song: { select: { id: true, title: true, artist: true, chords: true, lyrics: true, youtubeUrl: true, bpm: true, createdAt: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createPlaylist(userId: number, title: string) {
    return this.prisma.playlist.create({
      data: { userId, title },
    });
  }

  async renamePlaylist(userId: number, playlistId: number, title: string) {
    await this.assertOwner(userId, playlistId);
    return this.prisma.playlist.update({ where: { id: playlistId }, data: { title } });
  }

  async deletePlaylist(userId: number, playlistId: number) {
    await this.assertOwner(userId, playlistId);
    await this.prisma.playlist.delete({ where: { id: playlistId } });
    return { success: true };
  }

  async addSong(userId: number, playlistId: number, songId: number) {
    await this.assertOwner(userId, playlistId);
    const count = await this.prisma.playlistSong.count({ where: { playlistId } });
    return this.prisma.playlistSong.upsert({
      where: { playlistId_songId: { playlistId, songId } },
      create: { playlistId, songId, order: count },
      update: {},
    });
  }

  async removeSong(userId: number, playlistId: number, songId: number) {
    await this.assertOwner(userId, playlistId);
    await this.prisma.playlistSong.deleteMany({ where: { playlistId, songId } });
    return { success: true };
  }

  async getPlaylistSongs(userId: number, playlistId: number) {
    await this.assertOwner(userId, playlistId);
    const rows = await this.prisma.playlistSong.findMany({
      where: { playlistId },
      orderBy: { order: 'asc' },
      include: {
        song: { select: { id: true, title: true, artist: true, chords: true, lyrics: true, youtubeUrl: true, audioUrl: true, bpm: true, createdAt: true } },
      },
    });
    return rows.map(r => r.song);
  }

  private async assertOwner(userId: number, playlistId: number) {
    const pl = await this.prisma.playlist.findUnique({ where: { id: playlistId } });
    if (!pl) throw new NotFoundException('Playlist not found');
    if (pl.userId !== userId) throw new ForbiddenException('Not your playlist');
  }
}
