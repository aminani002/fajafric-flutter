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
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    final apts = await ApiService.getAppointments();
    if (mounted) setState(() { _all = apts; _loading = false; });
  }

  List<Appointment> get _upcoming => _all
    .where((a) => ['en_attente','confirme'].contains(a.statut) && DateTime.tryParse(a.dateHeure)?.isAfter(DateTime.now()) == true)
    .toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
  List<Appointment> get _history  => _all.where((a) => a.statut == 'termine').toList()..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
  List<Appointment> get _cancelled => _all.where((a) => a.statut == 'annule').toList();

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
              title: const Text('Mes rendez-vous', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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
                Tab(text: 'À venir (${_upcoming.length})'),
                Tab(text: 'Historique'),
                Tab(text: 'Annulés'),
              ],
            ),
          ),
        ],
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
          : TabBarView(controller: _tabs, children: [
              _buildList(_upcoming),
              _buildList(_history),
              _buildList(_cancelled),
            ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewAppointmentScreen())).then((_) => _load()),
        backgroundColor: AppTheme.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouveau RDV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildList(List<Appointment> list) {
    if (list.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_note_outlined, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('Aucun rendez-vous', style: TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
    ]));
    return RefreshIndicator(
      onRefresh: _load, color: AppTheme.teal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Appointment apt) {
    final dt = DateTime.tryParse(apt.dateHeure);
    final day   = dt != null ? DateFormat('d', 'fr_FR').format(dt) : '--';
    final month = dt != null ? DateFormat('MMM', 'fr_FR').format(dt) : '--';
    final time  = dt != null ? DateFormat('HH:mm').format(dt) : '--';
    final sc = apt.statutConfig;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Bloc date
          Container(
            width: 52, height: 60,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(day, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              Text(month.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 13, color: AppTheme.inkSoft),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.inkSoft, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(apt.typeLabel, style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
            ]),
            if (apt.motif != null) ...[
              const SizedBox(height: 5),
              Text(apt.motif!, style: const TextStyle(fontSize: 12.5, color: AppTheme.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Color(sc.bg), borderRadius: BorderRadius.circular(20)),
              child: Text(sc.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(sc.color))),
            ),
            if (apt.statut == 'en_attente' || apt.statut == 'confirme') ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmCancel(apt),
                child: const Text('Annuler', style: TextStyle(fontSize: 12, color: AppTheme.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  void _confirmCancel(Appointment apt) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Annuler le RDV ?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('RDV avec ${apt.medecin.fullName} sera annulé.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Non')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
          onPressed: () async { Navigator.pop(context); await ApiService.cancelAppointment(apt.id); _load(); },
          child: const Text('Annuler le RDV'),
        ),
      ],
    ));
  }
}
