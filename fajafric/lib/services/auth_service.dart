import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey  = 'auth_user';

  // ── LOGIN ──────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: ApiConfig.headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(ApiConfig.timeout);

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _save(data['token'], data['user']);
      return {'ok': true, 'user': User.fromJson(data['user'])};
    }
    return {'ok': false, 'message': data['message'] ?? 'Erreur de connexion'};
  }

  // ── REGISTER ───────────────────────────────────────
  static Future<Map<String, dynamic>> register(Map<String, String> form) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: ApiConfig.headers(null),
      body: jsonEncode(form),
    ).timeout(ApiConfig.timeout);

    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await _save(data['token'], data['user']);
      return {'ok': true, 'user': User.fromJson(data['user'])};
    }
    return {'ok': false, 'message': data['message'] ?? 'Erreur d\'inscription'};
  }

  // ── LOGOUT ─────────────────────────────────────────
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/logout'),
        headers: ApiConfig.headers(token),
      ).timeout(ApiConfig.timeout).catchError((_) {});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ── HELPERS ────────────────────────────────────────
  static Future<void> _save(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw));
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ── CHANGE PASSWORD ────────────────────────────────
  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final token = await getToken();
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/change-password'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({
        'current_password':      currentPassword,
        'password':              newPassword,
        'password_confirmation': newPassword,
      }),
    ).timeout(ApiConfig.timeout);

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return {'ok': true};
    return {'ok': false, 'message': data['message'] ?? 'Erreur'};
  }
}
