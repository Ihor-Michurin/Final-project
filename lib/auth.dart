import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const _baseUrl = 'https://fs-mt.qwerty123.tech/api';

  static Future<String> getSessionToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/session'),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final sessionToken = jsonData['data']['sessionToken'];
      return sessionToken;
    } else {
      throw Exception('Failed to get session token');
    }
  }

  static Future<String> getAccessToken(String sessionToken) async {
    final secretKey = '2jukqvNnhunHWMBRRVcZ9ZQ9';
    final signature = sha256.convert(utf8.encode('$sessionToken$secretKey')).toString();
    final deviceId = 'test_device_id'; // replace with your device id logic

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sessionToken': sessionToken,
        'signature': signature,
        'deviceId': deviceId,
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final accessToken = jsonData['data']['sessionToken'];
      return accessToken;
    } else {
      throw Exception('Failed to get access token');
    }
  }

  static Future<void> storeAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
  }

  static Future<String?> getAccessTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
