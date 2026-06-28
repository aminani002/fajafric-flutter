import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import 'new_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Appointment> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final apts = await ApiService.getAppointments();
    if (mounted) setState(() { _all = apts; _loading = false; });
  }

  List<Appointment> get _upcoming => _all
    .where((a) => ['en_attente','confirme'].contains(a.statut) && DateTime.tryParse(a.dateHeure)?.isAfter(DateTime.now()) == true)
    .toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

  List<Appointment> get _history  => _all.where((a) => a.statut == 'termine').toList()
    ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

  List<Appointment> get _cancelled => _all.where((a) => a.statut == 'annule').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.teal,
          unselectedLabelColor: AppTheme.inkSoft,
          indicatorColor: AppTheme.teal,
          tabs: const [Tab(text: 'À venir'), Tab(text: 'Historique'), Tab(text: 'Annulés')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewAppointmentScreen())).then((_) => _load()),
        backgroundColor: AppTheme.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau RDV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [
              _buildList(_upcoming),
              _buildList(_history),
              _buildList(_cancelled),
            ],
          ),
    );
  }

  Widget _buildList(List<Appointment> list) {
    if (list.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_note_outlined, size: 52, color: AppTheme.line),
          SizedBox(height: 12),
          Text('Aucun rendez-vous', style: TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Appointment apt) {
    final dt = DateTime.tryParse(apt.dateHeure);
    final day    = dt != null ? DateFormat('d', 'fr_FR').format(dt) : '--';
    final month  = dt != null ? DateFormat('MMM', 'fr_FR').format(dt) : '--';
    final time   = dt != null ? DateFormat('HH:mm').format(dt) : '--';
    final sc = apt.statutConfig;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date bloc
            Container(
              width: 54, height: 60,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(day, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.teal)),
                Text(month, style: const TextStyle(fontSize: 12, color: AppTheme.teal)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${apt.typeLabel} · $time', style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
                  if (apt.motif != null) ...[
                    const SizedBox(height: 4),
                    Text(apt.motif!, style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSoft), maxLines: 2),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(sc.bg), borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(sc.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(sc.color))),
                ),
                if (apt.statut == 'en_attente' || apt.statut == 'confirme') ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _confirmCancel(apt),
                    child: const Text('Annuler', style: TextStyle(fontSize: 12, color: AppTheme.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(Appointment apt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler le RDV ?'),
        content: Text('Voulez-vous annuler votre RDV avec ${apt.medecin.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Non')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.cancelAppointment(apt.id);
              _load();
            },
            child: const Text('Oui, annuler', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
