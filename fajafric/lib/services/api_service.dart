import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/appointment.dart';
import '../models/rapport.dart';
import '../models/message.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return ApiConfig.headers(token);
  }

  static dynamic _parse(http.Response res) {
    try { return jsonDecode(res.body); } catch (_) { return null; }
  }

  // ── MÉDECINS ───────────────────────────────────────
  static Future<List<dynamic>> getDoctors() async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/doctors'),
      headers: ApiConfig.headers(token),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    if (data is List) return data;
    if (data is Map && data['doctors'] != null) return data['doctors'];
    if (data is Map && data['data'] != null) return data['data'];
    return [];
  }

  // ── RENDEZ-VOUS ────────────────────────────────────
  static Future<List<Appointment>> getAppointments() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/appointments'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    List raw = [];
    if (data is List) raw = data;
    else if (data is Map && data['appointments'] != null) raw = data['appointments'];
    else if (data is Map && data['data'] != null) raw = data['data'];
    return raw.map((e) => Appointment.fromJson(e)).toList();
  }

  static Future<bool> createAppointment(Map<String, dynamic> form) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/appointments'),
      headers: await _headers(),
      body: jsonEncode(form),
    ).timeout(ApiConfig.timeout);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> cancelAppointment(int id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/appointments/$id/statut'),
      headers: await _headers(),
      body: jsonEncode({'statut': 'annule'}),
    ).timeout(ApiConfig.timeout);
    return res.statusCode == 200;
  }

  // ── RAPPORTS ───────────────────────────────────────
  static Future<List<Rapport>> getRapports() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/my-reports'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    List raw = [];
    if (data is List) raw = data;
    else if (data is Map && data['reports'] != null) raw = data['reports'];
    else if (data is Map && data['data'] != null) raw = data['data'];
    return raw.map((e) => Rapport.fromJson(e)).toList();
  }

  // ── ORDONNANCES ────────────────────────────────────
  static Future<List<Ordonnance>> getOrdonnances() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/my-prescriptions'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    List raw = [];
    if (data is List) raw = data;
    else if (data is Map && data['prescriptions'] != null) raw = data['prescriptions'];
    else if (data is Map && data['data'] != null) raw = data['data'];
    return raw.map((e) => Ordonnance.fromJson(e)).toList();
  }

  // ── CONVERSATIONS ──────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/conversations'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    if (data is List) return data;
    if (data is Map && data['conversations'] != null) return data['conversations'];
    if (data is Map && data['data'] != null) return data['data'];
    return [];
  }

  // ── MESSAGES ───────────────────────────────────────
  static Future<List<Message>> getMessages(int rdvId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/appointments/$rdvId/messages'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('[]', 200));
    final data = _parse(res);
    List raw = [];
    if (data is List) raw = data;
    else if (data is Map && data['messages'] != null) raw = data['messages'];
    else if (data is Map && data['data'] != null) raw = data['data'];
    return raw.map((e) => Message.fromJson(e)).toList();
  }

  static Future<bool> sendMessage(int rdvId, String contenu) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/appointments/$rdvId/messages'),
      headers: await _headers(),
      body: jsonEncode({'contenu': contenu}),
    ).timeout(ApiConfig.timeout);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ── PROFIL ─────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fajafric/profile'),
      headers: await _headers(),
    ).timeout(ApiConfig.timeout).catchError((_) => http.Response('{}', 200));
    final data = _parse(res);
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  // ── NOTIFICATIONS (non dispo côté Laravel pour l'instant) ──
  static Future<List<dynamic>> getNotifications() async => [];
  static Future<void> markAllRead() async {}
}
