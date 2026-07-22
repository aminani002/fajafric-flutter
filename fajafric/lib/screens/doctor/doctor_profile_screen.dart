import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'signature_pad_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});
  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _signatureB64;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getDoctorProfile(),
      loadSignature(),
    ]);
    if (mounted) {
      setState(() {
        _profile      = results[0] as Map<String, dynamic>?;
        _signatureB64 = results[1] as String?;
        _loading      = false;
      });
    }
  }

  Future<void> _openSignaturePad() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );
    if (result != null && mounted) {
      setState(() => _signatureB64 = result);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Signature enregistrée'),
        backgroundColor: AppTheme.teal,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteSignature() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la signature'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await clearSignature();
      if (mounted) setState(() => _signatureB64 = null);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _editProfile() {
    final p = _profile;
    if (p == null) return;
    final prenomCtrl = TextEditingController(text: p['prenom'] ?? '');
    final nomCtrl    = TextEditingController(text: p['nom'] ?? '');
    final specCtrl   = TextEditingController(text: p['specialite'] ?? '');
    final bioCtrl    = TextEditingController(text: p['bio'] ?? '');
    final villeCtrl  = TextEditingController(text: p['ville'] ?? '');
    final paysCtrl   = TextEditingController(text: p['pays'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Modifier le profil',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    )),
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
                children: [
                  _field('Prénom', prenomCtrl),
                  _field('Nom', nomCtrl),
                  _field('Spécialité', specCtrl,
                      hint: 'Ex: Cardiologue, Médecin généraliste…'),
                  _field('Bio', bioCtrl,
                      maxLines: 4, hint: 'Décrivez votre pratique…'),
                  _field('Ville', villeCtrl),
                  _field('Pays', paysCtrl),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await ApiService.updateDoctorProfile({
                          'prenom': prenomCtrl.text.trim(),
                          'nom': nomCtrl.text.trim(),
                          'specialite': specCtrl.text.trim(),
                          'bio': bioCtrl.text.trim(),
                          'ville': villeCtrl.text.trim(),
                          'pays': paysCtrl.text.trim(),
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? 'Profil mis à jour' : 'Erreur'),
                            backgroundColor: ok ? AppTheme.teal : AppTheme.red,
                            behavior: SnackBarBehavior.floating,
                          ));
                          if (ok) _load();
                        }
                      },
                      child: const Text('Enregistrer',
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

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.bgElevated,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.teal, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p       = _profile;
    final prenom  = p?['prenom'] ?? '';
    final nom     = p?['nom'] ?? '';
    final spec    = p?['specialite'] ?? 'Médecin';
    final bio     = p?['bio'] as String?;
    final ville   = p?['ville'] as String?;
    final pays    = p?['pays'] as String?;
    final lieu    = [ville, pays]
        .where((s) => s != null && s!.isNotEmpty)
        .join(', ');
    final initials =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.teal, strokeWidth: 2.5))
          : CustomScrollView(slivers: [
              // ── HEADER ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.tealMid,
                        AppTheme.primaryLight
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.55, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 32,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(children: [
                    GestureDetector(
                      onTap: _editProfile,
                      child: Stack(alignment: Alignment.center, children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(initials.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 14, color: AppTheme.primary),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text('Dr. $prenom $nom',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(spec,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                    if (lieu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 3),
                        Text(lieu,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                      ]),
                    ],
                  ]),
                ),
              ),

              // ── BIO ───────────────────────────────────────────────────────
              if (bio != null && bio.isNotEmpty)
                SliverToBoxAdapter(
                  child: _card(
                    margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('À propos',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          Text(bio,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.inkSoft,
                                  height: 1.5)),
                        ]),
                  ),
                ),

              // ── SIGNATURE ÉLECTRONIQUE ────────────────────────────────────
              SliverToBoxAdapter(
                child: _card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.draw_rounded,
                                color: Color(0xFF6366F1), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Signature électronique',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary)),
                                  Text(
                                      'Apparaît sur vos ordonnances et rapports',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.inkSoft)),
                                ]),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        if (_signatureB64 != null) ...[
                          // Aperçu
                          Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SignatureImage(
                                    base64: _signatureB64!, height: 76),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Modifier'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                      color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                onPressed: _openSignaturePad,
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _deleteSignature,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.red,
                                side: BorderSide(
                                    color: AppTheme.red.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              child: const Icon(
                                  Icons.delete_outline_rounded, size: 18),
                            ),
                          ]),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(children: [
                              Icon(Icons.draw_outlined,
                                  size: 32, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text('Aucune signature enregistrée',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.inkSoft)),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.draw_rounded, size: 18),
                              label: const Text('Créer ma signature',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              onPressed: _openSignaturePad,
                            ),
                          ),
                        ],
                      ]),
                ),
              ),

              // ── MENU ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(children: [
                    _menuItem(Icons.edit_rounded, 'Modifier le profil',
                        AppTheme.teal, _editProfile),
                    _divider(),
                    _menuItem(Icons.help_outline_rounded, 'Aide & Support',
                        Colors.blueGrey, () {}),
                    _divider(),
                    _menuItem(
                        Icons.logout_rounded, 'Déconnexion', AppTheme.red, _logout),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]),
    );
  }

  Widget _card({required Widget child, EdgeInsets? margin}) => Container(
        margin: margin ?? EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );

  Widget _menuItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary))),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 20),
        ]),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 52, color: Color(0xFFEEEEEE));
}
