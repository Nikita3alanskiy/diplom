import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';

import '../config/app_config.dart';

class CatalogApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/catalog';

  static Future<List<Map<String, dynamic>>> search(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to search catalog: ${response.body}');
  }

  static Future<Map<String, dynamic>> importSong(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/import'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to import song: ${response.body}');
  }
}
