import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  // Пошук користувача за email або ім'ям
  async searchUser(query: string, currentUserId: number) {
    const users = await this.prisma.user.findMany({
      where: {
        AND: [
          { id: { not: currentUserId } },
          {
            OR: [
              { email: { contains: query, mode: 'insensitive' } },
              { name: { contains: query, mode: 'insensitive' } },
            ],
          },
        ],
      },
      select: { id: true, name: true, email: true, avatarUrl: true },
      take: 10,
    });
    return users;
  }

  // Надіслати запит у друзі
  async sendRequest(senderId: number, targetEmail: string) {
    const receiver = await this.prisma.user.findUnique({
      where: { email: targetEmail },
    });
    if (!receiver) throw new NotFoundException('Користувача не знайдено');
    if (receiver.id === senderId)
      throw new BadRequestException('Не можна додати себе в друзі');

    const existing = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { senderId, receiverId: receiver.id },
          { senderId: receiver.id, receiverId: senderId },
        ],
      },
    });
    if (existing) {
      if (existing.status === 'accepted')
        throw new BadRequestException('Ви вже друзі');
      if (existing.status === 'pending')
        throw new BadRequestException('Запит вже надіслано');
    }

    return this.prisma.friendship.create({
      data: { senderId, receiverId: receiver.id, status: 'pending' },
      include: {
        receiver: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
    });
  }

  // Вхідні запити в друзі
  async getIncomingRequests(userId: number) {
    return this.prisma.friendship.findMany({
      where: { receiverId: userId, status: 'pending' },
      include: {
        sender: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // Список друзів (прийняті запити)
  async getFriends(userId: number) {
    const friendships = await this.prisma.friendship.findMany({
      where: {
        OR: [
          { senderId: userId, status: 'accepted' },
          { receiverId: userId, status: 'accepted' },
        ],
      },
      include: {
        sender: { select: { id: true, name: true, email: true, avatarUrl: true } },
        receiver: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
    });

    return friendships.map((f) => ({
      friendshipId: f.id,
      friend: f.senderId === userId ? f.receiver : f.sender,
    }));
  }

  // Прийняти запит
  async acceptRequest(friendshipId: number, userId: number) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
    });
    if (!friendship) throw new NotFoundException('Запит не знайдено');
    if (friendship.receiverId !== userId)
      throw new ForbiddenException('Немає доступу');

    return this.prisma.friendship.update({
      where: { id: friendshipId },
      data: { status: 'accepted' },
      include: {
        sender: { select: { id: true, name: true, email: true, avatarUrl: true } },
      },
    });
  }

  // Відхилити або видалити з друзів
  async rejectOrRemove(friendshipId: number, userId: number) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
    });
    if (!friendship) throw new NotFoundException('Не знайдено');
    if (
      friendship.senderId !== userId &&
      friendship.receiverId !== userId
    )
      throw new ForbiddenException('Немає доступу');

    await this.prisma.friendship.delete({ where: { id: friendshipId } });
    return { success: true };
  }

  // Отримати повідомлення чату
  async getMessages(friendshipId: number, userId: number) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
    });
    if (!friendship) throw new NotFoundException('Чат не знайдено');
    if (
      friendship.senderId !== userId &&
      friendship.receiverId !== userId
    )
      throw new ForbiddenException('Немає доступу до цього чату');

    return this.prisma.message.findMany({
      where: { friendshipId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: { id: true, name: true } },
      },
    });
  }

  // Зберегти повідомлення (викликається з WebSocket gateway)
  async saveMessage(friendshipId: number, senderId: number, content: string) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
    });
    if (!friendship || friendship.status !== 'accepted')
      throw new ForbiddenException('Немає доступу до цього чату');
    if (
      friendship.senderId !== senderId &&
      friendship.receiverId !== senderId
    )
      throw new ForbiddenException('Немає доступу');

    return this.prisma.message.create({
      data: { friendshipId, senderId, content },
      include: {
        sender: { select: { id: true, name: true } },
      },
    });
  }
}
