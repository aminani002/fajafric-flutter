import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  String _genre     = 'homme';
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.register({
      'prenom':   _prenomCtrl.text.trim(),
      'nom':      _nomCtrl.text.trim(),
      'email':    _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'password_confirmation': _passCtrl.text,
      'role':     'patient',
      'genre':    _genre,
    });
    if (!mounted) return;
    if (result['ok']) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() { _error = result['message']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte'), backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.red.withOpacity(0.2)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                _field('Prénom', _prenomCtrl, Icons.person_outline, 'Votre prénom'),
                const SizedBox(height: 14),
                _field('Nom', _nomCtrl, Icons.person_outline, 'Votre nom'),
                const SizedBox(height: 14),
                _field('Email', _emailCtrl, Icons.email_outlined, 'votre@email.com',
                  type: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'Email invalide'),
                const SizedBox(height: 14),

                // Genre
                const Text('Genre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                Row(children: [
                  for (final g in ['homme', 'femme'])
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(g == 'homme' ? 'Homme' : 'Femme'),
                        selected: _genre == g,
                        selectedColor: AppTheme.teal.withOpacity(0.15),
                        onSelected: (_) => setState(() => _genre = g),
                      ),
                    ),
                ]),
                const SizedBox(height: 14),

                // Mot de passe
                const Text('Mot de passe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  decoration: InputDecoration(
                    hintText: 'Min. 8 caractères',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  validator: (v) => v != null && v.length >= 8 ? null : 'Min. 8 caractères',
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("S'inscrire"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Déjà un compte ? ', style: TextStyle(color: AppTheme.inkSoft, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('Se connecter', style: TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, String hint, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
          validator: validator ?? (v) => v != null && v.isNotEmpty ? null : 'Champ requis',
        ),
      ],
    );
  }
}
