import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';
import '../config/app_config.dart';

class PlayedApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/played';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getPlayedSongs() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load played songs: ${response.statusCode}');
  }

  static Future<void> markAsPlayed(int songId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to mark song as played: ${response.body}');
    }
  }

  static Future<void> unmarkAsPlayed(int songId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unmark song: ${response.body}');
    }
  }

  static Future<bool> isPlayed(int songId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$songId/status'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['played'] == true;
    }
    return false;
  }
}
