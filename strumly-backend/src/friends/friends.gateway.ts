import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { FriendsService } from './friends.service';
import { PrismaService } from '../prisma.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: 'chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  // userId -> Set<socketId>
  private userSockets = new Map<number, Set<string>>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly friendsService: FriendsService,
    private readonly prisma: PrismaService,
  ) {}

  handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.split(' ')[1];

      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: 'super-secret-key',
      });

      client.data.userId = payload.sub;

      if (!this.userSockets.has(payload.sub)) {
        this.userSockets.set(payload.sub, new Set());
      }
      this.userSockets.get(payload.sub)!.add(client.id);

      console.log(`🔌 User ${payload.sub} connected (socket: ${client.id})`);
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId) {
      const sockets = this.userSockets.get(userId);
      sockets?.delete(client.id);
      if (sockets?.size === 0) {
        this.userSockets.delete(userId);
      }
    }
    console.log(`❌ Socket disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinRoom')
  handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { friendshipId: number },
  ) {
    client.join(`room_${data.friendshipId}`);
    return { event: 'joinedRoom', data: { friendshipId: data.friendshipId } };
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { friendshipId: number; content: string },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    try {
      const message = await this.friendsService.saveMessage(
        data.friendshipId,
        senderId,
        data.content,
      );

      // Відправляємо повідомлення всім у кімнаті (включно з відправником)
      this.server.to(`room_${data.friendshipId}`).emit('newMessage', {
        id: message.id,
        friendshipId: message.friendshipId,
        senderId: message.senderId,
        senderName: message.sender.name,
        content: message.content,
        createdAt: message.createdAt,
      });

      // Send a notification to the receiver specifically
      const friendship = await this.prisma.friendship.findUnique({ where: { id: data.friendshipId } });
      if (friendship) {
        const receiverId = friendship.senderId === senderId ? friendship.receiverId : friendship.senderId;
        const targetSockets = this.userSockets.get(receiverId);
        if (targetSockets) {
          for (const socketId of targetSockets) {
            this.server.to(socketId).emit('messageNotification', {
              friendshipId: data.friendshipId,
            });
          }
        }
      }
    } catch (e) {
      client.emit('error', { message: (e as Error).message });
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { friendshipId: number; isTyping: boolean },
  ) {
    const senderId = client.data.userId;
    client.to(`room_${data.friendshipId}`).emit('userTyping', {
      userId: senderId,
      isTyping: data.isTyping,
    });
  }

  /**
   * Host broadcasts a Jam Session invite to a specific friend by userId.
   * The friend receives 'sessionInviteReceived' on their socket(s).
   */
  @SubscribeMessage('sessionInvite')
  handleSessionInvite(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      friendUserId: number;
      sessionCode: string;
      songTitle: string;
      songId: number | null;
      playlistId: number | null;
      playlistTitle: string | null;
    },
  ) {
    const hostUserId = client.data.userId as number;
    const hostName = client.data.userName as string | undefined ?? `User${hostUserId}`;

    const targetSockets = this.userSockets.get(data.friendUserId);
    if (!targetSockets) return; // friend is offline

    for (const socketId of targetSockets) {
      this.server.to(socketId).emit('sessionInviteReceived', {
        sessionCode: data.sessionCode,
        songTitle: data.songTitle,
        songId: data.songId,
        playlistId: data.playlistId,
        playlistTitle: data.playlistTitle,
        hostName,
        hostUserId,
      });
    }
  }
}
