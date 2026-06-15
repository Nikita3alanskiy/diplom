import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthApiService {
  // Automatically determine base URL based on platform
  static String get baseUrl => AppConfig.baseUrl;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userAvatarKey = 'user_avatar';
  static const String _isPremiumKey = 'is_premium';

  // Check if token exists
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get User Name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get User Email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get User Avatar URL
  // Get User Avatar URL
  static Future<String?> getUserAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey);
  }

  // Get isPremium status
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  // Save profile data locally (after profile edit)
  static Future<void> saveUserData({String? name, String? avatarUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_userNameKey, name);
    if (avatarUrl != null) await prefs.setString(_userAvatarKey, avatarUrl);
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        await _saveSession(data);
        return {'success': true};
      } else {
        // Handle error message from NestJS (usually in 'message' array or string)
        final errorMsg = _extractErrorMessage(data);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Помилка підключення до сервера: $e'};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _saveSession(data);
        return {'success': true};
      } else {
        final errorMsg = _extractErrorMessage(data);
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Помилка підключення до сервера: $e'};
    }
  }

  // Logout
  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userAvatarKey);
    await prefs.remove(_isPremiumKey);
  }

  // Buy Premium (mock)
  static Future<bool> buyPremium() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/premium'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isPremiumKey, true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Helper: Save session data
  static Future<void> _saveSession(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = responseData['access_token'];
    final user = responseData['user'];
    
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    if (user != null) {
      await prefs.setString(_userNameKey, user['name'] ?? '');
      await prefs.setString(_userEmailKey, user['email'] ?? '');
      if (user['avatarUrl'] != null) {
        await prefs.setString(_userAvatarKey, user['avatarUrl']);
      }
      if (user['isPremium'] != null) {
        await prefs.setBool(_isPremiumKey, user['isPremium']);
      }
    }
  }

  // Helper: Extract error message from NestJS validation or exception
  static String _extractErrorMessage(Map<String, dynamic> data) {
    final messageField = data['message'];
    if (messageField is List) {
      return messageField.join(', ');
    } else if (messageField is String) {
      return messageField;
    }
    return 'Невідома помилка сервера';
  }
}
