import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../appointments/new_appointment_screen.dart'; // bottom sheet

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
        (m['specialite'] ?? '').toLowerCase().contains(query) ||
        (m['ville'] ?? '').toLowerCase().contains(query) ||
        (m['pays'] ?? '').toLowerCase().contains(query)
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
              hintText: 'Rechercher nom, spécialité, ville...',
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
    final ville = (m['ville'] as String?)?.isNotEmpty == true ? m['ville'] as String : null;
    final pays  = (m['pays']  as String?)?.isNotEmpty == true ? m['pays']  as String : null;
    final lieu  = ville ?? pays ?? '';

    final colors = [AppTheme.teal, const Color(0xFF6366F1), const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEC4899)];
    final colorIdx = nom.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    final avatarColor = colors[colorIdx];

    return GestureDetector(
      onTap: () => _showDoctorDetail(m, avatarColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: avatarColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(spec, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: avatarColor)),
              ),
              if (lieu.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.teal),
                  const SizedBox(width: 3),
                  Text(lieu, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft, fontWeight: FontWeight.w500)),
                ]),
              ],
            ])),
            GestureDetector(
              onTap: () => NewAppointmentScreen.show(context, medecin: m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('RDV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDoctorDetail(Map<String, dynamic> m, Color avatarColor) {
    final nom     = 'Dr. ${m['prenom'] ?? ''} ${m['nom'] ?? ''}';
    final spec    = m['specialite'] ?? 'Médecin généraliste';
    final ville   = (m['ville'] as String?)?.isNotEmpty == true ? m['ville'] as String : null;
    final pays    = (m['pays']  as String?)?.isNotEmpty == true ? m['pays']  as String : null;
    final lieu    = ville != null && pays != null ? '$ville, $pays' : ville ?? pays ?? '';
    final bio     = m['bio'] as String?;
    final initials = '${(m['prenom'] ?? ' ')[0]}${(m['nom'] ?? ' ')[0]}'.toUpperCase();
    final soins   = (m['soins_actes'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), children: [
              // Avatar + nom
              Row(children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(color: avatarColor.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                  child: Center(child: Text(initials, style: TextStyle(color: avatarColor, fontWeight: FontWeight.w800, fontSize: 22))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: avatarColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(spec, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: avatarColor)),
                  ),
                  if (lieu.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: AppTheme.teal),
                      const SizedBox(width: 3),
                      Text(lieu, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft, fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ])),
              ]),
              const SizedBox(height: 24),

              // Bio
              if (bio != null && bio.isNotEmpty) ...[
                const Text('À propos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(bio, style: const TextStyle(fontSize: 13.5, color: AppTheme.inkSoft, height: 1.5)),
                const SizedBox(height: 24),
              ],

              // Soins & Actes
              if (soins.isNotEmpty) ...[
                const Text('Soins & Actes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: soins.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.08),
                    border: Border.all(color: AppTheme.teal.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.teal)),
                )).toList()),
                const SizedBox(height: 28),
              ] else ...[
                const SizedBox(height: 8),
              ],

              // Bouton RDV
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Prendre un rendez-vous', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NewAppointmentScreen(medecin: m)));
                  },
                ),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}
