import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/libelles.dart';
import '../../core/constants/permissions.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';
import 'inspection_create_screen.dart';
import 'inspection_detail_screen.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  Object? _error;
  String? _statut;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _error = null);
    try {
      final res = await _api.get('/inspections', params: {'limit': '100'});
      if (!mounted) return;
      setState(() {
        _list = (res.data['data'] as List).cast<Map<String, dynamic>>();
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

  int _nb(String s) => _list.where((i) => i['statut'] == s).length;

  List<Map<String, dynamic>> get _filtres {
    final q = _recherche.trim().toLowerCase();
    return _list.where((i) {
      if (_statut != null && i['statut'] != _statut) return false;
      if (q.isEmpty) return true;
      return [
        i['vehicule']?['immatriculation'],
        i['vehicule']?['marque'],
        i['inspecteur']?['nom'],
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
      floatingActionButton: autorise(role, 'inspection.creer')
          ? FloatingActionButton.extended(
              heroTag: 'fab_inspections',
              onPressed: () => _ouvrir(const InspectionCreateScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Inspection', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          EnTeteOnglet(
            titre: 'Inspections',
            sousTitre: _loading
                ? 'Chargement…'
                : '${_list.length} inspection${_list.length > 1 ? 's' : ''} récente${_list.length > 1 ? 's' : ''}',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ChampRecherche(indice: 'Véhicule, inspecteur…', onChanged: (t) => setState(() => _recherche = t)),
          ),
          BarreFiltres(
            actif: _statut,
            onChanged: (s) => setState(() => _statut = s),
            filtres: [
              Filtre(null, 'Toutes', _list.length),
              for (final e in inspectionStatuts.entries) Filtre(e.key, e.value.texte, _nb(e.key)),
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
                            child: _list.isEmpty
                                ? EtatVide(
                                    icone: Icons.fact_check_rounded,
                                    titre: 'Aucune inspection',
                                    message: 'Contrôlez un véhicule avant un départ ou au retour de mission.',
                                    action: autorise(role, 'inspection.creer') ? 'Faire une inspection' : null,
                                    onAction: () => _ouvrir(const InspectionCreateScreen()),
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

  Widget _carte(Map<String, dynamic> ins) {
    final s = inspectionStatut(ins['statut'] as String?);
    final note = (ins['noteGlobale'] as num?)?.toDouble();
    final inspecteur = ins['inspecteur'] as Map<String, dynamic>?;

    return Carte(
      onTap: () => _ouvrir(InspectionDetailScreen(inspectionId: ins['id'] as int)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _note(note, s.ton),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ins['vehicule']?['immatriculation'] ?? '—',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${inspectionType(ins['typeInspection'] as String?)} · ${dateCourte(ins['dateInspection'])}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
                if (inspecteur != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Par ${inspecteur['prenom'] ?? ''} ${inspecteur['nom'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pastille(s),
        ],
      ),
    );
  }

  /// Note sur 20 dans un cercle coloré (ou icône si pas de note)
  Widget _note(double? note, Ton ton) {
    final (fond, texte) = couleursTon(ton);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: note == null
          ? Icon(Icons.fact_check_rounded, color: texte, size: 24)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note % 1 == 0 ? note.toInt().toString() : note.toStringAsFixed(1),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: texte, height: 1),
                ),
                Text(
                  '/20',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: texte.withValues(alpha: 0.75)),
                ),
              ],
            ),
    );
  }
}
