import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_api_service.dart';

import '../config/app_config.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  SocketService._();

  io.Socket? _socket;
  bool _isConnected = false;

  // Unread message tracking: friendshipId -> count
  final Map<int, int> _unreadCounts = {};
  Map<int, int> get unreadCounts => _unreadCounts;

  String get _serverUrl => AppConfig.wsBaseUrl;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await AuthApiService.getToken();
    if (token == null) return;

    _socket = io.io(
      '$_serverUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      print('🔌 WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('❌ WebSocket disconnected');
    });

    _socket!.on('messageNotification', (data) {
      if (data is Map && data['friendshipId'] != null) {
        final fId = data['friendshipId'] as int;
        _unreadCounts[fId] = (_unreadCounts[fId] ?? 0) + 1;
        _onUnreadChanged?.call();
      }
    });

    _socket!.onError((e) {
      print('⚠️ Socket error: $e');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void joinRoom(int friendshipId) {
    _socket?.emit('joinRoom', {'friendshipId': friendshipId});
  }

  void sendMessage(int friendshipId, String content) {
    _socket?.emit('sendMessage', {
      'friendshipId': friendshipId,
      'content': content,
    });
  }

  void sendTyping(int friendshipId, bool isTyping) {
    _socket?.emit('typing', {
      'friendshipId': friendshipId,
      'isTyping': isTyping,
    });
  }

  void onNewMessage(void Function(Map<String, dynamic> msg) handler) {
    _socket?.on('newMessage', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void onUserTyping(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('userTyping', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void offNewMessage() {
    _socket?.off('newMessage');
  }

  void offUserTyping() {
    _socket?.off('userTyping');
  }

  // ─── Unread Messages ──────────────

  void Function()? _onUnreadChanged;

  void setUnreadListener(void Function() handler) {
    _onUnreadChanged = handler;
  }

  void clearUnread(int friendshipId) {
    if (_unreadCounts.containsKey(friendshipId)) {
      _unreadCounts.remove(friendshipId);
      _onUnreadChanged?.call();
    }
  }

  // ─── Jam Session Invites (via /chat namespace) ──────────────

  /// Host sends a session invite to a friend through the chat socket.
  void sendSessionInvite({
    required int friendUserId,
    required String sessionCode,
    required String songTitle,
    int? songId,
    int? playlistId,
    String? playlistTitle,
  }) {
    _socket?.emit('sessionInvite', {
      'friendUserId': friendUserId,
      'sessionCode': sessionCode,
      'songTitle': songTitle,
      'songId': songId,
      'playlistId': playlistId,
      'playlistTitle': playlistTitle,
    });
  }

  /// Listen for incoming jam session invites.
  void onSessionInviteReceived(
      void Function(Map<String, dynamic> data) handler) {
    _socket?.on('sessionInviteReceived', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void offSessionInviteReceived() {
    _socket?.off('sessionInviteReceived');
  }
}
