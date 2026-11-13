import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Bandeau haut avec logo ────────────────────────────────
          Container(
            width: double.infinity,
            height: size.height * 0.36,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4))],
            ),
            child: SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('assets/images/logo.png', width: 130, height: 130),
                const SizedBox(height: 12),
                const Text(
                  'Gestion de flotte véhicules',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 0.3),
                ),
              ]),
            ),
          ),

          // ── Formulaire ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              const Text(
                'Connexion',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connectez-vous à votre compte pour continuer.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(children: [

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecor('Adresse email', Icons.email_outlined),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mot de passe
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => auth.loading ? null : _submit(),
                    decoration: _inputDecor('Mot de passe', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                  ),
                ]),
              ),

              // Erreur
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 16, color: AppTheme.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.error!, style: const TextStyle(fontSize: 13, color: AppTheme.danger))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),

              // Bouton
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Se connecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ),
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text('© 2025 KOERE — Tous droits réservés',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
    prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
