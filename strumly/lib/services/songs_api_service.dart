import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class SongsApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/songs';
    } else {
      return 'http://localhost:3000/api/songs';
    }
  }

  static String get serverBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static Future<List<Song>> getSongs() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Song.fromJson(json)).toList();
    }
    throw Exception('Failed to load songs: ${response.statusCode}');
  }

  static Future<Song> getSong(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return Song.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load song: ${response.statusCode}');
  }

  static Future<Song> createSong(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Song.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create song: ${response.body}');
  }

  static Future<void> deleteSong(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete song');
    }
  }

  static Future<String> uploadAudio(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Повертаємо відносний шлях як абсолютний з урахуванням baseUrl
      return serverBaseUrl + data['url'];
    }
    throw Exception('Failed to upload audio: ${response.body}');
  }

  static Future<Song> parseSong(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/parse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Song.fromJson(jsonDecode(response.body));
    }
    
    // Спробуємо дістати повідомлення про помилку від бекенду
    try {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to parse song');
    } catch (_) {
      throw Exception('Failed to parse song: ${response.statusCode}');
    }
  }
}
