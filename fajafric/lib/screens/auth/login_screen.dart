import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fajafric_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (result['ok']) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() { _error = result['message']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [

          // ── HEADER TEAL GRADIENT ─────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.tealMid, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            padding: EdgeInsets.only(
              top:    MediaQuery.of(context).padding.top + 44,
              bottom: 52,
              left: 24, right: 24,
            ),
            child: Column(children: [
              const FajafricLogo(
                onDark: true, fontSize: 36,
                showSlogan: true, animated: true,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Hope & Health · Santé · Médecine',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
              ),
            ]),
          ),

          // ── FORMULAIRE ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const Text('Connexion',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Accédez à votre espace santé',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 28),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.red.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, color: AppTheme.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                        style: TextStyle(color: AppTheme.red, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                _label('Adresse email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDeco('votre@email.com',
                    const Icon(Icons.email_outlined, color: AppTheme.textSecondary)),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 16),

                _label('Mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDeco('••••••••',
                    const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                    suffix: IconButton(
                      icon: Icon(_showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        color: AppTheme.textSecondary),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    )),
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Min. 6 caractères',
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppTheme.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                      ? const SizedBox(height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Se connecter',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),

                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Pas encore de compte ? ",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text("S'inscrire",
                      style: TextStyle(color: AppTheme.primary,
                        fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, Widget prefix, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      fillColor: AppTheme.bgElevated,
      filled: true,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.red),
      ),
    );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary));
}
