import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/rapport.dart';
import 'signature_pad_screen.dart';

class DoctorActesScreen extends StatefulWidget {
  const DoctorActesScreen({super.key});
  @override
  State<DoctorActesScreen> createState() => _DoctorActesScreenState();
}

class _DoctorActesScreenState extends State<DoctorActesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Rapport> _rapports = [];
  List<Ordonnance> _ordonnances = [];
  bool _loadingR = true, _loadingO = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadRapports();
    _loadOrdonnances();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadRapports() async {
    final r = await ApiService.getRapports();
    if (mounted) setState(() { _rapports = r; _loadingR = false; });
  }

  Future<void> _loadOrdonnances() async {
    final o = await ApiService.getOrdonnances();
    if (mounted) setState(() { _ordonnances = o; _loadingO = false; });
  }

  String _fmt(String raw) {
    try { return DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(raw)); }
    catch (_) { return raw.split('T').first; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 50),
              title: const Text('Mes Actes',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.tealMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Ordonnances'), Tab(text: 'Rapports')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [_ordonnancesTab(), _rapportsTab()],
        ),
      ),
    );
  }

  Widget _ordonnancesTab() {
    if (_loadingO) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_ordonnances.isEmpty) return _empty('Aucune ordonnance rédigée', Icons.medication_outlined);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _ordonnances.length,
      itemBuilder: (_, i) {
        final o = _ordonnances[i];
        final meds = o.medicaments is String ? o.medicaments as String : o.medicaments?.toString() ?? '';
        return _acteCard(
          icon: Icons.medication_rounded,
          iconColor: AppTheme.primary,
          title: 'Ordonnance #${o.id}',
          subtitle: meds.isNotEmpty ? meds.split('\n').first : 'Voir le détail',
          date: _fmt(o.createdAt),
          onTap: () => _showOrdonnanceDetail(o),
        );
      },
    );
  }

  Widget _rapportsTab() {
    if (_loadingR) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_rapports.isEmpty) return _empty('Aucun rapport rédigé', Icons.description_outlined);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rapports.length,
      itemBuilder: (_, i) {
        final r = _rapports[i];
        return _acteCard(
          icon: Icons.description_rounded,
          iconColor: const Color(0xFF6366F1),
          title: 'Rapport #${r.id}',
          subtitle: r.diagnostic,
          date: _fmt(r.createdAt),
          onTap: () => _showRapportDetail(r),
        );
      },
    );
  }

  Widget _acteCard({
    required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required String date, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
        ]),
      ),
    );
  }

  void _showOrdonnanceDetail(Ordonnance o) async {
    final sig = await loadSignature();
    final meds = o.medicaments is String ? o.medicaments as String : o.medicaments?.toString() ?? '';
    if (!mounted) return;
    _showDetail('Ordonnance #${o.id}', [
      _detailRow('Date', _fmt(o.createdAt)),
      _detailRow('Médicaments', meds),
    ], signature: sig);
  }

  void _showRapportDetail(Rapport r) async {
    final sig = await loadSignature();
    if (!mounted) return;
    _showDetail('Rapport #${r.id}', [
      _detailRow('Date', _fmt(r.createdAt)),
      _detailRow('Diagnostic', r.diagnostic),
      if (r.recommandations != null && r.recommandations!.isNotEmpty)
        _detailRow('Recommandations', r.recommandations!),
    ], signature: sig);
  }

  void _showDetail(String title, List<Widget> rows, {String? signature}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  ...rows,
                  if (signature != null) ...[
                    const Divider(height: 24, color: Color(0xFFF0F0F0)),
                    const Text('Signature du médecin',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.inkSoft, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity, height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SignatureImage(base64: signature, height: 70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppTheme.inkSoft, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
        ]),
      );

  Widget _empty(String msg, IconData icon) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
        ]),
      );
}
