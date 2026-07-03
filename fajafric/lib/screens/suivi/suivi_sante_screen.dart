import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// ── Modèle mesure ─────────────────────────────────────────────────────────────
class HealthEntry {
  final String type;
  final double value;
  final String? value2; // ex: diastolique pour la TA
  final String unit;
  final DateTime date;
  final String? note;

  HealthEntry({
    required this.type, required this.value, this.value2,
    required this.unit, required this.date, this.note,
  });

  Map<String, dynamic> toJson() => {
    'type': type, 'value': value, 'value2': value2,
    'unit': unit, 'date': date.toIso8601String(), 'note': note,
  };

  factory HealthEntry.fromJson(Map<String, dynamic> j) => HealthEntry(
    type: j['type'], value: (j['value'] as num).toDouble(), value2: j['value2'],
    unit: j['unit'], date: DateTime.parse(j['date']), note: j['note'],
  );
}

// ── Types de mesures ──────────────────────────────────────────────────────────
class MeasureType {
  final String key, label, unit;
  final IconData icon;
  final Color color;
  final String hint;
  final bool hasTwoValues;

  const MeasureType({
    required this.key, required this.label, required this.unit,
    required this.icon, required this.color, required this.hint,
    this.hasTwoValues = false,
  });
}

const _types = [
  MeasureType(key: 'tension',     label: 'Tension artérielle', unit: 'mmHg', icon: Icons.favorite_rounded,        color: Color(0xFFEF4444), hint: 'Ex : 120 / 80',         hasTwoValues: true),
  MeasureType(key: 'poids',       label: 'Poids',              unit: 'kg',   icon: Icons.monitor_weight_rounded,  color: Color(0xFF2A8BAE), hint: 'Ex : 72.5'),
  MeasureType(key: 'glycemie',    label: 'Glycémie',           unit: 'g/L',  icon: Icons.water_drop_rounded,      color: Color(0xFFF59E0B), hint: 'Ex : 1.02'),
  MeasureType(key: 'cardio',      label: 'Fréquence cardiaque',unit: 'bpm',  icon: Icons.monitor_heart_rounded,   color: Color(0xFFEC4899), hint: 'Ex : 72'),
  MeasureType(key: 'temperature', label: 'Température',        unit: '°C',   icon: Icons.thermostat_rounded,      color: Color(0xFF10B981), hint: 'Ex : 37.2'),
  MeasureType(key: 'spo2',        label: 'Saturation O₂',      unit: '%',    icon: Icons.air_rounded,             color: Color(0xFF6366F1), hint: 'Ex : 98'),
];

// ── Écran principal ────────────────────────────────────────────────────────────
class SuiviSanteScreen extends StatefulWidget {
  const SuiviSanteScreen({super.key});
  @override
  State<SuiviSanteScreen> createState() => _SuiviSanteScreenState();
}

