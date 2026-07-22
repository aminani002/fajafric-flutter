import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/appointment.dart';
import '../messages/messages_screen.dart';

/// Messages côté médecin — liste les patients avec qui il a eu un RDV
class DoctorMessagesScreen extends StatefulWidget {
  const DoctorMessagesScreen({super.key});
  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  List<DoctorAppointment> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apts = await ApiService.getDoctorAppointments();
    if (!mounted) return;

    // Un chat par patient (le RDV le plus récent)
    final Map<int, DoctorAppointment> byPatient = {};
    for (final apt in apts) {
      final existing = byPatient[apt.patient.id];
      if (existing == null ||
          apt.dateHeure.compareTo(existing.dateHeure) > 0) {
        byPatient[apt.patient.id] = apt;
      }
    }

    setState(() {
      _chats = byPatient.values.toList()
        ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
      _loading = false;
    });
  }

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
            title: const Text('Messages',
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

        if (_loading)
          const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.teal)))
        else if (_chats.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Aucun message pour l\'instant',
                    style: TextStyle(
                        color: AppTheme.inkSoft, fontSize: 15)),
              ]),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildItem(_chats[i]),
              childCount: _chats.length,
            ),
          ),
      ]),
    );
  }

  Widget _buildItem(DoctorAppointment apt) {
    DateTime? dt;
    try { dt = DateTime.parse(apt.dateHeure); } catch (_) {}
    final dateStr = dt != null
        ? DateFormat('d MMM', 'fr_FR').format(dt)
        : '';

    final initials = apt.patient.initials;
    final colors = [
      AppTheme.teal,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEC4899)
    ];
    final idx = apt.patient.fullName.codeUnits
            .fold(0, (a, b) => a + b) %
        colors.length;
    final avatarColor = colors[idx];

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            appointment: _toAppointment(apt),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor.withOpacity(0.12),
            child: Text(initials,
                style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(apt.patient.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 3),
              Text(apt.typeLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.inkSoft)),
            ]),
          ),
          Text(dateStr,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.inkSoft)),
        ]),
      ),
    );
  }

  Appointment _toAppointment(DoctorAppointment da) => Appointment(
        id: da.id,
        medecin: Medecin(
          id: da.patient.id,
          prenom: da.patient.prenom,
          nom: da.patient.nom,
        ),
        dateHeure: da.dateHeure,
        type: da.type,
        statut: da.statut,
      );
}
