import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class PlayedService {
  constructor(private readonly prisma: PrismaService) {}

  async getPlayedSongs(userId: number) {
    const records = await this.prisma.playedSong.findMany({
      where: { userId },
      orderBy: { playedAt: 'desc' },
      include: {
        song: {
          select: {
            id: true,
            title: true,
            artist: true,
            chords: true,
            bpm: true,
            audioUrl: true,
          },
        },
      },
    });
    return records.map((r) => ({
      ...r.song,
      playedAt: r.playedAt,
    }));
  }

  async markAsPlayed(userId: number, songId: number) {
    try {
      // Перевіряємо, чи пісня існує
      const songExists = await this.prisma.song.findUnique({
        where: { id: songId },
      });
      if (!songExists) {
        throw new Error(`Song with id ${songId} not found`);
      }

      return await this.prisma.playedSong.upsert({
        where: { userId_songId: { userId, songId } },
        create: { userId, songId },
        update: { playedAt: new Date() },
      });
    } catch (e: any) {
      console.error('Error marking as played:', e);
      throw new Error(`Failed to mark as played: ${e.message}`);
    }
  }

  async unmarkAsPlayed(userId: number, songId: number) {
    await this.prisma.playedSong.deleteMany({
      where: { userId, songId },
    });
    return { success: true };
  }

  async isPlayed(userId: number, songId: number): Promise<boolean> {
    const record = await this.prisma.playedSong.findUnique({
      where: { userId_songId: { userId, songId } },
    });
    return !!record;
  }
}
