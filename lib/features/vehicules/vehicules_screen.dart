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
import 'vehicule_detail_screen.dart';
import 'vehicule_form_screen.dart';

/// Regroupement des statuts pour les filtres
const _groupes = <String, List<String>>{
  'ok': ['DISPONIBLE', 'EN_CIRCULATION'],
  'atelier': ['EN_MAINTENANCE', 'EN_ATTENTE_REPARATION_EXTERNE', 'EN_ATTENTE_PIECES'],
  'arret': ['IMMOBILISE', 'ACCIDENTE', 'HORS_SERVICE'],
};

class VehiculesScreen extends StatefulWidget {
  const VehiculesScreen({super.key});

  @override
  State<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends State<VehiculesScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _vehicules = [];
  bool _loading = true;
  Object? _error;
  String _recherche = '';
  String? _groupe;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _error = null);
    try {
      final res = await _api.get('/vehicules', params: {'limit': '200'});
      if (!mounted) return;
      setState(() {
        _vehicules = (res.data['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e;
          _loading = false;
        });
    }
  }

  int _nb(String g) => _vehicules.where((v) => _groupes[g]!.contains(v['statut'])).length;

  List<Map<String, dynamic>> get _filtres {
    final q = _recherche.trim().toLowerCase();
    return _vehicules.where((v) {
      if (_groupe != null && !_groupes[_groupe]!.contains(v['statut'])) return false;
      if (q.isEmpty) return true;
      return [
        v['immatriculation'],
        v['numeroInterne'],
        v['marque'],
        v['modele'],
      ].any((x) => (x ?? '').toString().toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?['role'] as String?;
    final liste = _filtres;

    return Scaffold(
      floatingActionButton: autorise(role, 'vehicule.creer')
          ? FloatingActionButton.extended(
              heroTag: 'fab_vehicules',
              onPressed: () => _ouvrir(const VehiculeFormScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Véhicule', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          EnTeteOnglet(
            titre: 'Véhicules',
            sousTitre: _loading
                ? 'Chargement…'
                : '${_vehicules.length} véhicule${_vehicules.length > 1 ? 's' : ''} dans le parc',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ChampRecherche(
              indice: 'Immatriculation, marque, n° interne…',
              onChanged: (t) => setState(() => _recherche = t),
            ),
          ),
          BarreFiltres(
            actif: _groupe,
            onChanged: (g) => setState(() => _groupe = g),
            filtres: [
              Filtre(null, 'Tous', _vehicules.length),
              Filtre('ok', 'En service', _nb('ok')),
              Filtre('atelier', 'À l’atelier', _nb('atelier')),
              Filtre('arret', 'À l’arrêt', _nb('arret')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const ChargementListe()
                : _error != null
                ? ErrorView(error: _error!, onRetry: _charger)
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: liste.isEmpty
                        ? ListeVide(
                            child: _vehicules.isEmpty
                                ? EtatVide(
                                    icone: Icons.directions_car_rounded,
                                    titre: 'Aucun véhicule',
                                    message: 'Les véhicules du parc apparaîtront ici.',
                                    action: autorise(role, 'vehicule.creer') ? 'Ajouter un véhicule' : null,
                                    onAction: () => _ouvrir(const VehiculeFormScreen()),
                                  )
                                : const EtatVide(
                                    icone: Icons.search_off_rounded,
                                    titre: 'Aucun résultat',
                                    message: 'Essayez une autre recherche ou un autre filtre.',
                                  ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: liste.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _carte(liste[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _carte(Map<String, dynamic> v) {
    final type = vehiculeType(v['typeVehicule'] as String?);
    final heures = compteHeures(v['typeVehicule'] as String?);
    final compteur = heures ? '${nombre(v['heuresMoteur'])} h' : '${nombre(v['kilometrage'])} km';
    final photo = AppConstants.urlFichier(v['photoUrl'] as String?);

    return Carte(
      onTap: () => _ouvrir(VehiculeDetailScreen(vehicule: v)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 56,
              child: photo.isEmpty
                  ? IconeTon(type.icone ?? Icons.directions_car_rounded, taille: 56)
                  : CachedNetworkImage(
                      imageUrl: photo,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => IconeTon(type.icone ?? Icons.directions_car_rounded, taille: 56),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v['immatriculation'] ?? '—',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Pastille(vehiculeStatut(v['statut'] as String?)),
                    const Spacer(),
                    Icon(
                      heures ? Icons.schedule_rounded : Icons.speed_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      compteur,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
