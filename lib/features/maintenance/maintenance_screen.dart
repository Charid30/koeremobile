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
import 'maintenance_create_screen.dart';
import 'maintenance_detail_screen.dart';

/// Entretiens préventifs : plans au compteur (périodiques) et au calendrier (généraux).
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _periodiques = [];
  List<Map<String, dynamic>> _generales = [];
  bool _loading = true;
  Object? _error;
  bool _calendrier = false; // false = au compteur, true = au calendrier

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _error = null);
    try {
      final r = await Future.wait([
        _api.get('/maintenance-preventive/periodique'),
        _api.get('/maintenance-preventive/generale'),
      ]);
      if (!mounted) return;
      List<Map<String, dynamic>> lire(dynamic d) => d is List ? d.cast<Map<String, dynamic>>() : [];
      setState(() {
        _periodiques = lire(r[0].data)..sort((a, b) => _avancement(b).compareTo(_avancement(a)));
        _generales = lire(r[1].data)..sort((a, b) => _jours(a).compareTo(_jours(b)));
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

  /// Part du chemin parcouru vers la prochaine échéance (0 → 1+), au km ou à l'heure moteur.
  double _avancement(Map<String, dynamic> p) {
    final heures = compteHeures(p['vehicule']?['typeVehicule'] as String?) && p['frequenceHeures'] != null;
    final v = (p['vehicule'] as Map<String, dynamic>?) ?? const {};
    final actuel = (v[heures ? 'heuresMoteur' : 'kilometrage'] as num?)?.toDouble() ?? 0;
    final depart = ((heures ? p['derniereExecutionHeures'] : p['derniereExecutionKm']) as num?)?.toDouble() ?? 0;
    final pas = ((heures ? p['frequenceHeures'] : p['frequenceKm']) as num?)?.toDouble() ?? 0;
    if (pas <= 0) return 0;
    return ((actuel - depart) / pas).clamp(0, 2);
  }

  int _jours(Map<String, dynamic> p) =>
      lireDate(p['prochaineExecutionDate'])?.difference(DateTime.now()).inDays ?? 9999;

  Future<void> _ouvrir(Widget ecran) async {
    final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
    if (ok == true || ok == null) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?['role'] as String?;
    final enRetard =
        _periodiques.where((p) => _avancement(p) >= 1).length + _generales.where((p) => _jours(p) < 0).length;
    final liste = _calendrier ? _generales : _periodiques;

    return Scaffold(
      floatingActionButton: autorise(role, 'maintenance.creer')
          ? FloatingActionButton.extended(
              heroTag: 'fab_maintenance',
              onPressed: () => _ouvrir(const MaintenanceCreateScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Plan', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          EnTeteOnglet(
            titre: 'Entretien',
            sousTitre: _loading
                ? 'Chargement…'
                : enRetard > 0
                ? '$enRetard entretien${enRetard > 1 ? 's' : ''} à faire maintenant'
                : 'Tous les entretiens sont à jour',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.speed_rounded, size: 18),
                  label: Text('Au compteur (${_periodiques.length})'),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text('Au calendrier (${_generales.length})'),
                ),
              ],
              selected: {_calendrier},
              onSelectionChanged: (s) => setState(() => _calendrier = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? AppTheme.brand : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? Colors.white : AppTheme.textPrimary,
                ),
                side: const WidgetStatePropertyAll(BorderSide(color: AppTheme.border)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const ChargementListe()
                : _error != null
                ? ErrorView(error: _error!, onRetry: _charger)
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: liste.isEmpty
                        ? ListeVide(
                            child: EtatVide(
                              icone: Icons.event_repeat_rounded,
                              titre: _calendrier ? 'Aucun entretien au calendrier' : 'Aucun entretien au compteur',
                              message: _calendrier
                                  ? 'Ex. : visite technique tous les 6 mois.'
                                  : 'Ex. : vidange tous les 10 000 km.',
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: liste.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _calendrier ? _carteCalendrier(liste[i]) : _carteCompteur(liste[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _enTeteCarte(Map<String, dynamic> p, Libelle? alerte) {
    final v = p['vehicule'] as Map<String, dynamic>?;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p['typeOperation'] ?? 'Entretien',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                '${v?['immatriculation'] ?? '—'} · ${v?['marque'] ?? ''} ${v?['modele'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        if (alerte != null) ...[const SizedBox(width: 8), Pastille(alerte, icone: true)],
      ],
    );
  }

  Widget _carteCompteur(Map<String, dynamic> p) {
    final a = _avancement(p);
    final ton = a >= 1
        ? Ton.danger
        : a >= 0.8
        ? Ton.attention
        : Ton.succes;
    final couleur = couleursTon(ton).$2;
    final heures = compteHeures(p['vehicule']?['typeVehicule'] as String?) && p['frequenceHeures'] != null;
    final unite = heures ? 'h' : 'km';
    final prochain = heures ? p['prochaineExecutionHeures'] : p['prochaineExecutionKm'];
    final v = (p['vehicule'] as Map<String, dynamic>?) ?? const {};
    final actuel = v[heures ? 'heuresMoteur' : 'kilometrage'];
    final pas = heures ? p['frequenceHeures'] : p['frequenceKm'];

    return Carte(
      onTap: () => _ouvrir(MaintenanceDetailScreen(plan: p)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _enTeteCarte(
            p,
            a >= 1
                ? const Libelle('À faire', Ton.danger, Icons.warning_amber_rounded)
                : a >= 0.8
                ? const Libelle('Bientôt', Ton.attention, Icons.schedule_rounded)
                : null,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: a.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: const Color(0xFFEFEDF4),
              valueColor: AlwaysStoppedAnimation(couleur),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${nombre(actuel ?? 0)} $unite',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Text(
                pas != null ? '  ·  tous les ${nombre(pas)} $unite' : '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Text(
                prochain != null ? 'prochain à ${nombre(prochain)} $unite' : '${(a * 100).round()} %',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleur),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _carteCalendrier(Map<String, dynamic> p) {
    final j = _jours(p);
    final ton = j < 0
        ? Ton.danger
        : j <= 15
        ? Ton.attention
        : Ton.succes;
    final couleur = couleursTon(ton).$2;
    final date = p['prochaineExecutionDate'];
    final texte = j == 9999
        ? 'Pas de date prévue'
        : j < 0
        ? 'En retard de ${-j} jour${-j > 1 ? 's' : ''}'
        : j == 0
        ? "Aujourd'hui"
        : 'Dans $j jour${j > 1 ? 's' : ''}';

    return Carte(
      onTap: () => _ouvrir(MaintenanceDetailScreen(plan: p)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _enTeteCarte(
            p,
            j < 0
                ? const Libelle('En retard', Ton.danger, Icons.warning_amber_rounded)
                : j <= 15
                ? const Libelle('Bientôt', Ton.attention, Icons.schedule_rounded)
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconeTon(j < 0 ? Icons.event_busy_rounded : Icons.event_rounded, ton: ton, taille: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texte,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: couleur),
                    ),
                    Text(
                      '${date != null ? 'Le ${dateCourte(date)}' : ''}${p['frequenceMois'] != null ? ' · tous les ${p['frequenceMois']} mois' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
