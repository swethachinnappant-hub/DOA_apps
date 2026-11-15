import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static String? _storedToken;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _storedToken = prefs.getString(_tokenKey);
  }

  static String? getToken() => _storedToken;

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _storedToken = token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _storedToken = null;
  }

  static Future<bool> hasToken() async => _storedToken != null;
}