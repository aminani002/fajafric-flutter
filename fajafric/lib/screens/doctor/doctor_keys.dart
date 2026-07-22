// Évite l'import circulaire entre doctor_main_nav et doctor_home_screen.
// DoctorMainNav assigne cette fonction dans initState ;
// les autres écrans l'appellent sans importer doctor_main_nav.

/// Appelle switchTab(index) sur DoctorMainNav depuis n'importe quel écran
void Function(int)? doctorSwitchTab;
