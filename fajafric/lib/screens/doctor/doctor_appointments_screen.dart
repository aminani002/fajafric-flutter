import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../messages/messages_screen.dart';

// Clé globale pour accéder au state depuis doctor_home
final doctorAptKey = GlobalKey<_DoctorAppointmentsScreenState>();

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});
  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen> {
  List<DoctorAppointment> _all = [];
  List<DoctorAppointment> _filtered = [];
  String _filter = 'tous';
  bool _loading = true;

  static const _filters = [
    {'key': 'tous', 'label': 'Tous'},
    {'key': 'en_attente', 'label': 'En attente'},
    {'key': 'confirme', 'label': 'Confirmés'},
    {'key': 'termine', 'label': 'Terminés'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final apts = await ApiService.getDoctorAppointments();
    if (!mounted) return;
    setState(() {
      _all = apts..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
      _applyFilter(_filter);
      _loading = false;
    });
  }

  void _applyFilter(String f) {
    setState(() {
      _filter = f;
      _filtered = f == 'tous'
          ? List.from(_all)
          : _all.where((a) => a.statut == f).toList();
    });
  }

  Future<void> _updateStatut(DoctorAppointment apt, String newStatut) async {
    final ok = await ApiService.updateAppointmentStatut(apt.id, newStatut);
    if (!mounted) return;
    if (ok) {
      _load();
      _showSnack('Statut mis à jour');
    } else {
      _showSnack('Erreur lors de la mise à jour', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.red : AppTheme.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showActions(DoctorAppointment apt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionsSheet(
        apt: apt,
        onStatut: (s) { Navigator.pop(context); _updateStatut(apt, s); },
        onMessage: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(appointment: _aptFromDoctor(apt))));
        },
        onOrdonnance: () {
          Navigator.pop(context);
          _showOrdonnanceForm(apt);
        },
        onRapport: () {
          Navigator.pop(context);
          _showRapportForm(apt);
        },
      ),
    );
  }

  // Convertit DoctorAppointment en Appointment minimal pour ChatScreen
  Appointment _aptFromDoctor(DoctorAppointment da) => Appointment(
    id: da.id,
    medecin: Medecin(
      id: 0,
      prenom: da.patient.prenom,
      nom: da.patient.nom,
    ),
    dateHeure: da.dateHeure,
    type: da.type,
    statut: da.statut,
    motif: da.motif,
  );

  void _showOrdonnanceForm(DoctorAppointment apt) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            _handle(),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text('Ordonnance — ${apt.patient.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText:
                          'Ex:\n- Paracétamol 500mg — 3x/jour pendant 5 jours\n- Amoxicilline 1g — 2x/jour pendant 7 jours',
                      filled: true,
                      fillColor: AppTheme.bgElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (ctrl.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        final ok = await ApiService.createPrescription(
                            apt.id, {'medicaments': ctrl.text.trim()});
                        if (mounted) {
                          _showSnack(ok
                              ? 'Ordonnance envoyée au patient'
                              : 'Erreur', error: !ok);
                          if (ok) _load();
                        }
                      },
                      child: const Text('Envoyer l\'ordonnance',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showRapportForm(DoctorAppointment apt) {
    final diagCtrl = TextEditingController();
    final recoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            _handle(),
            Expanded(
              child: ListView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20,
                    MediaQuery.of(context).viewInsets.bottom + 32),
                children: [
                  Text('Rapport — ${apt.patient.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('Diagnostic *',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: diagCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Décrivez le diagnostic...',
                      filled: true,
                      fillColor: AppTheme.bgElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Recommandations',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: recoCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Recommandations au patient...',
                      filled: true,
                      fillColor: AppTheme.bgElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (diagCtrl.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        final ok = await ApiService.createReport(apt.id, {
                          'diagnostic': diagCtrl.text.trim(),
                          'recommandations': recoCtrl.text.trim(),
                        });
                        if (mounted) {
                          _showSnack(ok
                              ? 'Rapport envoyé au patient'
                              : 'Erreur', error: !ok);
                          if (ok) _load();
                        }
                      },
                      child: const Text('Envoyer le rapport',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Mon Planning',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
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
        ),

        // Filtres
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: _filters.map((f) {
                final active = _filter == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _applyFilter(f['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ],
                      ),
                      child: Text(f['label']!,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : AppTheme.textPrimary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        if (_loading)
          const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.teal)))
        else if (_filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Aucun rendez-vous',
                    style:
                        TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildCard(_filtered[i]),
                childCount: _filtered.length,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildCard(DoctorAppointment apt) {
    final sc = apt.statutConfig;
    final color = Color(sc.color);
    final bg = Color(sc.bg);
    DateTime? dt;
    try { dt = DateTime.parse(apt.dateHeure); } catch (_) {}
    final dateStr = dt != null
        ? DateFormat('EEE d MMM • HH:mm', 'fr_FR').format(dt)
        : apt.dateHeure;

    final initials = apt.patient.initials;

    return GestureDetector(
      onTap: () => _showActions(apt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.teal.withOpacity(0.12),
              child: Text(initials,
                  style: const TextStyle(
                      color: AppTheme.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(apt.patient.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: AppTheme.inkSoft),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.inkSoft)),
                ]),
              ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(sc.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _typeBadge(apt.typeLabel),
            const Spacer(),
            if (apt.hasOrdonnance)
              const Icon(Icons.medication_rounded,
                  size: 16, color: AppTheme.teal),
            if (apt.hasReport) ...[
              const SizedBox(width: 4),
              const Icon(Icons.description_rounded,
                  size: 16, color: Color(0xFF6366F1)),
            ],
            if (apt.motif != null && apt.motif!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(apt.motif!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inkSoft)),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _typeBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.teal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.teal)),
      );
}

// ── Feuille d'actions ──────────────────────────────────────────────────────────
class _ActionsSheet extends StatelessWidget {
  final DoctorAppointment apt;
  final void Function(String) onStatut;
  final VoidCallback onMessage;
  final VoidCallback onOrdonnance;
  final VoidCallback onRapport;

  const _ActionsSheet({
    required this.apt,
    required this.onStatut,
    required this.onMessage,
    required this.onOrdonnance,
    required this.onRapport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 16),
        Text(apt.patient.fullName,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(apt.typeLabel,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.inkSoft)),
        const SizedBox(height: 20),

        // Statut
        if (apt.statut == 'en_attente') ...[
          _actionBtn(Icons.check_circle_outline_rounded, 'Confirmer le RDV',
              const Color(0xFF10B981),
              () => onStatut('confirme')),
          const SizedBox(height: 8),
          _actionBtn(Icons.cancel_outlined, 'Annuler le RDV',
              const Color(0xFFEF4444),
              () => onStatut('annule')),
          const SizedBox(height: 8),
        ],
        if (apt.statut == 'confirme') ...[
          _actionBtn(Icons.task_alt_rounded, 'Marquer comme terminé',
              AppTheme.teal,
              () => onStatut('termine')),
          const SizedBox(height: 8),
        ],

        _actionBtn(Icons.chat_bubble_outline_rounded, 'Envoyer un message',
            const Color(0xFF6366F1), onMessage),
        const SizedBox(height: 8),
        _actionBtn(Icons.medication_outlined,
            apt.hasOrdonnance ? 'Ordonnance (déjà envoyée)' : 'Rédiger une ordonnance',
            AppTheme.primary, onOrdonnance),
        const SizedBox(height: 8),
        _actionBtn(Icons.description_outlined,
            apt.hasReport ? 'Rapport (déjà envoyé)' : 'Rédiger un rapport',
            const Color(0xFFF59E0B), onRapport),
      ]),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20, color: color),
        label: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
