import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _nouveauCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscureNv      = true;
  bool _obscureConf    = true;
  bool _submitting     = false;

  @override
  void dispose() {
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(String? role) => switch (role) {
    'ADMIN'                   => 'Administrateur',
    'DIRECTION'               => 'Direction',
    'RESPONSABLE_PARC'        => 'Responsable parc',
    'RESPONSABLE_MAINTENANCE' => 'Responsable maintenance',
    'MECANICIEN'              => 'Mécanicien',
    'CHAUFFEUR'               => 'Chauffeur',
    _                         => role ?? '-',
  };

  Future<void> _changerMotDePasse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = context.read<AuthProvider>().user;
      final id = user?['id'] as int?;
      if (id == null) throw Exception('Utilisateur non identifié');
      await _api.patch('/users/$id/reset-mot-de-passe', data: {
        'nouveauMotDePasse': _nouveauCtrl.text,
      });
      if (mounted) {
        _nouveauCtrl.clear();
        _confirmCtrl.clear();
        showSuccessSnack(context, 'Mot de passe modifié avec succès.');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + nom
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  (user?['prenom'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${user?['prenom'] ?? ''} ${user?['nom'] ?? ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _roleLabel(user?['role'] as String?),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Informations
          _card([
            _row(Icons.email_outlined, 'Email', user?['email'] as String? ?? '-'),
            _divider(),
            _row(Icons.phone_outlined, 'Téléphone', user?['telephone'] as String? ?? 'Non renseigné'),
            _divider(),
            _row(Icons.badge_outlined, 'Matricule', user?['matricule'] as String? ?? 'Non renseigné'),
          ]),
          const SizedBox(height: 24),

          // Changer mot de passe
          Row(children: [
            const Icon(Icons.lock_outline, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            const Text('Changer le mot de passe',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: _card([
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  TextFormField(
                    controller: _nouveauCtrl,
                    obscureText: _obscureNv,
                    decoration: _inputDecor('Nouveau mot de passe', Icons.lock_outline, IconButton(
                      icon: Icon(_obscureNv ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: () => setState(() => _obscureNv = !_obscureNv),
                    )),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (v.length < 8) return 'Minimum 8 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConf,
                    decoration: _inputDecor('Confirmer le nouveau mot de passe', Icons.lock_outline, IconButton(
                      icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: () => setState(() => _obscureConf = !_obscureConf),
                    )),
                    validator: (v) {
                      if (v != _nouveauCtrl.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _changerMotDePasse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(children: children),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), textAlign: TextAlign.end)),
    ]),
  );

  Widget _divider() => const Divider(height: 1, indent: 46);

  InputDecoration _inputDecor(String hint, IconData icon, Widget? suffix) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}
