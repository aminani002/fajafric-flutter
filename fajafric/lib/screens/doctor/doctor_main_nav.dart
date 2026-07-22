import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'doctor_keys.dart';
import 'doctor_home_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_messages_screen.dart';
import 'doctor_actes_screen.dart';
import 'doctor_profile_screen.dart';

final doctorNavKey = GlobalKey<DoctorMainNavState>();

class DoctorMainNav extends StatefulWidget {
  const DoctorMainNav({super.key});
  @override
  State<DoctorMainNav> createState() => DoctorMainNavState();
}

class DoctorMainNavState extends State<DoctorMainNav> {
  int _index = 0;

  final List<Widget> _screens = const [
    DoctorHomeScreen(),
    DoctorAppointmentsScreen(),
    DoctorMessagesScreen(),
    DoctorActesScreen(),
    DoctorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    doctorSwitchTab = switchTab;
  }

  @override
  void dispose() {
    doctorSwitchTab = null;
    super.dispose();
  }

  void switchTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primary,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded),
              label: 'Planning',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'Actes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
