import 'dart:io';

/// Central configuration for Strumly.
/// 
/// Local dev  → works out of the box (platform-aware localhost)
/// Production → flutter build apk --dart-define=API_BASE_URL=https://your-backend.onrender.com
class AppConfig {
  AppConfig._();

  static const String _defined = String.fromEnvironment('API_BASE_URL');

  /// Full base URL for REST API (no trailing slash).
  static String get baseUrl {
    if (_defined.isNotEmpty) return _defined;
    // Android emulator routes 10.0.2.2 → host machine
    return Platform.isAndroid
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  /// WebSocket / Socket.IO base (no /api suffix).
  static String get wsBaseUrl {
    if (_defined.isNotEmpty) {
      return _defined
          .replaceAll('/api', '')
          .replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://');
    }
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  /// HTTP origin without /api — used for file/upload URLs.
  static String get httpBaseUrl {
    if (_defined.isNotEmpty) {
      return _defined.replaceAll('/api', '');
    }
    return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }
}
