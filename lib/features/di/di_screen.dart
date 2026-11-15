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
import 'di_create_screen.dart';
import 'di_detail_screen.dart';

/// Signalements de panne (demandes d'intervention).
class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
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
      final res = await _api.get('/demandes-intervention', params: {'limit': '100'});
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

  int _nb(String s) => _list.where((d) => d['statut'] == s).length;

  List<Map<String, dynamic>> get _filtres {
    final q = _recherche.trim().toLowerCase();
    return _list.where((d) {
      if (_statut != null && d['statut'] != _statut) return false;
      if (q.isEmpty) return true;
      return [
        d['numeroDI'],
        d['description'],
        d['localisation'],
        d['vehicule']?['immatriculation'],
        d['vehicule']?['marque'],
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
    final enAttente = _nb('EN_ATTENTE');

    return Scaffold(
      floatingActionButton: autorise(role, 'di.creer')
          ? FloatingActionButton.extended(
              heroTag: 'fab_di',
              onPressed: () => _ouvrir(const DiCreateScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Signaler', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          EnTeteOnglet(
            titre: 'Signalements',
            sousTitre: _loading
                ? 'Chargement…'
                : enAttente > 0
                ? '$enAttente en attente de prise en charge'
                : 'Aucun signalement en attente',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ChampRecherche(
              indice: 'Véhicule, description, lieu…',
              onChanged: (t) => setState(() => _recherche = t),
            ),
          ),
          BarreFiltres(
            actif: _statut,
            onChanged: (s) => setState(() => _statut = s),
            filtres: [
              Filtre(null, 'Tous', _list.length),
              for (final e in diStatuts.entries) Filtre(e.key, e.value.texte, _nb(e.key)),
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
                                    icone: Icons.campaign_rounded,
                                    titre: 'Aucun signalement',
                                    message:
                                        'Une panne, un bruit, un voyant allumé ?\nSignalez-le en quelques secondes.',
                                    action: autorise(role, 'di.creer') ? 'Signaler une panne' : null,
                                    onAction: () => _ouvrir(const DiCreateScreen()),
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

  Widget _carte(Map<String, dynamic> d) {
    final p = priorite(d['priorite'] as String?);
    final (_, couleurPrio) = couleursTon(p.ton);
    final v = d['vehicule'] as Map<String, dynamic>?;
    final declarant = d['declarant'] as Map<String, dynamic>?;

    return Carte(
      bordureGauche: couleurPrio,
      onTap: () => _ouvrir(DiDetailScreen(di: d)),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  v?['immatriculation'] ?? 'Véhicule inconnu',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
              Pastille(diStatut(d['statut'] as String?)),
            ],
          ),
          if (v != null)
            Text(
              '${v['marque'] ?? ''} ${v['modele'] ?? ''}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          const SizedBox(height: 8),
          Text(
            d['description'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(p.icone, size: 15, color: couleurPrio),
              const SizedBox(width: 2),
              Text(
                p.texte,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleurPrio),
              ),
              const SizedBox(width: 12),
              if (declarant != null) ...[
                const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${declarant['prenom'] ?? ''} ${declarant['nom'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(width: 8),
              Text(
                ilYA(d['dateSignalement'] ?? d['createdAt']),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
