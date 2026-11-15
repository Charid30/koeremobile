import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/libelles.dart';
import '../../core/constants/permissions.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';

class DiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> di;
  const DiDetailScreen({super.key, required this.di});

  @override
  State<DiDetailScreen> createState() => _DiDetailScreenState();
}

class _DiDetailScreenState extends State<DiDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/demandes-intervention/${widget.di['id']}');
      setState(() {
        _detail = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _detail = widget.di;
        _loading = false;
      });
    }
  }

  // Corrigé : utilise /statut
  Future<void> _changerStatut(String statut) async {
    setState(() => _actionLoading = true);
    try {
      await _api.patch('/demandes-intervention/${widget.di['id']}/statut', data: {'statut': statut});
      await _charger();
      if (mounted) showSuccessSnack(context, 'Statut mis à jour');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
    setState(() => _actionLoading = false);
  }

  Future<void> _supprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la demande'),
        content: const Text('Cette action est irréversible. Confirmer la suppression ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.delete('/demandes-intervention/${widget.di['id']}');
      if (mounted) {
        Navigator.pop(context, true);
        showSuccessSnack(context, 'Demande supprimée');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _editer() async {
    final d = _detail ?? widget.di;
    final descCtrl = TextEditingController(text: d['description'] as String? ?? '');
    final locCtrl = TextEditingController(text: d['localisation'] as String? ?? '');
    String priorite = d['priorite'] as String? ?? 'NORMALE';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Modifier la demande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: descCtrl, maxLines: 3, decoration: _inputDecor('Décrivez le problème...')),
                  const SizedBox(height: 14),

                  // Localisation
                  const Text(
                    'Localisation',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: locCtrl, decoration: _inputDecor('Rue, quartier, ville...')),
                  const SizedBox(height: 14),

                  // Priorité
                  const Text(
                    'Priorité',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ChoixPriorite(valeur: priorite, onChanged: (p) => setLocal(() => priorite = p)),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _api.patch(
                            '/demandes-intervention/${widget.di['id']}',
                            data: {
                              if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                              if (locCtrl.text.trim().isNotEmpty) 'localisation': locCtrl.text.trim(),
                              'priorite': priorite,
                            },
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) showErrorSnack(ctx, e);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    descCtrl.dispose();
    locCtrl.dispose();
    if (saved == true) {
      await _charger();
      if (mounted) showSuccessSnack(context, 'Demande modifiée');
    }
  }

  void _voirPhoto(String url) => showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InteractiveViewer(
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?['role'] as String?;
    final d = _detail ?? widget.di;
    final statut = d['statut'] as String? ?? '';
    final p = priorite(d['priorite'] as String?);
    final v = d['vehicule'] as Map<String, dynamic>?;
    final declarant = d['declarant'] as Map<String, dynamic>?;
    final photos = (d['photos'] as List?) ?? [];
    final ots = (d['ordresTravail'] as List?) ?? [];
    final ouverte = statut != 'TRAITEE' && statut != 'REJETEE';
    final peutTraiter = autorise(role, 'di.traiter');

    return Scaffold(
      appBar: AppBar(
        title: Text(d['numeroDI'] ?? 'Signalement'),
        actions: [
          if (peutTraiter || autorise(role, 'di.supprimer'))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (a) {
                if (a == 'modifier') _editer();
                if (a == 'supprimer') _supprimer();
              },
              itemBuilder: (_) => [
                if (peutTraiter)
                  const PopupMenuItem(
                    value: 'modifier',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (autorise(role, 'di.supprimer'))
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
      bottomNavigationBar: ouverte && peutTraiter && !_loading
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: _actionLoading
                    ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _changerStatut('REJETEE'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                              child: const Text('Rejeter'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: statut == 'EN_ATTENTE'
                                ? FilledButton.icon(
                                    onPressed: () => _changerStatut('PRISE_EN_CHARGE'),
                                    icon: const Icon(Icons.handyman_rounded, size: 18),
                                    label: const Text('Prendre en charge'),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _changerStatut('TRAITEE'),
                                    style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Marquer traitée'),
                                  ),
                          ),
                        ],
                      ),
              ),
            )
          : null,
      body: _loading
          ? const ChargementListe(lignes: 3)
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  // ── En-tête ──
                  Carte(
                    bordureGauche: couleursTon(p.ton).$2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Pastille(diStatut(statut), icone: true, grande: true),
                            Pastille(
                              Libelle('Priorité ${p.texte.toLowerCase()}', p.ton, p.icone),
                              icone: true,
                              grande: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          d['description'] ?? '—',
                          style: const TextStyle(fontSize: 15.5, height: 1.5, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Signalé ${ilYA(d['dateSignalement'] ?? d['createdAt'])}'
                          '${declarant != null ? ' par ${declarant['prenom'] ?? ''} ${declarant['nom'] ?? ''}' : ''}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // ── Photos ──
                  if (photos.isNotEmpty) ...[
                    TitreSection('Photos (${photos.length})'),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final url = AppConstants.urlFichier((photos[i] as Map)['url'] as String?);
                          return GestureDetector(
                            onTap: () => _voirPhoto(url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  width: 96,
                                  color: AppTheme.primaryLight,
                                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.primary),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Lieu ──
                  if (d['localisation'] != null && (d['localisation'] as String).isNotEmpty) ...[
                    const TitreSection('Lieu'),
                    _localisationCard(d['localisation'] as String),
                  ],

                  // ── Véhicule ──
                  GroupeInfos(
                    titre: 'Véhicule',
                    lignes: [
                      LigneInfo(Icons.badge_outlined, 'Immatriculation', v?['immatriculation']),
                      LigneInfo(
                        Icons.directions_car_outlined,
                        'Modèle',
                        v != null ? '${v['marque'] ?? ''} ${v['modele'] ?? ''}' : null,
                      ),
                      LigneInfo(Icons.tag_rounded, 'N° interne', v?['numeroInterne']),
                    ],
                  ),

                  // ── Suite donnée ──
                  if (ots.isNotEmpty) ...[
                    const TitreSection('Ordres de travail'),
                    Carte(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < ots.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_circle_outlined, size: 20, color: AppTheme.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      (ots[i] as Map)['numeroOT'] ?? 'OT',
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Pastille(otStatut((ots[i] as Map)['statut'] as String?)),
                                ],
                              ),
                            ),
                            if (i < ots.length - 1) const Divider(height: 1, indent: 44),
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

  // Retourne true si le texte ressemble à "lat, lon"
  bool _estCoordonnees(String loc) {
    final parts = loc.split(',');
    if (parts.length != 2) return false;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    return lat != null && lon != null;
  }

  Future<void> _ouvrirGoogleMaps(String loc) async {
    final parts = loc.split(',');
    final lat = parts[0].trim();
    final lon = parts[1].trim();
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _localisationCard(String loc) {
    final isGps = _estCoordonnees(loc);
    return Carte(
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(loc, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
          if (isGps) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _ouvrirGoogleMaps(loc),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Maps', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppTheme.primaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
