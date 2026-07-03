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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
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
      backgroundColor: AppTheme.bg,
      body: _user == null
        ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
        : CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _infoSection(),
                const SizedBox(height: 16),
                _menuSection(),
                const SizedBox(height: 24),
                Text('Hope & Health — Fajafric v1.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 32),
              ]),
            )),
          ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.tealMid, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight, stops: [0.0, 0.55, 1.0]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 32, left: 20, right: 20),
      child: Column(children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
          ),
          child: Center(child: Text(_user!.initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 14),
        Text(_user!.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(_user!.email, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Text('Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _infoSection() {
    final infos = [
      if (_user!.genre != null) _InfoItem(Icons.wc_rounded, 'Genre', _user!.genre == 'homme' ? 'Homme' : 'Femme'),
      if (_user!.pays != null)  _InfoItem(Icons.flag_rounded, 'Pays', _user!.pays!),
      if (_user!.dateNaissance != null) _InfoItem(Icons.cake_rounded, 'Naissance', _user!.dateNaissance!),
      if (_user!.pathologie != null)    _InfoItem(Icons.medical_information_rounded, 'Pathologie', _user!.pathologie!),
    ];
    if (infos.isEmpty) return const SizedBox.shrink();
    return _card(
      title: 'Mes informations',
      child: Column(children: infos.asMap().entries.map((e) => Column(children: [
        _infoRow(e.value.icon, e.value.label, e.value.value),
        if (e.key < infos.length - 1) const Divider(height: 1),
      ])).toList()),
    );
  }

  Widget _menuSection() {
    final items = [
      _MenuItem(Icons.lock_outline_rounded, 'Changer le mot de passe', null, () {}),
      _MenuItem(Icons.notifications_outlined, 'Notifications', null, () {}),
      _MenuItem(Icons.help_outline_rounded, 'Aide & Support', null, () {}),
      _MenuItem(Icons.logout_rounded, 'Se déconnecter', AppTheme.red, _logout),
    ];
    return Column(children: items.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (item.color ?? AppTheme.teal).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color ?? AppTheme.teal, size: 20),
        ),
        title: Text(item.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: item.color ?? AppTheme.textPrimary)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        onTap: item.onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    )).toList());
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
        ),
        const Divider(height: 1),
        child,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 17, color: AppTheme.teal),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _InfoItem { final IconData icon; final String label, value; _InfoItem(this.icon, this.label, this.value); }
class _MenuItem { final IconData icon; final String label; final Color? color; final VoidCallback onTap; _MenuItem(this.icon, this.label, this.color, this.onTap); }
