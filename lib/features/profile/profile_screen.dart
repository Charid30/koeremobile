import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/libelles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();

  Future<void> _deconnecter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau votre email et votre mot de passe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final nav = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    nav.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  /// Changement de mot de passe : le mot de passe actuel est exigé par l'API,
  /// et les autres appareils sont déconnectés par sécurité.
  Future<void> _changerMotDePasse() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FeuilleMotDePasse(api: _api),
    );
    if (ok == true && mounted)
      showSuccessSnack(context, 'Mot de passe modifié. Vos autres appareils ont été déconnectés.');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};
    final haut = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── En-tête ──
          Container(
            padding: EdgeInsets.fromLTRB(8, haut + 4, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.brand, Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Mon profil',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Avatar(prenom: user['prenom'], nom: user['nom'], taille: 76, clair: true),
                const SizedBox(height: 12),
                Text(
                  '${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    role(user['role'] as String?),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GroupeInfos(
                  titre: 'Mes informations',
                  lignes: [
                    LigneInfo(Icons.mail_outline_rounded, 'Email', user['email']),
                    LigneInfo(Icons.phone_outlined, 'Téléphone', user['telephone'] ?? 'Non renseigné'),
                    LigneInfo(Icons.badge_outlined, 'Matricule', user['matricule'] ?? 'Non renseigné'),
                  ],
                ),
                const TitreSection('Sécurité'),
                Carte(
                  onTap: _changerMotDePasse,
                  child: const Row(
                    children: [
                      IconeTon(Icons.lock_reset_rounded, taille: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Changer mon mot de passe',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Au moins 8 caractères',
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _deconnecter,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SOFARY GMAO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeuilleMotDePasse extends StatefulWidget {
  final ApiService api;
  const _FeuilleMotDePasse({required this.api});

  @override
  State<_FeuilleMotDePasse> createState() => _FeuilleMotDePasseState();
}

class _FeuilleMotDePasseState extends State<_FeuilleMotDePasse> {
  final _formKey = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirm = TextEditingController();
  bool _masque = true;
  bool _envoi = false;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await widget.api.patch(
        '/auth/changer-mot-de-passe',
        data: {'motDePasseActuel': _actuel.text, 'nouveauMotDePasse': _nouveau.text},
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _envoi = false);
        showErrorSnack(context, e);
      }
    }
  }

  InputDecoration _deco(String libelle) => InputDecoration(
    labelText: libelle,
    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
    suffixIcon: IconButton(
      icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
      onPressed: () => setState(() => _masque = !_masque),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Changer mon mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _actuel,
            obscureText: _masque,
            decoration: _deco('Mot de passe actuel'),
            validator: (v) => (v == null || v.isEmpty) ? 'Saisissez votre mot de passe actuel' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nouveau,
            obscureText: _masque,
            decoration: _deco('Nouveau mot de passe'),
            validator: (v) => (v == null || v.length < 8) ? 'Au moins 8 caractères' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirm,
            obscureText: _masque,
            decoration: _deco('Confirmer le nouveau mot de passe'),
            validator: (v) => v != _nouveau.text ? 'Les deux mots de passe sont différents' : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _envoi ? null : _valider,
            child: _envoi
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}
