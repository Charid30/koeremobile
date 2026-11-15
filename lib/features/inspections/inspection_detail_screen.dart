import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/libelles.dart';
import '../../core/constants/permissions.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _inspection;
  bool _loading = true;
  Object? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/inspections/${widget.inspectionId}');
      setState(() {
        _inspection = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _editerNotes() async {
    final ctrl = TextEditingController(text: _inspection?['notes'] as String? ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier les notes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Notes...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _submitting = true);
    try {
      await _api.patch('/inspections/${widget.inspectionId}', data: {'notes': result});
      await _charger();
      if (mounted) showSuccessSnack(context, 'Notes mises à jour.');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _supprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'inspection'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _submitting = true);
    try {
      await _api.delete('/inspections/${widget.inspectionId}');
      if (mounted) {
        showSuccessSnack(context, 'Inspection supprimée.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection')),
        body: const ChargementListe(lignes: 4),
      );
    if (_error != null)
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: _error!, onRetry: _charger),
      );

    final role = context.watch<AuthProvider>().user?['role'] as String?;
    final ins = _inspection!;
    final v = ins['vehicule'] as Map<String, dynamic>?;
    final s = inspectionStatut(ins['statut'] as String?);
    final (fond, couleur) = couleursTon(s.ton);
    final note = (ins['noteGlobale'] as num?)?.toDouble();
    final items = (ins['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final ok = items.where((i) => i['resultat'] == 'OK').length;
    final ko = items.where((i) => i['resultat'] == 'KO').length;
    final parCategorie = <String, List<Map<String, dynamic>>>{};
    for (final m in items) {
      parCategorie.putIfAbsent(m['categorie'] as String? ?? 'Autre', () => []).add(m);
    }
    final inspecteur = ins['inspecteur'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection'),
        actions: [
          if (autorise(role, 'inspection.modifier') || autorise(role, 'inspection.supprimer'))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              enabled: !_submitting,
              onSelected: (a) {
                if (a == 'notes') _editerNotes();
                if (a == 'supprimer') _supprimer();
              },
              itemBuilder: (_) => [
                if (autorise(role, 'inspection.modifier'))
                  const PopupMenuItem(
                    value: 'notes',
                    child: ListTile(
                      leading: Icon(Icons.edit_note_rounded),
                      title: Text('Modifier les notes'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (autorise(role, 'inspection.supprimer'))
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: AppTheme.danger),
                      title: Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // ── Résultat ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: note == null ? 0 : (note / 20).clamp(0, 1),
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.7),
                            valueColor: AlwaysStoppedAnimation(couleur),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              note == null ? '—' : (note % 1 == 0 ? note.toInt().toString() : note.toStringAsFixed(1)),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: couleur, height: 1),
                            ),
                            Text(
                              '/20',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: couleur),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(s.icone, color: couleur, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              s.texte,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: couleur),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${inspectionType(ins['typeInspection'] as String?)} · ${dateCourte(ins['dateInspection'])}',
                          style: TextStyle(fontSize: 13, color: couleur.withValues(alpha: 0.85)),
                        ),
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$ok conforme${ok > 1 ? 's' : ''} · $ko défaut${ko > 1 ? 's' : ''} sur ${items.length} points',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: couleur),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            GroupeInfos(
              titre: 'Détails',
              lignes: [
                LigneInfo(Icons.badge_outlined, 'Véhicule', v?['immatriculation']),
                LigneInfo(
                  Icons.directions_car_outlined,
                  'Modèle',
                  v != null ? '${v['marque'] ?? ''} ${v['modele'] ?? ''}' : null,
                ),
                LigneInfo(
                  Icons.speed_rounded,
                  'Compteur relevé',
                  ins['kilometrageReleve'] != null ? '${nombre(ins['kilometrageReleve'])} km' : null,
                ),
                LigneInfo(
                  Icons.schedule_rounded,
                  'Heures relevées',
                  ins['heuresMoteurReleve'] != null ? '${nombre(ins['heuresMoteurReleve'])} h' : null,
                ),
                LigneInfo(
                  Icons.person_outline_rounded,
                  'Inspecteur',
                  inspecteur != null ? '${inspecteur['prenom'] ?? ''} ${inspecteur['nom'] ?? ''}' : null,
                ),
              ],
            ),

            if ((ins['notes'] as String?)?.trim().isNotEmpty ?? false) ...[
              const TitreSection('Notes'),
              Carte(child: Text(ins['notes'] as String, style: const TextStyle(fontSize: 14, height: 1.5))),
            ],

            for (final e in parCategorie.entries) ...[
              TitreSection(e.key),
              Carte(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < e.value.length; i++) ...[
                      _itemRow(e.value[i]),
                      if (i < e.value.length - 1) const Divider(height: 1, indent: 46),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final resultat = item['resultat'] as String? ?? 'NA';
    final (ton, icone) = switch (resultat) {
      'OK' => (Ton.succes, Icons.check_circle_rounded),
      'KO' => (Ton.danger, Icons.cancel_rounded),
      _ => (Ton.neutre, Icons.remove_circle_outline_rounded),
    };
    final couleur = couleursTon(ton).$2;
    final photo = AppConstants.urlFichier(item['photoUrl'] as String?);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['libelle'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: resultat == 'KO' ? FontWeight.w600 : FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if ((item['observation'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    item['observation'] as String,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (photo.isNotEmpty) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: photo, width: 44, height: 44, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
