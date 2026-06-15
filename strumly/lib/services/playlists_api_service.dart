import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';
import '../config/app_config.dart';

class PlaylistsApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/playlists';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getPlaylists() async {
    final response = await http.get(Uri.parse(baseUrl), headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load playlists');
  }

  static Future<Map<String, dynamic>> createPlaylist(String title) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create playlist');
  }

  static Future<void> deletePlaylist(int playlistId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$playlistId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete playlist');
    }
  }

  static Future<void> renamePlaylist(int playlistId, String title) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$playlistId'),
      headers: await _headers(),
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rename playlist');
    }
  }

  static Future<List<Map<String, dynamic>>> getPlaylistSongs(int playlistId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$playlistId/songs'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load playlist songs');
  }

  static Future<void> addSong(int playlistId, int songId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$playlistId/songs/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add song to playlist');
    }
  }

  static Future<void> removeSong(int playlistId, int songId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$playlistId/songs/$songId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove song from playlist');
    }
  }
}
