import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  async getFavorites(userId: number) {
    const records = await this.prisma.favoriteSong.findMany({
      where: { userId },
      include: {
        song: { select: { id: true, title: true, artist: true, chords: true, youtubeUrl: true, bpm: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return records.map(r => r.song);
  }

  async addFavorite(userId: number, songId: number) {
    return this.prisma.favoriteSong.upsert({
      where: { userId_songId: { userId, songId } },
      create: { userId, songId },
      update: {},
    });
  }

  async removeFavorite(userId: number, songId: number) {
    await this.prisma.favoriteSong.deleteMany({ where: { userId, songId } });
    return { success: true };
  }

  async isFavorite(userId: number, songId: number): Promise<boolean> {
    const f = await this.prisma.favoriteSong.findUnique({
      where: { userId_songId: { userId, songId } },
    });
    return f !== null;
  }
}
