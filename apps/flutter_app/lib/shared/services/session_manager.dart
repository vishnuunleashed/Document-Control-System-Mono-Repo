import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static String? _token;
  static Map<String, dynamic>? _user;

  static String? get token => _token;
  static Map<String, dynamic>? get user => _user;
  
  static bool get isAuthenticated => _token != null;
  static String get userRole => _user?['role'] ?? 'Employee';
  static String get userName => _user?['name'] ?? 'User';
  static String get userId => _user?['_id'] ?? '';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      final userString = prefs.getString('user');
      if (userString != null) {
        _user = jsonDecode(userString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Session load failed
    }
  }

  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));
    } catch (e) {
      // Session save failed
    }
  }

  static Future<void> clearSession() async {
    _token = null;
    _user = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      // Session clear failed
    }
  }
}
