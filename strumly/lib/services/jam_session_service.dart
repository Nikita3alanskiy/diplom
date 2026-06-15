import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_api_service.dart';

import '../config/app_config.dart';

/// Singleton service that manages the /jam WebSocket namespace.
/// Connects independently from the chat socket.
class JamSessionService {
  static JamSessionService? _instance;
  static JamSessionService get instance =>
      _instance ??= JamSessionService._();
  JamSessionService._();

  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String get _serverUrl => AppConfig.wsBaseUrl;

  // ─── Connection ────────────────────────────────────────────

  Future<void> connect() async {
    if (_isConnected) return;
    final token = await AuthApiService.getToken();
    if (token == null) return;

    _socket = io.io(
      '$_serverUrl/jam',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      print('🎸 Jam socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('🎸 Jam socket disconnected');
    });

    _socket!.onError((e) => print('🎸 Jam socket error: $e'));

    // Wait a tick for connection
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // ─── Emits ─────────────────────────────────────────────────

  /// Host: create a new jam session.
  void createSession({
    int? songId,
    int? playlistId,
    List<Map<String, dynamic>>? playlistSongs,
    int currentSongIndex = 0,
  }) {
    _socket?.emit('createSession', {
      if (songId != null) 'songId': songId,
      if (playlistId != null) 'playlistId': playlistId,
      if (playlistSongs != null) 'playlistSongs': playlistSongs,
      'currentSongIndex': currentSongIndex,
    });
  }

  /// Guest: join an existing session by code.
  void joinSession(String sessionCode) {
    _socket?.emit('joinSession', {'sessionCode': sessionCode});
  }

  /// Any participant: leave the session.
  void leaveSession() {
    _socket?.emit('leaveSession', {});
  }

  /// Host: start synchronised scroll.
  void startScroll({required int? bpm, required double scrollSpeed}) {
    _socket?.emit('startScroll', {
      'bpm': bpm,
      'scrollSpeed': scrollSpeed,
      'startTimestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Host: stop scroll.
  void stopScroll() {
    _socket?.emit('stopScroll', {});
  }

  /// Host: update scroll speed while running.
  void updateScrollSpeed(double speed) {
    _socket?.emit('updateScrollSpeed', {'scrollSpeed': speed});
  }

  /// Host: update bpm
  void updateBpm(int bpm) {
    _socket?.emit('updateBpm', {'bpm': bpm});
  }

  /// Host: change current song in playlist mode.
  void changeSong(int songIndex, int songId) {
    _socket?.emit('changeSong', {'songIndex': songIndex, 'songId': songId});
  }

  // ─── Listeners ─────────────────────────────────────────────

  void onSessionCreated(void Function(String sessionCode) cb) {
    _socket?.on('sessionCreated', (data) {
      if (data is Map) cb(data['sessionCode'] as String);
    });
  }

  /// Fired when a guest first joins — full current state snapshot.
  void onSessionState(void Function(Map<String, dynamic> state) cb) {
    _socket?.on('sessionState', (data) {
      if (data is Map) cb(Map<String, dynamic>.from(data));
    });
  }

  void onScrollStarted(void Function(Map<String, dynamic> data) cb) {
    _socket?.on('scrollStarted', (data) {
      if (data is Map) cb(Map<String, dynamic>.from(data));
    });
  }

  void onScrollStopped(void Function() cb) {
    _socket?.on('scrollStopped', (_) => cb());
  }

  void onScrollSpeedUpdated(void Function(double speed) cb) {
    _socket?.on('scrollSpeedUpdated', (data) {
      if (data is Map) {
        cb((data['scrollSpeed'] as num).toDouble());
      }
    });
  }

  void onBpmUpdated(void Function(int bpm) cb) {
    _socket?.on('bpmUpdated', (data) {
      if (data is Map) {
        cb(data['bpm'] as int);
      }
    });
  }

  void onMemberJoined(void Function(Map<String, dynamic> data) cb) {
    _socket?.on('memberJoined', (data) {
      if (data is Map) cb(Map<String, dynamic>.from(data));
    });
  }

  void onMemberLeft(void Function(Map<String, dynamic> data) cb) {
    _socket?.on('memberLeft', (data) {
      if (data is Map) cb(Map<String, dynamic>.from(data));
    });
  }

  void onSessionEnded(void Function(String reason) cb) {
    _socket?.on('sessionEnded', (data) {
      if (data is Map) cb(data['reason'] as String? ?? 'unknown');
    });
  }

  void onSongChanged(void Function(int songIndex, int songId) cb) {
    _socket?.on('songChanged', (data) {
      if (data is Map) {
        cb(data['songIndex'] as int, data['songId'] as int);
      }
    });
  }

  void onJoinError(void Function(String message) cb) {
    _socket?.on('joinError', (data) {
      if (data is Map) cb(data['message'] as String? ?? 'Помилка');
    });
  }

  /// Remove all listeners (call in dispose).
  void offAll() {
    _socket?.off('sessionCreated');
    _socket?.off('sessionState');
    _socket?.off('scrollStarted');
    _socket?.off('scrollStopped');
    _socket?.off('scrollSpeedUpdated');
    _socket?.off('bpmUpdated');
    _socket?.off('memberJoined');
    _socket?.off('memberLeft');
    _socket?.off('sessionEnded');
    _socket?.off('songChanged');
    _socket?.off('joinError');
  }
}
