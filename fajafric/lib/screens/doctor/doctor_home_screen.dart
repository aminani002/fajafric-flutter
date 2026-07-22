import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import 'doctor_keys.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _prenom = '';
  String _nom = '';
  String _specialite = '';
  List<DoctorAppointment> _rdvAujourdhui = [];
  List<DoctorAppointment> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AuthService.getUser(),
      ApiService.getDoctorAppointments(),
      ApiService.getDoctorProfile(),
    ]);
    if (!mounted) return;

    final user    = results[0] as dynamic;
    final apts    = results[1] as List<DoctorAppointment>;
    final profile = results[2] as Map<String, dynamic>?;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayApts = apts
        .where((a) => a.dateHeure.startsWith(today))
        .toList()
      ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

    setState(() {
      _prenom    = user?.prenom ?? '';
      _nom       = user?.nom ?? '';
      _specialite = profile?['specialite'] ?? '';
      _rdvAujourdhui = todayApts;
      _all = apts;
      _loading = false;
    });
  }

  int get _enAttente => _all.where((a) => a.statut == 'en_attente').length;
  int get _confirmes  => _all.where((a) => a.statut == 'confirme').length;
  int get _termines   => _all.where((a) => a.statut == 'termine').length;

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        color: AppTheme.teal,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.teal, strokeWidth: 2.5)),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildStatCards(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildQuickActions(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("RDV d'aujourd'hui",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    if (_rdvAujourdhui.isNotEmpty)
                      GestureDetector(
                        onTap: () => doctorSwitchTab?.call(1),
                        child: Text('Tout voir →',
                            style: const TextStyle(fontSize: 12, color: AppTheme.teal, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),

            if (_rdvAujourdhui.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available_rounded, color: AppTheme.teal, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Pas de RDV aujourd'hui",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Profitez-en pour vous reposer 🎉',
                        style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, i == _rdvAujourdhui.length - 1 ? 100 : 10),
                    child: _rdvCard(_rdvAujourdhui[i]),
                  ),
                  childCount: _rdvAujourdhui.length,
                ),
              ),

            if (_rdvAujourdhui.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ]),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final initials = '${_prenom.isNotEmpty ? _prenom[0] : ''}${_nom.isNotEmpty ? _nom[0] : ''}';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.tealMid, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 28,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Dr. $_prenom $_nom',
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            if (_specialite.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(_specialite,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
            ],
          ])),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: Text(initials.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Text(
              _rdvAujourdhui.isEmpty
                  ? 'Aucun RDV aujourd\'hui'
                  : '${_rdvAujourdhui.length} RDV aujourd\'hui',
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

  // ── STAT CARDS ───────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final stats = [
      {'val': '$_enAttente', 'label': 'En attente',  'icon': Icons.hourglass_top_rounded,       'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)},
      {'val': '$_confirmes', 'label': 'Confirmés',   'icon': Icons.check_circle_outline_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFD1FAE5)},
      {'val': '$_termines',  'label': 'Terminés',    'icon': Icons.task_alt_rounded,             'color': AppTheme.teal,            'bg': AppTheme.bgElevated},
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final s = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0, top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(s['val'] as String,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(s['label'] as String,
                  style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Services',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _quickCard(
          icon: Icons.calendar_month_rounded,
          label: 'Planning',
          subtitle: 'Gérer vos RDV',
          color: AppTheme.primary,
          bg: AppTheme.bgElevated,
          onTap: () => doctorSwitchTab?.call(1),
        )),
        const SizedBox(width: 12),
        Expanded(child: _quickCard(
          icon: Icons.chat_bubble_rounded,
          label: 'Messages',
          subtitle: 'Vos patients',
          color: const Color(0xFF6366F1),
          bg: const Color(0xFFF3F0FF),
          onTap: () => doctorSwitchTab?.call(2),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _quickCard(
          icon: Icons.description_rounded,
          label: 'Mes Actes',
          subtitle: 'Ordonnances & rapports',
          color: const Color(0xFF0891B2),
          bg: const Color(0xFFE0F7FA),
          onTap: () => doctorSwitchTab?.call(3),
        )),
        const SizedBox(width: 12),
        Expanded(child: _quickCard(
          icon: Icons.person_rounded,
          label: 'Mon Profil',
          subtitle: 'Signature & infos',
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
          onTap: () => doctorSwitchTab?.call(4),
        )),
      ]),
    ]);
  }

  Widget _quickCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 18),
        ]),
      ),
    );
  }

  // ── RDV CARD ─────────────────────────────────────────────────────────────────

  Widget _rdvCard(DoctorAppointment apt) {
    final sc = apt.statutConfig;
    final color = Color(sc.color);
    final bg = Color(sc.bg);
    DateTime? dt;
    try { dt = DateTime.parse(apt.dateHeure); } catch (_) {}
    final heure = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
    final parts = heure.split(':');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(parts[0],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.teal)),
            Text(':${parts[1]}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.inkSoft)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(apt.patient.fullName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(apt.typeLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.teal)),
          ),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(sc.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }
}
