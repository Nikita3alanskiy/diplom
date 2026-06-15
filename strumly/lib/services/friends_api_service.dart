import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';
import '../config/app_config.dart';

class FriendsApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/friends';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Пошук за email або ім'ям
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {'q': query},
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Список друзів
  static Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load friends');
  }

  // Вхідні запити
  static Future<List<Map<String, dynamic>>> getRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load requests');
  }

  // Надіслати запит за email
  static Future<Map<String, dynamic>> sendRequest(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to send request');
  }

  // Прийняти запит
  static Future<void> acceptRequest(int friendshipId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$friendshipId/accept'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to accept request');
    }
  }

  // Відхилити / видалити
  static Future<void> rejectOrRemove(int friendshipId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$friendshipId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject/remove');
    }
  }

  // Завантажити повідомлення чату
  static Future<List<Map<String, dynamic>>> getMessages(
      int friendshipId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$friendshipId/messages'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load messages');
  }
}
