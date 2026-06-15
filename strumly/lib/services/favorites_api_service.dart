import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';
import '../config/app_config.dart';

class FavoritesApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/favorites';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await http.get(Uri.parse(baseUrl), headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load favorites: ${response.statusCode}');
  }

  static Future<void> addFavorite(int songId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add favorite: ${response.body}');
    }
  }

  static Future<void> removeFavorite(int songId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove favorite: ${response.body}');
    }
  }

  static Future<bool> isFavorite(int songId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$songId/status'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorite'] == true;
    }
    return false;
  }
}