class _SuiviSanteScreenState extends State<SuiviSanteScreen> {
  List<HealthEntry> _entries = [];
  String _selectedType = 'tension';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('health_entries') ?? [];
    setState(() => _entries = raw.map((e) => HealthEntry.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('health_entries', _entries.map((e) => jsonEncode(e.toJson())).toList());
  }

  void _addEntry(HealthEntry e) {
    setState(() { _entries.insert(0, e); });
    _save();
  }

  void _deleteEntry(int i) {
    setState(() => _entries.removeAt(i));
    _save();
  }

  List<HealthEntry> get _filtered => _entries.where((e) => e.type == _selectedType).toList();

  MeasureType get _currentType => _types.firstWhere((t) => t.key == _selectedType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        // ── HEADER ────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120, pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            title: const Text('Suivi Santé',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.tealMid],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        // ── TYPE SELECTOR ──────────────────────────────────────────────
        SliverToBoxAdapter(child: SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final t = _types[i];
              final sel = t.key == _selectedType;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? t.color : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? t.color : AppTheme.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t.icon, size: 15, color: sel ? Colors.white : t.color),
                    const SizedBox(width: 6),
                    Text(t.label, style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppTheme.textPrimary,
                    )),
                  ]),
                ),
              );
            },
          ),
        )),

        // ── DERNIÈRE MESURE + BOUTON AJOUTER ──────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _buildSummaryCard(),
        )),

        // ── HISTORIQUE ────────────────────────────────────────────────
        _filtered.isEmpty
          ? SliverFillRemaining(child: _buildEmpty())
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => _buildEntryTile(_filtered[i],
                  _entries.indexOf(_filtered[i])),
                childCount: _filtered.length,
              )),
            ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: _currentType.color,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter une mesure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final t = _currentType;
    final latest = _filtered.isNotEmpty ? _filtered.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.color.withOpacity(0.12), t.color.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: t.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(t.icon, color: t.color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          if (latest != null) ...[
            Row(children: [
              Text(
                latest.value2 != null
                  ? '${latest.value.toStringAsFixed(0)} / ${latest.value2}'
                  : latest.value.toString(),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: t.color),
              ),
              const SizedBox(width: 4),
              Text(t.unit, style: TextStyle(fontSize: 13, color: t.color.withOpacity(0.7))),
            ]),
            Text(
              'Dernière mesure · ${DateFormat('d MMM yyyy HH:mm', 'fr_FR').format(latest.date)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ] else
            Text('Aucune mesure enregistrée', style: TextStyle(fontSize: 13, color: t.color.withOpacity(0.7))),
        ])),
        Text('${_filtered.length}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: t.color.withOpacity(0.2))),
      ]),
    );
  }

  Widget _buildEntryTile(HealthEntry entry, int globalIdx) {
    final t = _types.firstWhere((x) => x.key == entry.type);
    final df = DateFormat('d MMM yyyy à HH:mm', 'fr_FR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: t.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(t.icon, color: t.color, size: 20),
        ),
        title: Text(
          entry.value2 != null
            ? '${entry.value.toStringAsFixed(0)} / ${entry.value2} ${t.unit}'
            : '${entry.value} ${t.unit}',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: t.color),
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(df.format(entry.date), style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          if (entry.note != null && entry.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(entry.note!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ]),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 20),
          onPressed: () => _confirmDelete(globalIdx),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(_currentType.icon, size: 56, color: AppTheme.border),
    const SizedBox(height: 12),
    Text('Aucune mesure de ${_currentType.label.toLowerCase()}',
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    const Text('Appuyez sur + pour ajouter votre première mesure',
      style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 80),
  ]));

  void _confirmDelete(int i) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('Cette mesure sera supprimée définitivement.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
          onPressed: () { Navigator.pop(context); _deleteEntry(i); },
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  void _openAddDialog() {
    final t = _currentType;
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: t.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(t.icon, color: t.color, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Ajouter — ${t.label}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 20),
            if (t.hasTwoValues) ...[
              Row(children: [
                Expanded(child: _field(ctrl1, 'Systolique', 'Ex : 120', TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(ctrl2, 'Diastolique', 'Ex : 80', TextInputType.number)),
              ]),
            ] else
              _field(ctrl1, '${t.label} (${t.unit})', t.hint, const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            _field(noteCtrl, 'Note (optionnel)', 'Ex : après le sport, à jeun…', TextInputType.text),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: StatefulBuilder(builder: (ctx, setBtn) => ElevatedButton(
                onPressed: () {
                  final v1 = double.tryParse(ctrl1.text.replaceAll(',', '.'));
                  if (v1 == null) return;
                  final entry = HealthEntry(
                    type: t.key, value: v1,
                    value2: t.hasTwoValues ? ctrl2.text.trim() : null,
                    unit: t.unit, date: DateTime.now(),
                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  );
                  _addEntry(entry);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: t.color, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Enregistrer la mesure', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, TextInputType kb) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: kb,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}
