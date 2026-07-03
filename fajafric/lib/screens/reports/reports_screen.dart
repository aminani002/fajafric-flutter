import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/rapport.dart';

class ReportsScreen extends StatefulWidget {
  final int initialTab;
  const ReportsScreen({super.key, this.initialTab = 0});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Rapport> _rapports = [];
  List<Ordonnance> _ordonnances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _load();
  }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final r = await ApiService.getRapports();
    final o = await ApiService.getOrdonnances();
    if (mounted) setState(() { _rapports = r; _ordonnances = o; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120, pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 52),
              title: const Text('Mon dossier médical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              background: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.tealMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
              )),
            ),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(icon: const Icon(Icons.description_outlined, size: 18), text: 'Rapports (${_rapports.length})'),
                Tab(icon: const Icon(Icons.medication_outlined, size: 18), text: 'Ordonnances (${_ordonnances.length})'),
              ],
            ),
          ),
        ],
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
          : TabBarView(controller: _tabs, children: [_buildRapports(), _buildOrdonnances()]),
      ),
    );
  }

  Widget _buildRapports() {
    if (_rapports.isEmpty) return _empty('Aucun rapport médical', Icons.description_outlined, 'Vos rapports de consultation\napparaîtront ici');
    return RefreshIndicator(
      onRefresh: _load, color: AppTheme.teal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _rapports.length,
        itemBuilder: (_, i) {
          final r = _rapports[i];
          final dt = DateTime.tryParse(r.createdAt);
          final date = dt != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(dt) : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.teal.withOpacity(0.15), AppTheme.teal.withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.description_rounded, color: AppTheme.teal, size: 22),
                ),
                title: Text('Consultation du $date', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(r.medecinNom ?? 'Médecin', style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSoft)),
                ),
                children: [
                  Container(height: 1, color: const Color(0xFFF3F4F6), margin: const EdgeInsets.only(bottom: 14)),
                  _detailBlock('Diagnostic', r.diagnostic, Icons.medical_information_rounded),
                  if (r.recommandations != null) ...[
                    const SizedBox(height: 12),
                    _detailBlock('Recommandations', r.recommandations!, Icons.medication_rounded),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdonnances() {
    if (_ordonnances.isEmpty) return _empty('Aucune ordonnance', Icons.medication_outlined, 'Vos ordonnances médicales\napparaîtront ici');
    return RefreshIndicator(
      onRefresh: _load, color: AppTheme.teal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _ordonnances.length,
        itemBuilder: (_, i) {
          final o = _ordonnances[i];
          final dt = DateTime.tryParse(o.createdAt);
          final date = dt != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(dt) : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                title: Text('Ordonnance du $date', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(o.medecinNom ?? 'Médecin', style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSoft)),
                ),
                children: [
                  Container(height: 1, color: const Color(0xFFF3F4F6), margin: const EdgeInsets.only(bottom: 14)),
                  const Text('Médicaments prescrits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  if (o.medicaments is List)
                    ...(o.medicaments as List).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 8, height: 8, margin: const EdgeInsets.only(top: 5, right: 10),
                          decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                        ),
                        Expanded(child: Text(m.toString(), style: const TextStyle(fontSize: 14))),
                      ]),
                    ))
                  else
                    Text(o.medicaments.toString(), style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailBlock(String title, String content, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
        child: Text(content, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textPrimary)),
      ),
    ]);
  }

  Widget _empty(String title, IconData icon, String subtitle) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: AppTheme.inkSoft, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    ]),
  );
}
