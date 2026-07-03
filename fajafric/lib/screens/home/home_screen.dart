import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';
import '../../models/rapport.dart';
import '../reports/reports_screen.dart';
import '../suivi/suivi_sante_screen.dart';
import '../chatbot/chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Appointment> _appointments = [];
  int _ordonnancesCount = 0;
  bool _loading = true;
  String? _notifMessage;
  int _notifCount = 0;
  Timer? _notifTimer;

  @override
  void initState() { super.initState(); _load(); _startNotifPolling(); }

  @override
  void dispose() { _notifTimer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final results = await Future.wait([
      AuthService.getUser(),
      ApiService.getAppointments(),
      ApiService.getOrdonnances(),
    ]);
    if (mounted) setState(() {
      _user             = results[0] as User?;
      _appointments     = results[1] as List<Appointment>;
      _ordonnancesCount = (results[2] as List<Ordonnance>).length;
      _loading          = false;
    });
  }

  void _startNotifPolling() {
    _checkNotifs();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkNotifs());
  }

  Future<void> _checkNotifs() async {
    final notifs = await ApiService.getNotifications();
    if (notifs.isEmpty || !mounted) return;
    final data = notifs[0]['data'];
    setState(() { _notifMessage = data['message']; _notifCount++; });
    await ApiService.markAllRead();
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) setState(() { _notifMessage = null; _notifCount = 0; });
  }

  List<Appointment> get _upcoming => _appointments
    .where((a) => a.statut != 'annule' && a.statut != 'termine' &&
        DateTime.tryParse(a.dateHeure)?.isAfter(DateTime.now()) == true)
    .toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

  List<Appointment> get _history => _appointments
    .where((a) => a.statut == 'termine')
    .toList()..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5)));

    final now = DateTime.now();
    final todayCount = _upcoming.where((a) =>
      DateFormat('yyyy-MM-dd').format(DateTime.parse(a.dateHeure)) ==
      DateFormat('yyyy-MM-dd').format(now)).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.primary,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHeader(todayCount)),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildStatCards(),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildQuickActions(),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSection('Prochains rendez-vous', _upcoming.take(3).toList(), isUpcoming: true),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: _buildSection('Historique récent', _history.take(4).toList(), isUpcoming: false),
            )),
          ]),
        ),
        if (_notifMessage != null)
          Positioned(bottom: 90, left: 16, right: 16, child: _buildToast(_notifMessage!)),
      ]),
    );
  }

  Widget _buildHeader(int todayCount) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.tealMid, AppTheme.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 28,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_user?.fullName ?? '', style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3,
            )),
          ])),
          // Bell icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              ),
              if (_notifCount > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Center(child: Text('$_notifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22, backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(_user?.initials ?? '?', style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15,
            )),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              todayCount > 0 ? '$todayCount rendez-vous aujourd\'hui' : 'Aucun RDV aujourd\'hui',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            Text(DateFormat('d MMM', 'fr_FR').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatCards() {
    final rapportsCount = _history.where((a) => a.hasReport).length;
    final stats = [
      {'icon': Icons.event_available_rounded, 'label': 'Consultations', 'value': '${_appointments.length}', 'color': AppTheme.primary, 'bg': AppTheme.bgElevated, 'tab': null},
      {'icon': Icons.description_rounded,    'label': 'Rapports',       'value': '$rapportsCount',          'color': AppTheme.gold,    'bg': const Color(0xFFFEF3C7), 'tab': 0},
      {'icon': Icons.medication_rounded,     'label': 'Ordonnances',    'value': '$_ordonnancesCount',      'color': AppTheme.green,   'bg': const Color(0xFFD1FAE5), 'tab': 1},
    ];

    return Row(children: stats.asMap().entries.map((e) {
      final s   = e.value;
      final tab = s['tab'] as int?;
      return Expanded(child: GestureDetector(
        onTap: tab != null ? () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ReportsScreen(initialTab: tab))) : null,
        child: Container(
          margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: s['bg'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(s['value'] as String,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(s['label'] as String,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _buildQuickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ),
      Row(children: [
        Expanded(child: _quickCard(
          icon: Icons.monitor_heart_rounded,
          label: 'Suivi Santé',
          subtitle: 'TA, poids, glycémie…',
          color: AppTheme.primary,
          bg: AppTheme.bgElevated,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuiviSanteScreen())),
        )),
        const SizedBox(width: 12),
        Expanded(child: _quickCard(
          icon: Icons.smart_toy_rounded,
          label: 'Chatbot Médical',
          subtitle: 'Conseils santé IA',
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF3F0FF),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        )),
      ]),
    ]);
  }

  Widget _quickCard({
    required IconData icon, required String label, required String subtitle,
    required Color color, required Color bg, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<Appointment> items, {required bool isUpcoming}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Column(children: [
                Icon(isUpcoming ? Icons.event_available_outlined : Icons.history_outlined,
                  size: 40, color: AppTheme.textMuted),
                const SizedBox(height: 10),
                Text(isUpcoming ? 'Aucun RDV à venir' : 'Pas encore de consultations',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ])),
            )
          : Column(children: items.asMap().entries.map((e) =>
              isUpcoming ? _upcomingTile(e.value, e.key == items.length - 1)
                         : _historyTile(e.value, e.key == items.length - 1)
            ).toList()),
      ),
    ]);
  }

  Widget _upcomingTile(Appointment apt, bool isLast) {
    final dt    = DateTime.tryParse(apt.dateHeure);
    final day   = dt != null ? DateFormat('d', 'fr_FR').format(dt) : '--';
    final month = dt != null ? DateFormat('MMM', 'fr_FR').format(dt) : '--';
    final time  = dt != null ? DateFormat('HH:mm').format(dt) : '--';
    final sc    = apt.statutConfig;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 46, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              Text(month.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('$time · ${apt.typeLabel}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Color(sc.bg), borderRadius: BorderRadius.circular(20)),
            child: Text(sc.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(sc.color))),
          ),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }

  Widget _historyTile(Appointment apt, bool isLast) {
    final dt   = DateTime.tryParse(apt.dateHeure);
    final date = dt != null ? DateFormat('d MMM yyyy', 'fr_FR').format(dt) : '';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: AppTheme.bgElevated,
            child: Text(apt.medecin.initials, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textPrimary)),
            Text(apt.medecin.specialite ?? 'Médecin généraliste', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(date, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
            if (apt.hasReport) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(20)),
                child: const Text('Rapport', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ],
          ]),
        ]),
      ),
      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }

  Widget _buildToast(String message) {
    return Material(
      elevation: 12, borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
        ),
        child: Row(children: [
          const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RDV confirmé !', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 13)),
            const SizedBox(height: 2),
            Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          GestureDetector(
            onTap: () => setState(() => _notifMessage = null),
            child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
          ),
        ]),
      ),
    );
  }
}
