// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  // Helper function to encode data as URL-encoded form data.
  String _encodeFormData(Map<String, dynamic> data) {
    return data.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Use the base URL from HttpService
    final url = Uri.parse('${HttpService.baseUrl}/api/v1/passport/auth/login');
    // Encode the body as URL-encoded form data
    final body = _encodeFormData({"email": email, "password": password});
    // Set the header to let the backend know you're sending form data
    final headers = {
      'User-Agent': 'Homiefroxy/1.4',
      'Content-Type': 'application/x-www-form-urlencoded'
    };

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Login failed: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String inviteCode, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _httpService.postRequest(
      "/api/v1/passport/comm/sendEmailVerify",
      {'email': email},
    );
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }
}
