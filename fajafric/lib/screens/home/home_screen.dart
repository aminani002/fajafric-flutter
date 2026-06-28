import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Appointment> _appointments = [];
  bool _loading = true;
  String? _notifMessage;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startNotifPolling();
  }

  @override
  void dispose() { _notifTimer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final user = await AuthService.getUser();
    final apts = await ApiService.getAppointments();
    if (mounted) setState(() { _user = user; _appointments = apts; _loading = false; });
  }

  void _startNotifPolling() {
    _checkNotifs();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkNotifs());
  }

  Future<void> _checkNotifs() async {
    final notifs = await ApiService.getNotifications();
    if (notifs.isEmpty || !mounted) return;
    final data = notifs[0]['data'];
    setState(() => _notifMessage = data['message']);
    await ApiService.markAllRead();
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() => _notifMessage = null);
  }

  List<Appointment> get _upcoming => _appointments
    .where((a) => a.statut != 'annule' && a.statut != 'termine' && DateTime.tryParse(a.dateHeure)?.isAfter(DateTime.now()) == true)
    .toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

  List<Appointment> get _history => _appointments
    .where((a) => a.statut == 'termine')
    .toList()..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = DateFormat("EEEE d MMMM yyyy", "fr_FR").format(DateTime.now());
    final todayCount = _upcoming.where((a) =>
      DateFormat('yyyy-MM-dd').format(DateTime.parse(a.dateHeure)) ==
      DateFormat('yyyy-MM-dd').format(DateTime.now())).length;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── HEADER ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildWelcomeBar(today, todayCount),
                    ),
                  ),

                  // ── STAT CARDS ─────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _buildStatCards(),
                    ),
                  ),

                  // ── PROCHAINS RDV ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildSection('Prochains rendez-vous', _upcoming.take(3).toList(), isUpcoming: true),
                    ),
                  ),

                  // ── HISTORIQUE ─────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: _buildSection('Historique récent', _history.take(5).toList(), isUpcoming: false),
                    ),
                  ),
                ],
              ),
            ),

            // ── NOTIFICATION TOAST ─────────────────────
            if (_notifMessage != null)
              Positioned(
                bottom: 90, left: 16, right: 16,
                child: _buildToast(_notifMessage!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBar(String today, int todayCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, ${_user?.prenom ?? ''} 👋', style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827),
                )),
                const SizedBox(height: 4),
                Text(
                  todayCount > 0 ? 'Vous avez $todayCount RDV aujourd\'hui' : 'Aucun rendez-vous aujourd\'hui',
                  style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.teal,
                child: Text(_user?.initials ?? '?', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                )),
              ),
              const SizedBox(height: 6),
              Text('${today.substring(0, today.length > 12 ? 12 : today.length)}…',
                style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final stats = [
      {'icon': Icons.calendar_today_rounded, 'label': 'Consultations', 'value': '${_appointments.length}', 'color': AppTheme.teal},
      {'icon': Icons.medical_services_outlined, 'label': 'Ordonnances', 'value': '–', 'color': Colors.blue},
      {'icon': Icons.description_outlined, 'label': 'Rapports', 'value': '${_history.where((a) => a.hasReport).length}', 'color': Colors.purple},
    ];
    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: s == stats.last ? 0 : 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: (s['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(s['value'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              Text(s['label'] as String, style: const TextStyle(fontSize: 11.5, color: AppTheme.inkSoft)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSection(String title, List<Appointment> items, {required bool isUpcoming}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const Text('Voir tout', style: TextStyle(fontSize: 13, color: AppTheme.teal, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                Icon(isUpcoming ? Icons.event_available_outlined : Icons.history_outlined,
                  size: 36, color: AppTheme.line),
                const SizedBox(height: 10),
                Text(isUpcoming ? 'Aucun rendez-vous à venir' : 'Aucun historique',
                  style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
              ]),
            )
          else
            ...items.map((apt) => isUpcoming ? _upcomingTile(apt) : _historyTile(apt)),
        ],
      ),
    );
  }

  Widget _upcomingTile(Appointment apt) {
    final dt = DateTime.tryParse(apt.dateHeure);
    final dateStr = dt != null ? DateFormat('EEE d MMM, HH:mm', 'fr_FR').format(dt) : '';
    final sc = apt.statutConfig;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.teal,
                child: Text(apt.medecin.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                    Text('${apt.typeLabel} · $dateStr', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                    if (apt.motif != null) Text(apt.motif!, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(sc.bg),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(sc.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(sc.color))),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _historyTile(Appointment apt) {
    final dt = DateTime.tryParse(apt.dateHeure);
    final dateStr = dt != null ? DateFormat('d MMM yyyy', 'fr_FR').format(dt) : '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(apt.medecin.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF111827))),
                    Text(apt.medecin.specialite ?? 'Médecin généraliste', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  if (apt.hasReport) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Rapport', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.teal)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildToast(String message) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border(left: BorderSide(color: AppTheme.teal, width: 4)),
        ),
        child: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rendez-vous confirmé !', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.teal, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _notifMessage = null),
              child: const Icon(Icons.close, size: 18, color: AppTheme.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
