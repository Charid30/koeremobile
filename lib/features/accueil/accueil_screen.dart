import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/libelles.dart';
import '../../core/constants/permissions.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_provider.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ui.dart';
import '../di/di_create_screen.dart';
import '../di/di_detail_screen.dart';
import '../inspections/inspection_create_screen.dart';
import '../profile/profile_screen.dart';
import '../releves/releve_km_screen.dart';

/// Écran d'accueil : la situation du jour et les gestes les plus fréquents.
class AccueilScreen extends StatefulWidget {
  /// Ouvre un autre onglet (1 véhicules, 2 signalements, 3 entretien, 4 inspections)
  final ValueChanged<int> ouvrirOnglet;
  const AccueilScreen({super.key, required this.ouvrirOnglet});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _tableau;
  List<dynamic> _signalements = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final r = await Future.wait([
        _api.get('/dashboard'),
        _api.get('/demandes-intervention', params: {'limit': '4'}),
      ]);
      if (!mounted) return;
      setState(() {
        _tableau = r[0].data as Map<String, dynamic>?;
        _signalements = (r[1].data['data'] as List?) ?? [];
        _chargement = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};
    final r = user['role'] as String?;
    final t = _tableau;
    final v = t?['vehicules'] as Map<String, dynamic>?;
    final di = t?['demandesIntervention'] as Map<String, dynamic>?;
    final ot = t?['ordresTravail'] as Map<String, dynamic>?;
    final dispo = (t?['kpis']?['tauxDisponibilite'] as num?)?.round();
    final maintenances = (t?['prochainesMaintenances'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _charger,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _entete(user, dispo, v)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                // ── Actions rapides ──
                const TitreSection('Actions rapides'),
                RangeeEgale(
                  enfants: [
                    if (autorise(r, 'di.creer'))
                      ActionRapide(
                        icone: Icons.report_problem_rounded,
                        libelle: 'Signaler\nune panne',
                        ton: Ton.danger,
                        onTap: () => _ouvrir(const DiCreateScreen()),
                      ),
                    ActionRapide(
                      icone: Icons.speed_rounded,
                      libelle: 'Relever\nle compteur',
                      ton: Ton.info,
                      onTap: () => _ouvrir(const ReleveKmScreen()),
                    ),
                    if (autorise(r, 'inspection.creer'))
                      ActionRapide(
                        icone: Icons.fact_check_rounded,
                        libelle: 'Faire une\ninspection',
                        ton: Ton.succes,
                        onTap: () => _ouvrir(const InspectionCreateScreen()),
                      ),
                  ],
                ),

                // ── Chiffres du jour ──
                TitreSection('Aujourd’hui', action: 'Véhicules', onAction: () => widget.ouvrirOnglet(1)),
                if (_chargement && t == null)
                  const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      TuileChiffre(
                        valeur: '${di?['enAttente'] ?? 0}',
                        libelle: 'Signalements\nen attente',
                        icone: Icons.campaign_rounded,
                        ton: (di?['enAttente'] ?? 0) > 0 ? Ton.attention : Ton.succes,
                        onTap: () => widget.ouvrirOnglet(2),
                      ),
                      TuileChiffre(
                        valeur: '${ot?['enCours'] ?? 0}',
                        libelle: 'Réparations\nen cours',
                        icone: Icons.build_rounded,
                        ton: Ton.marque,
                      ),
                      TuileChiffre(
                        valeur: '${v?['immobilises'] ?? 0}',
                        libelle: 'Véhicules\nimmobilisés',
                        icone: Icons.block_rounded,
                        ton: (v?['immobilises'] ?? 0) > 0 ? Ton.danger : Ton.succes,
                        onTap: () => widget.ouvrirOnglet(1),
                      ),
                      TuileChiffre(
                        valeur: '${maintenances.length}',
                        libelle: 'Entretiens\nà prévoir',
                        icone: Icons.event_repeat_rounded,
                        ton: Ton.info,
                        onTap: () => widget.ouvrirOnglet(3),
                      ),
                    ],
                  ),

                // ── Signalements récents ──
                if (_signalements.isNotEmpty) ...[
                  TitreSection('Derniers signalements', action: 'Tout voir', onAction: () => widget.ouvrirOnglet(2)),
                  for (final s in _signalements) ...[
                    _ligneSignalement(s as Map<String, dynamic>),
                    const SizedBox(height: 8),
                  ],
                ],

                // ── Entretiens à venir ──
                if (maintenances.isNotEmpty) ...[
                  TitreSection('Entretiens à venir', action: 'Tout voir', onAction: () => widget.ouvrirOnglet(3)),
                  Carte(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < maintenances.length && i < 4; i++) ...[
                          _ligneMaintenance(maintenances[i] as Map<String, dynamic>),
                          if (i < maintenances.length - 1 && i < 3) const Divider(height: 1, indent: 64),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entete(Map<String, dynamic> user, int? dispo, Map<String, dynamic>? v) {
    final haut = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, haut + 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brand, Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Image.asset('assets/images/logo.png', width: 26, height: 26),
              ),
              const SizedBox(width: 10),
              const Text(
                'SOFARY',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Avatar(prenom: user['prenom'], nom: user['nom'], taille: 38, clair: true),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '${salutation()}, ${user['prenom'] ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 2),
          Text(
            role(user['role'] as String?),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          // Disponibilité de la flotte
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponibilité de la flotte',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dispo != null ? '$dispo %' : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (dispo ?? 0) / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFC4B5FD)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _chiffreEntete('${v?['disponibles'] ?? '—'}', 'disponibles'),
                    const SizedBox(height: 6),
                    _chiffreEntete('${v?['total'] ?? '—'}', 'au total'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chiffreEntete(String n, String l) => RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: n,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        TextSpan(
          text: '  $l',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    ),
  );

  Widget _ligneSignalement(Map<String, dynamic> d) {
    final p = priorite(d['priorite'] as String?);
    final (_, couleur) = couleursTon(p.ton);
    return Carte(
      bordureGauche: couleur,
      onTap: () => _ouvrir(DiDetailScreen(di: d)),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['vehicule']?['immatriculation'] ?? 'Véhicule',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  d['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pastille(diStatut(d['statut'] as String?)),
              const SizedBox(height: 4),
              Text(
                ilYA(d['dateSignalement'] ?? d['createdAt']),
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneMaintenance(Map<String, dynamic> m) {
    final date = lireDate(m['prochaineExecutionDate']);
    final jours = date?.difference(DateTime.now()).inDays;
    final ton = jours == null
        ? Ton.neutre
        : jours < 0
        ? Ton.danger
        : jours <= 15
        ? Ton.attention
        : Ton.succes;
    final echeance = jours == null
        ? (m['prochaineExecutionKm'] != null ? 'à ${nombre(m['prochaineExecutionKm'])} km' : '—')
        : jours < 0
        ? 'en retard de ${-jours} j'
        : jours == 0
        ? "aujourd'hui"
        : 'dans $jours j';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconeTon(Icons.event_repeat_rounded, ton: ton, taille: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['typeOperation'] ?? 'Entretien',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  m['vehicule'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            echeance,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: couleursTon(ton).$2),
          ),
        ],
      ),
    );
  }
}
