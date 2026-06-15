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
