import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  // ── Users ──────────────────────────────────────────────────────────

  async getUsers() {
    return this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        name: true,
        isPremium: true,
        premiumUntil: true,
        createdAt: true,
        avatarUrl: true,
      },
    });
  }

  async togglePremium(userId: number, isPremium: boolean) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        isPremium,
        premiumUntil: isPremium ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) : null,
      },
      select: {
        id: true,
        email: true,
        name: true,
        isPremium: true,
        premiumUntil: true,
      },
    });
  }

  async deleteUser(userId: number) {
    await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return this.prisma.user.delete({ where: { id: userId } });
  }

  // ── Songs ──────────────────────────────────────────────────────────

  async getSongs() {
    return this.prisma.song.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        creator: {
          select: { id: true, name: true, email: true },
        },
      },
    });
  }

  async createSong(data: {
    title: string;
    artist?: string;
    lyrics: string;
    chords: string;
    audioUrl?: string;
    youtubeUrl?: string;
    bpm?: number;
  }) {
    return this.prisma.song.create({ data });
  }

  async updateSong(
    songId: number,
    data: {
      title?: string;
      artist?: string;
      lyrics?: string;
      chords?: string;
      audioUrl?: string;
      youtubeUrl?: string;
      bpm?: number;
    },
  ) {
    await this.prisma.song.findUniqueOrThrow({ where: { id: songId } });
    return this.prisma.song.update({ where: { id: songId }, data });
  }

  async deleteSong(songId: number) {
    await this.prisma.song.findUniqueOrThrow({ where: { id: songId } });
    return this.prisma.song.delete({ where: { id: songId } });
  }

  // ── Chords ─────────────────────────────────────────────────────────

  async getChords() {
    return this.prisma.chord.findMany({ orderBy: { name: 'asc' } });
  }

  async createChord(data: {
    name: string;
    fingering: string;
    category?: string;
    difficulty?: string;
    description?: string;
  }) {
    return this.prisma.chord.create({ data });
  }

  async updateChord(
    chordId: number,
    data: {
      name?: string;
      fingering?: string;
      category?: string;
      difficulty?: string;
      description?: string;
    },
  ) {
    await this.prisma.chord.findUniqueOrThrow({ where: { id: chordId } });
    return this.prisma.chord.update({ where: { id: chordId }, data });
  }

  async deleteChord(chordId: number) {
    await this.prisma.chord.findUniqueOrThrow({ where: { id: chordId } });
    return this.prisma.chord.delete({ where: { id: chordId } });
  }

  // ── Stats ──────────────────────────────────────────────────────────

  async getStats() {
    const [totalUsers, premiumUsers, totalSongs, totalChords] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { isPremium: true } }),
      this.prisma.song.count(),
      this.prisma.chord.count(),
    ]);
    return { totalUsers, premiumUsers, totalSongs, totalChords };
  }
}
