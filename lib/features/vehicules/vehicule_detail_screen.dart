import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/libelles.dart';
import '../../core/constants/permissions.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';
import '../di/di_create_screen.dart';
import '../di/di_detail_screen.dart';
import '../inspections/inspection_create_screen.dart';
import '../releves/releve_km_screen.dart';
import 'vehicule_form_screen.dart';

class VehiculeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicule;
  const VehiculeDetailScreen({super.key, required this.vehicule});

  @override
  State<VehiculeDetailScreen> createState() => _VehiculeDetailScreenState();
}

class _VehiculeDetailScreenState extends State<VehiculeDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _detail;
  List<dynamic> _dernieresDI = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loadError = null);
    final id = widget.vehicule['id'];
    try {
      final r = await Future.wait([
        _api.get('/vehicules/$id'),
        _api.get('/demandes-intervention', params: {'vehiculeId': '$id', 'limit': '5'}),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = r[0].data as Map<String, dynamic>;
        _dernieresDI = (r[1].data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _loadError = e;
          _loading = false;
        });
    }
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
    _charger();
  }

  Future<void> _confirmerSuppression() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('Le véhicule ${widget.vehicule['immatriculation']} sera supprimé définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.delete('/vehicules/${widget.vehicule['id']}');
      if (mounted) {
        showSuccessSnack(context, 'Véhicule supprimé');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?['role'] as String?;
    final v = _detail ?? widget.vehicule;
    final type = vehiculeType(v['typeVehicule'] as String?);
    final heures = compteHeures(v['typeVehicule'] as String?);
    final photo = AppConstants.urlFichier(v['photoUrl'] as String?);
    final conducteur = v['conducteurHabituel'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(v['immatriculation'] ?? ''),
        actions: [
          if (autorise(role, 'vehicule.modifier') || autorise(role, 'vehicule.supprimer'))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (a) {
                if (a == 'modifier') _ouvrir(VehiculeFormScreen(vehicule: v));
                if (a == 'supprimer') _confirmerSuppression();
              },
              itemBuilder: (_) => [
                if (autorise(role, 'vehicule.modifier'))
                  const PopupMenuItem(
                    value: 'modifier',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (autorise(role, 'vehicule.supprimer'))
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
      body: _loading
          ? const ChargementListe(lignes: 4)
          : _loadError != null
          ? ErrorView(error: _loadError!, onRetry: _charger)
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  // ── Carte d'identité ──
                  Carte(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (photo.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                color: AppTheme.primaryLight,
                                child: Icon(type.icone, size: 48, color: AppTheme.primary),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (photo.isEmpty) ...[
                                IconeTon(type.icone ?? Icons.directions_car_rounded, taille: 56),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${type.texte} · N° ${v['numeroInterne'] ?? '—'}',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 10),
                                    Pastille(vehiculeStatut(v['statut'] as String?), icone: true, grande: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _chiffre(
                                heures ? '${nombre(v['heuresMoteur'])} h' : '${nombre(v['kilometrage'])} km',
                                heures ? 'Heures moteur' : 'Kilométrage',
                              ),
                              const VerticalDivider(width: 1),
                              _chiffre('${v['annee'] ?? '—'}', 'Année'),
                              const VerticalDivider(width: 1),
                              _chiffre(carburants[v['carburant']] ?? '—', 'Carburant'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Actions ──
                  const TitreSection('Actions'),
                  RangeeEgale(
                    enfants: [
                      if (autorise(role, 'di.creer'))
                        ActionRapide(
                          icone: Icons.report_problem_rounded,
                          libelle: 'Signaler\nune panne',
                          ton: Ton.danger,
                          onTap: () => _ouvrir(DiCreateScreen(vehiculePreselectionne: v)),
                        ),
                      ActionRapide(
                        icone: Icons.speed_rounded,
                        libelle: heures ? 'Relever\nles heures' : 'Relever\nle compteur',
                        ton: Ton.info,
                        onTap: () => _ouvrir(ReleveKmScreen(vehicule: v)),
                      ),
                      if (autorise(role, 'inspection.creer'))
                        ActionRapide(
                          icone: Icons.fact_check_rounded,
                          libelle: 'Faire une\ninspection',
                          ton: Ton.succes,
                          onTap: () => _ouvrir(const InspectionCreateScreen()),
                        ),
                    ],
                  ),

                  // ── Derniers signalements ──
                  if (_dernieresDI.isNotEmpty) ...[
                    const TitreSection('Derniers signalements'),
                    Carte(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < _dernieresDI.length; i++) ...[
                            _ligneDI(_dernieresDI[i] as Map<String, dynamic>),
                            if (i < _dernieresDI.length - 1) const Divider(height: 1, indent: 14),
                          ],
                        ],
                      ),
                    ),
                  ],

                  GroupeInfos(
                    titre: 'Identification',
                    lignes: [
                      LigneInfo(Icons.badge_outlined, 'Immatriculation', v['immatriculation']),
                      LigneInfo(Icons.tag_rounded, 'N° interne', v['numeroInterne']),
                      LigneInfo(Icons.qr_code_rounded, 'N° de série', v['numeroSerie']),
                      LigneInfo(Icons.palette_outlined, 'Couleur', v['couleur']),
                    ],
                  ),
                  GroupeInfos(
                    titre: 'Affectation',
                    lignes: [
                      LigneInfo(Icons.location_city_rounded, 'Entité', v['entite']),
                      LigneInfo(Icons.apartment_rounded, 'Département', v['departement']),
                      LigneInfo(Icons.place_outlined, 'Site', v['siteGeographique']),
                      LigneInfo(
                        Icons.person_outline_rounded,
                        'Chauffeur',
                        conducteur != null ? '${conducteur['prenom'] ?? ''} ${conducteur['nom'] ?? ''}' : null,
                      ),
                      LigneInfo(
                        Icons.event_available_rounded,
                        'Mise en service',
                        v['dateMiseEnService'] != null ? dateCourte(v['dateMiseEnService']) : null,
                      ),
                      LigneInfo(
                        Icons.shopping_bag_outlined,
                        'Acquisition',
                        v['dateAcquisition'] != null ? dateCourte(v['dateAcquisition']) : null,
                      ),
                    ],
                  ),
                  if ((v['notes'] as String?)?.trim().isNotEmpty ?? false) ...[
                    const TitreSection('Notes'),
                    Carte(child: Text(v['notes'], style: const TextStyle(fontSize: 14, height: 1.5))),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _chiffre(String valeur, String libelle) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        children: [
          Text(
            valeur,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(libelle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
        ],
      ),
    ),
  );

  Widget _ligneDI(Map<String, dynamic> d) => InkWell(
    onTap: () => _ouvrir(DiDetailScreen(di: d)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['description'] ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary, height: 1.35),
                ),
                const SizedBox(height: 3),
                Text(
                  ilYA(d['dateSignalement'] ?? d['createdAt']),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pastille(diStatut(d['statut'] as String?)),
        ],
      ),
    ),
  );
}
