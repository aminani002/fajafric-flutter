import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = await AuthService.getUser();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _user == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                // ── AVATAR + NOM ───────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.teal, AppTheme.tealDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(_user!.initials, style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800,
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(_user!.fullName, style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 4),
                    Text(_user!.email, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                  ]),
                ),

                // ── INFOS ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _infoCard([
                        _infoRow(Icons.person_outline, 'Prénom', _user!.prenom),
                        _infoRow(Icons.person_outline, 'Nom', _user!.nom),
                        _infoRow(Icons.email_outlined, 'Email', _user!.email),
                        if (_user!.genre != null)
                          _infoRow(Icons.wc_outlined, 'Genre', _user!.genre == 'homme' ? 'Homme' : 'Femme'),
                        if (_user!.pays != null)
                          _infoRow(Icons.flag_outlined, 'Pays', _user!.pays!),
                        if (_user!.dateNaissance != null)
                          _infoRow(Icons.cake_outlined, 'Date de naissance', _user!.dateNaissance!),
                        if (_user!.pathologie != null)
                          _infoRow(Icons.medical_information_outlined, 'Pathologie', _user!.pathologie!),
                      ]),
                      const SizedBox(height: 16),

                      // ── MENU ───────────────────────────
                      _menuItem(Icons.lock_outline, 'Changer le mot de passe', onTap: () {}),
                      _menuItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
                      _menuItem(Icons.help_outline, 'Aide & Support', onTap: () {}),
                      const SizedBox(height: 8),
                      _menuItem(Icons.logout_rounded, 'Se déconnecter', color: AppTheme.red, onTap: _logout),
                      const SizedBox(height: 32),
                      const Text('Fajafric — Hope & Health v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.inkSoft),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.ink),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: color ?? AppTheme.ink, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color ?? AppTheme.inkSoft),
          ],
        ),
      ),
    );
  }
}
