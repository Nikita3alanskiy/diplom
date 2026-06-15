import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}

  async updateProfile(userId: number, name?: string, avatarUrl?: string) {
    const data: any = {};
    if (name !== undefined) data.name = name;
    if (avatarUrl !== undefined) data.avatarUrl = avatarUrl;
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, name: true, email: true, avatarUrl: true, isPremium: true },
    });
  }

  async getCoverVideos(userId: number) {
    return this.prisma.coverVideo.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async addCoverVideo(userId: number, videoUrl: string, title?: string) {
    return this.prisma.coverVideo.create({
      data: { userId, videoUrl, title },
    });
  }

  async deleteCoverVideo(userId: number, videoId: number) {
    const video = await this.prisma.coverVideo.findUnique({ where: { id: videoId } });
    if (!video) throw new NotFoundException('Video not found');
    if (video.userId !== userId) throw new ForbiddenException('Not your video');
    await this.prisma.coverVideo.delete({ where: { id: videoId } });
    return { success: true };
  }

  async getPublicProfile(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        avatarUrl: true,
        coverVideos: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }
}
