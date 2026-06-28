import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

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
      appBar: AppBar(title: const Text('Médecins')),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin ou spécialité...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _search(''); })
                  : null,
              ),
            ),
          ),

          // Liste
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_search_outlined, size: 52, color: AppTheme.line),
                      SizedBox(height: 12),
                      Text('Aucun médecin trouvé', style: TextStyle(color: AppTheme.inkSoft)),
                    ]),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> m) {
    final initials = '${(m['prenom'] ?? ' ')[0]}${(m['nom'] ?? ' ')[0]}';
    final nom = 'Dr. ${m['prenom'] ?? ''} ${m['nom'] ?? ''}';
    final spec = m['specialite'] ?? 'Médecin généraliste';
    final pays = m['pays'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.teal,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(spec, style: const TextStyle(fontSize: 13, color: AppTheme.teal)),
                  if (pays.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(pays, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  ],
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('RDV'),
            ),
          ],
        ),
      ),
    );
  }
}
