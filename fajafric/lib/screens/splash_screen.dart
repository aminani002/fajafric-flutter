import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fajafric_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    final user = await AuthService.getUser();
    final route = user?.role == 'medecin' ? '/doctor' : '/home';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.tealMid, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                const FajafricLogo(
                  onDark: true, fontSize: 42,
                  showSlogan: true, animated: true,
                ),

                const SizedBox(height: 80),

                SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.7),
                    strokeWidth: 2.5,
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Chargement de votre espace santé…',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
