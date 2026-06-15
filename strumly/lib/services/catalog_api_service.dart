import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api_service.dart';

class CatalogApiService {
  // baseUrl = http://10.0.2.2:3000/api/catalog
  static String get baseUrl {
    // AuthApiService.baseUrl = http://10.0.2.2:3000/api (ends with /api)
    // We just replace /auth-related suffix and append /catalog
    return '${AuthApiService.baseUrl.replaceAll('/auth', '')}/catalog';
  }

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
