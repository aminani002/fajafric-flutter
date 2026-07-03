import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class NewAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? medecin; // médecin pré-sélectionné (depuis MedecinsScreen)

  const NewAppointmentScreen({super.key, this.medecin});
  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  final _motifCtrl  = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _type        = 'cabinet';
  String _searchQuery = '';
  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading        = false;
  bool _loadingDoctors = false;
  String? _error;
  Map<String, dynamic>? _selectedMedecin;
  List<dynamic> _doctors = [];

  final _types = [
    {'value': 'cabinet',          'label': 'En cabinet',       'icon': Icons.local_hospital_outlined},
    {'value': 'teleconsultation', 'label': 'Téléconsultation', 'icon': Icons.videocam_outlined},
    {'value': 'deplacement',      'label': 'Déplacement',      'icon': Icons.directions_car_outlined},
    {'value': 'chat',             'label': 'Chat médical',     'icon': Icons.chat_outlined},
  ];

  // ── Médecins filtrés par la recherche ──────────────────────────
  List<dynamic> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    final q = _searchQuery.toLowerCase();
    return _doctors.where((d) {
      final nom    = (d['nom']        ?? '').toString().toLowerCase();
      final prenom = (d['prenom']     ?? '').toString().toLowerCase();
      final spec   = (d['specialite'] ?? '').toString().toLowerCase();
      return nom.contains(q) || prenom.contains(q) || spec.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedMedecin = widget.medecin;
    if (_selectedMedecin == null) _loadDoctors();
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    final docs = await ApiService.getDoctors();
    if (mounted) setState(() { _doctors = docs; _loadingDoctors = false; });
  }

  Future<void> _submit() async {
    if (_selectedMedecin == null) {
      setState(() => _error = 'Veuillez sélectionner un médecin');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      setState(() => _error = 'Veuillez choisir une date et une heure');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final dt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    final ok = await ApiService.createAppointment({
      'doctor_id':  _selectedMedecin!['id'],
      'date_heure': DateFormat("yyyy-MM-dd HH:mm:ss").format(dt),
      'type':       _type,
      'motif':      _motifCtrl.text.trim(),
    });

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rendez-vous demandé avec succès !'),
          backgroundColor: AppTheme.teal,
        ),
      );
    } else {
      setState(() {
        _error = 'Erreur lors de la création du RDV. Vérifiez les informations.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medecinNom = _selectedMedecin != null
        ? 'Dr. ${_selectedMedecin!['prenom'] ?? ''} ${_selectedMedecin!['nom'] ?? ''}'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau rendez-vous')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── MÉDECIN ────────────────────────────────────────────
            const Text('Médecin',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            if (_selectedMedecin != null)
              // Médecin sélectionné — carte + option Changer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.teal),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22, backgroundColor: AppTheme.teal,
                    child: Text(
                      '${(_selectedMedecin!['prenom'] ?? ' ')[0]}${(_selectedMedecin!['nom'] ?? ' ')[0]}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medecinNom!,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(_selectedMedecin!['specialite'] ?? 'Médecin généraliste',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.teal)),
                    ],
                  )),
                  if (widget.medecin == null)
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedMedecin = null;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
                      child: const Text('Changer'),
                    ),
                ]),
              )

            else if (_loadingDoctors)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ))

            else ...[
              // ── Barre de recherche ─────────────────────────────
              TextField(
                controller: _searchCtrl,
                onChanged: (q) => setState(() => _searchQuery = q),
                decoration: InputDecoration(
                  hintText: 'Rechercher un médecin, une spécialité…',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.inkSoft),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),

              // ── Liste filtrée ──────────────────────────────────
              if (_filteredDoctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _doctors.isEmpty
                          ? 'Aucun médecin disponible'
                          : 'Aucun résultat pour "$_searchQuery"',
                      style: const TextStyle(color: AppTheme.inkSoft),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.line),
                  ),
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredDoctors.length,
                    itemBuilder: (_, i) {
                      final d = _filteredDoctors[i];
                      return Column(children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.teal,
                            child: Text(
                              '${(d['prenom'] ?? ' ')[0]}${(d['nom'] ?? ' ')[0]}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                          title: Text(
                            'Dr. ${d['prenom'] ?? ''} ${d['nom'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(d['specialite'] ?? 'Généraliste',
                              style: const TextStyle(fontSize: 12.5)),
                          onTap: () => setState(() => _selectedMedecin = d),
                        ),
                        if (i < _filteredDoctors.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ]);
                    },
                  ),
                ),
            ],
            const SizedBox(height: 20),

            // ── ERREUR ─────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: TextStyle(color: AppTheme.red, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // ── TYPE DE CONSULTATION ───────────────────────────────
            const Text('Type de consultation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _types.map((t) {
                final sel = _type == t['value'];
                return GestureDetector(
                  onTap: () => setState(() => _type = t['value'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.teal.withOpacity(0.1) : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppTheme.teal : AppTheme.line,
                          width: sel ? 2 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t['icon'] as IconData,
                          size: 16,
                          color: sel ? AppTheme.teal : AppTheme.inkSoft),
                      const SizedBox(width: 6),
                      Text(t['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                            color: sel ? AppTheme.teal : AppTheme.inkSoft,
                          )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── DATE ───────────────────────────────────────────────
            const Text('Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(primary: AppTheme.teal)),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedDate != null ? AppTheme.teal : AppTheme.line),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color: _selectedDate != null ? AppTheme.teal : AppTheme.inkSoft),
                  const SizedBox(width: 10),
                  Text(
                    _selectedDate != null
                        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                        : 'Choisir une date',
                    style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate != null ? AppTheme.ink : AppTheme.inkSoft),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── HEURE ──────────────────────────────────────────────
            const Text('Heure',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(primary: AppTheme.teal)),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _selectedTime = t);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedTime != null ? AppTheme.teal : AppTheme.line),
                ),
                child: Row(children: [
                  Icon(Icons.access_time_outlined,
                      size: 18,
                      color: _selectedTime != null ? AppTheme.teal : AppTheme.inkSoft),
                  const SizedBox(width: 10),
                  Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Choisir une heure',
                    style: TextStyle(
                        fontSize: 14,
                        color: _selectedTime != null ? AppTheme.ink : AppTheme.inkSoft),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── MOTIF ──────────────────────────────────────────────
            const Text('Motif (optionnel)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _motifCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Décrivez votre motif de consultation…'),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Demander le rendez-vous'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
