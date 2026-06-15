import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_api_service.dart';

class ProfileApiService {
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/profile';
    return 'http://localhost:3000/api/profile';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> updateName(String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: await _headers(),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update name: ${response.body}');
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load user profile: ${response.body}');
  }

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final token = await AuthApiService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/avatar'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to upload avatar: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> getCoverVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/videos'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load videos');
  }

  static Future<Map<String, dynamic>> uploadCoverVideo(File videoFile, {String? title}) async {
    final token = await AuthApiService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/videos'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (title != null) request.fields['title'] = title;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      videoFile.path,
      contentType: MediaType.parse('video/mp4'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to upload video: ${response.body}');
  }

  static Future<void> deleteCoverVideo(int videoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/videos/$videoId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete video');
    }
  }
}
