import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import 'auth_api_service.dart';

class PaymentService {
  static String get baseUrl => '${AppConfig.baseUrl}/payments';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthApiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a checkout session and open it in the browser
  static Future<void> createCheckoutSession() async {
    // Determine the base url to pass as returnUrl to Stripe (to correctly handle Android emulator vs physical device vs iOS)
    final returnUrl = AppConfig.baseUrl.replaceAll('/api', '');
    
    final response = await http.post(
      Uri.parse('$baseUrl/create-checkout-session'),
      headers: await _headers(),
      body: jsonEncode({'returnUrl': returnUrl}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final url = data['url'] as String;

      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView)) {
        throw Exception('Could not launch payment URL');
      }
    } else {
      String errorMessage = 'Failed to create checkout session';
      try {
        final errData = jsonDecode(response.body);
        if (errData['message'] != null) {
          errorMessage = 'Server error: ${errData['message']}';
        } else {
          errorMessage = 'Server error: ${response.body}';
        }
      } catch (_) {
        errorMessage = 'Server error (${response.statusCode}): ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }
}
