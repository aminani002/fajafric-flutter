import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/rapport.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Rapport>     _rapports    = [];
  List<Ordonnance>  _ordonnances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        title: const Text('Mon dossier médical'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.teal,
          unselectedLabelColor: AppTheme.inkSoft,
          indicatorColor: AppTheme.teal,
          tabs: const [Tab(text: 'Rapports'), Tab(text: 'Ordonnances')],
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [_buildRapports(), _buildOrdonnances()],
          ),
    );
  }

  Widget _buildRapports() {
    if (_rapports.isEmpty) return _empty('Aucun rapport médical', Icons.description_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rapports.length,
      itemBuilder: (_, i) {
        final r = _rapports[i];
        final dt = DateTime.tryParse(r.createdAt);
        final date = dt != null ? DateFormat('d MMM yyyy', 'fr_FR').format(dt) : '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.description_outlined, color: AppTheme.teal),
            ),
            title: Text('Consultation du $date', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(r.medecinNom ?? 'Médecin', style: const TextStyle(fontSize: 12.5)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('Diagnostic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.inkSoft)),
                    const SizedBox(height: 6),
                    Text(r.diagnostic, style: const TextStyle(fontSize: 14)),
                    if (r.recommandations != null) ...[
                      const SizedBox(height: 12),
                      const Text('Recommandations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.inkSoft)),
                      const SizedBox(height: 6),
                      Text(r.recommandations!, style: const TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdonnances() {
    if (_ordonnances.isEmpty) return _empty('Aucune ordonnance', Icons.medical_services_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ordonnances.length,
      itemBuilder: (_, i) {
        final o = _ordonnances[i];
        final dt = DateTime.tryParse(o.createdAt);
        final date = dt != null ? DateFormat('d MMM yyyy', 'fr_FR').format(dt) : '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.medical_services_outlined, color: Colors.purple),
            ),
            title: Text('Ordonnance du $date', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(o.medecinNom ?? 'Médecin', style: const TextStyle(fontSize: 12.5)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('Médicaments prescrits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.inkSoft)),
                    const SizedBox(height: 8),
                    if (o.medicaments is List)
                      ...(o.medicaments as List).map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(m.toString(), style: const TextStyle(fontSize: 14)),
                        ]),
                      ))
                    else
                      Text(o.medicaments.toString(), style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String msg, IconData icon) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 52, color: AppTheme.line),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
    ]),
  );
}
