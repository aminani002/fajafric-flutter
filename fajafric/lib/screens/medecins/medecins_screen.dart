import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../appointments/new_appointment_screen.dart';

class MedecinsScreen extends StatefulWidget {
  const MedecinsScreen({super.key});
  @override
  State<MedecinsScreen> createState() => _MedecinsScreenState();
}

class _MedecinsScreenState extends State<MedecinsScreen> {
  List<dynamic> _medecins = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final data = await ApiService.getDoctors();
    if (mounted) setState(() { _medecins = data; _filtered = data; _loading = false; });
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _medecins.where((m) =>
        '${m['prenom']} ${m['nom']}'.toLowerCase().contains(query) ||
        (m['specialite'] ?? '').toLowerCase().contains(query)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        // ── HEADER ────────────────────────────────
        SliverAppBar(
          expandedHeight: 130,
          floating: false, pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Nos médecins', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
            )),
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

        // ── RECHERCHE ─────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Rechercher nom, spécialité...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.inkSoft),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _search(''); })
                : null,
            ),
          ),
        )),

        // ── LISTE ─────────────────────────────────
        if (_loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.teal)))
        else if (_filtered.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucun médecin trouvé', style: TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _buildCard(_filtered[i]),
              childCount: _filtered.length,
            )),
          ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> m) {
    final initials = '${(m['prenom'] ?? ' ')[0]}${(m['nom'] ?? ' ')[0]}'.toUpperCase();
    final nom  = 'Dr. ${m['prenom'] ?? ''} ${m['nom'] ?? ''}';
    final spec = m['specialite'] ?? 'Médecin généraliste';
    final pays = m['pays'] ?? '';

    // Couleur basée sur la spécialité
    final colors = [AppTheme.teal, const Color(0xFF6366F1), const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEC4899)];
    final colorIdx = nom.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    final avatarColor = colors[colorIdx];

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
          // Avatar
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(initials, style: TextStyle(
              color: avatarColor, fontWeight: FontWeight.w800, fontSize: 18,
            ))),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(spec, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: avatarColor)),
            ),
            if (pays.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.inkSoft),
                const SizedBox(width: 3),
                Text(pays, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
              ]),
            ],
          ])),
          // Bouton RDV
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => NewAppointmentScreen(medecin: m))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('RDV', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ),
          ),
        ]),
      ),
    );
  }
}
