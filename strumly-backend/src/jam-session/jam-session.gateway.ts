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

interface JamMemberInfo {
  userId: number;
  name: string;
}

interface JamSession {
  sessionCode: string;
  hostSocketId: string;
  hostUserId: number;
  hostName: string;
  /** Single song mode */
  songId: number | null;
  /** Playlist mode */
  playlistId: number | null;
  playlistSongs: { id: number; title: string; artist: string; bpm?: number | null }[];
  currentSongIndex: number;
  /** Active members */
  memberSocketIds: Set<string>;
  memberInfo: Map<string, JamMemberInfo>;
  isScrolling: boolean;
  bpm: number | null;
  scrollSpeed: number;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'jam',
})
export class JamSessionGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  /** sessionCode → JamSession */
  private sessions = new Map<string, JamSession>();
  /** socketId → sessionCode */
  private socketToSession = new Map<string, string>();

  constructor(private readonly jwtService: JwtService) {}

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
      client.data.userId = payload.sub as number;
      client.data.userName = (payload.name as string) || `User${payload.sub}`;
      console.log(
        `🎸 Jam: User ${payload.sub} connected (socket: ${client.id})`,
      );
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this._handleLeave(client);
    console.log(`🎸 Jam: socket ${client.id} disconnected`);
  }

  // ─── Helpers ───────────────────────────────────────────────

  private _handleLeave(client: Socket) {
    const code = this.socketToSession.get(client.id);
    if (!code) return;
    const session = this.sessions.get(code);
    if (!session) return;

    const isHost = session.hostSocketId === client.id;
    session.memberSocketIds.delete(client.id);
    session.memberInfo.delete(client.id);
    this.socketToSession.delete(client.id);

    if (isHost) {
      // End session for everyone
      this.server.to(code).emit('sessionEnded', { reason: 'host_left' });
      this.sessions.delete(code);
    } else {
      this.server.to(code).emit('memberLeft', {
        userId: client.data.userId,
        memberCount: session.memberSocketIds.size,
        members: this._serializeMembers(session),
      });
    }
  }

  private _generateCode(): string {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
  }

  private _serializeMembers(session: JamSession) {
    const result: JamMemberInfo[] = [];
    for (const info of session.memberInfo.values()) {
      result.push(info);
    }
    return result;
  }

  private _sessionSnapshot(session: JamSession) {
    return {
      sessionCode: session.sessionCode,
      songId: session.songId,
      playlistId: session.playlistId,
      playlistSongs: session.playlistSongs,
      currentSongIndex: session.currentSongIndex,
      isScrolling: session.isScrolling,
      bpm: session.bpm,
      scrollSpeed: session.scrollSpeed,
      hostUserId: session.hostUserId,
      hostName: session.hostName,
      memberCount: session.memberSocketIds.size,
      members: this._serializeMembers(session),
    };
  }

  // ─── Events ────────────────────────────────────────────────

  @SubscribeMessage('createSession')
  handleCreateSession(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      songId?: number;
      playlistId?: number;
      playlistSongs?: {
        id: number;
        title: string;
        artist: string;
        bpm?: number | null;
      }[];
      currentSongIndex?: number;
    },
  ) {
    const userId = client.data.userId as number;
    if (!userId) return;

    let code: string;
    do {
      code = this._generateCode();
    } while (this.sessions.has(code));

    const session: JamSession = {
      sessionCode: code,
      hostSocketId: client.id,
      hostUserId: userId,
      hostName: client.data.userName as string,
      songId: data.songId ?? null,
      playlistId: data.playlistId ?? null,
      playlistSongs: data.playlistSongs ?? [],
      currentSongIndex: data.currentSongIndex ?? 0,
      memberSocketIds: new Set([client.id]),
      memberInfo: new Map([
        [
          client.id,
          { userId, name: client.data.userName as string },
        ],
      ]),
      isScrolling: false,
      bpm: null,
      scrollSpeed: 40,
    };

    this.sessions.set(code, session);
    this.socketToSession.set(client.id, code);
    client.join(code);

    console.log(`🎸 Session created: ${code} by user ${userId}`);

    client.emit('sessionCreated', { sessionCode: code });
  }

  @SubscribeMessage('joinSession')
  handleJoinSession(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { sessionCode: string },
  ) {
    const session = this.sessions.get(data.sessionCode);
    if (!session) {
      client.emit('joinError', { message: 'Сесію не знайдено' });
      return;
    }
    if (session.memberSocketIds.size >= 8) {
      client.emit('joinError', {
        message: 'Сесія заповнена (максимум 8 учасників)',
      });
      return;
    }

    const userId = client.data.userId as number;
    session.memberSocketIds.add(client.id);
    session.memberInfo.set(client.id, {
      userId,
      name: client.data.userName as string,
    });
    this.socketToSession.set(client.id, data.sessionCode);
    client.join(data.sessionCode);

    // Send current state to newcomer
    client.emit('sessionState', this._sessionSnapshot(session));

    // Notify all others in room
    this.server.to(data.sessionCode).emit('memberJoined', {
      userId,
      name: client.data.userName,
      memberCount: session.memberSocketIds.size,
      members: this._serializeMembers(session),
    });

    console.log(
      `🎸 User ${userId} joined session ${data.sessionCode} (${session.memberSocketIds.size} members)`,
    );
  }

  @SubscribeMessage('leaveSession')
  handleLeaveSession(@ConnectedSocket() client: Socket) {
    client.leave(this.socketToSession.get(client.id) ?? '');
    this._handleLeave(client);
  }

  @SubscribeMessage('startScroll')
  handleStartScroll(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      bpm: number | null;
      scrollSpeed: number;
      startTimestamp: number;
    },
  ) {
    const code = this.socketToSession.get(client.id);
    const session = code ? this.sessions.get(code) : null;
    if (!session || session.hostSocketId !== client.id) return;

    session.isScrolling = true;
    session.bpm = data.bpm;
    session.scrollSpeed = data.scrollSpeed;

    this.server.to(code!).emit('scrollStarted', {
      bpm: data.bpm,
      scrollSpeed: data.scrollSpeed,
      startTimestamp: data.startTimestamp,
    });
  }

  @SubscribeMessage('stopScroll')
  handleStopScroll(@ConnectedSocket() client: Socket) {
    const code = this.socketToSession.get(client.id);
    const session = code ? this.sessions.get(code) : null;
    if (!session || session.hostSocketId !== client.id) return;

    session.isScrolling = false;
    this.server.to(code!).emit('scrollStopped', {});
  }

  @SubscribeMessage('updateScrollSpeed')
  handleUpdateScrollSpeed(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { scrollSpeed: number },
  ) {
    const code = this.socketToSession.get(client.id);
    const session = code ? this.sessions.get(code) : null;
    if (!session || session.hostSocketId !== client.id) return;

    session.scrollSpeed = data.scrollSpeed;
    this.server.to(code!).emit('scrollSpeedUpdated', {
      scrollSpeed: data.scrollSpeed,
    });
  }

  @SubscribeMessage('updateBpm')
  handleUpdateBpm(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { bpm: number },
  ) {
    const code = this.socketToSession.get(client.id);
    const session = code ? this.sessions.get(code) : null;
    if (!session || session.hostSocketId !== client.id) return;

    session.bpm = data.bpm;
    this.server.to(code!).emit('bpmUpdated', {
      bpm: data.bpm,
    });
  }

  @SubscribeMessage('changeSong')
  handleChangeSong(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { songIndex: number; songId: number },
  ) {
    const code = this.socketToSession.get(client.id);
    const session = code ? this.sessions.get(code) : null;
    if (!session || session.hostSocketId !== client.id) return;

    session.currentSongIndex = data.songIndex;
    session.songId = data.songId;
    session.isScrolling = false;

    this.server.to(code!).emit('songChanged', {
      songIndex: data.songIndex,
      songId: data.songId,
    });
  }
}
