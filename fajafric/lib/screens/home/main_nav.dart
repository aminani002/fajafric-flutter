import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../appointments/appointments_screen.dart';
import '../messages/messages_screen.dart';
import '../medecins/medecins_screen.dart';
import '../profile/profile_screen.dart';

// Clé globale — permet de changer d'onglet depuis n'importe quel écran
final mainNavKey = GlobalKey<MainNavState>();

/// Raccourci : aller sur l'onglet Médecins (index 3) depuis n'importe où
void goToMedecins() => mainNavKey.currentState?.switchTab(3);

/// Raccourci : aller sur l'onglet RDV (index 1)
void goToRdv() => mainNavKey.currentState?.switchTab(1);

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => MainNavState();
}

class MainNavState extends State<MainNav> {
  int _index = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    AppointmentsScreen(key: appointmentsScreenKey),
    const MessagesScreen(),
    const MedecinsScreen(),
    const ProfileScreen(),
  ];

  /// Appelle depuis n'importe quel écran via mainNavKey.currentState?.switchTab(index)
  void switchTab(int index) {
    setState(() => _index = index);
    if (index == 1) appointmentsScreenKey.currentState?.reload();
  }

  void _onTabSelected(int i) {
    setState(() => _index = i);
    if (i == 1) appointmentsScreenKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primary,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil'),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded),
              label: 'RDV'),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages'),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services_rounded),
              label: 'Médecins'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
