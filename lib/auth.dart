import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiManager {
  static const String _baseUrl = "https://fs-mt.qwerty123.tech";
  static const String _secretKey = "2jukqvNnhunHWMBRRVcZ9ZQ9";
  static const String _sessionTokenKey = "session_token";

  static Future<String> getSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionToken = prefs.getString(_sessionTokenKey);
    if (sessionToken != null) {
      return sessionToken;
    } else {
      http.Response response = await http.post(Uri.parse("$_baseUrl/auth/session"));
      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);
        if (body["success"] == true && body["data"] != null) {
          sessionToken = body["data"]["sessionToken"];
          await prefs.setString(_sessionTokenKey, sessionToken!);
          return sessionToken;
        }
      }
      throw Exception("Failed to get session token");
    }
  }

  static Future<String> getAccessToken(String deviceId) async {
    String sessionToken = await getSessionToken();
    String signature = _calculateSignature(sessionToken);
    http.Response response = await http.post(Uri.parse("$_baseUrl/auth/token"), body: {
      "sessionToken": sessionToken,
      "signature": signature,
      "deviceId": deviceId,
    });
    if (response.statusCode == 200) {
      Map<String, dynamic> body = json.decode(response.body);
      if (body["success"] == true && body["data"] != null) {
        return body["data"]["sessionToken"];
      }
    }
    throw Exception("Failed to get access token");
  }

  static String _calculateSignature(String sessionToken) {
    String message = sessionToken + _secretKey;
    List<int> bytes = utf8.encode(message);
    Digest digest = sha256.convert(bytes);
    return digest.toString();
  }
}
