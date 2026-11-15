import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../di/di_create_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _confirmerSuppression() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text('Le véhicule ${widget.vehicule['immatriculation']} sera supprimé définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
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

  Object? _loadError;

  Future<void> _charger() async {
    setState(() { _loading = true; _loadError = null; });
    final id = widget.vehicule['id'];
    try {
      final rv = await _api.get('/vehicules/$id');
      final rd = await _api.get('/demandes-intervention', params: {'vehiculeId': '$id', 'limit': '5'});
      setState(() {
        _detail = rv.data as Map<String, dynamic>;
        _dernieresDI = (rd.data['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loadError = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _detail ?? widget.vehicule;
    final statut = v['statut'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(v['immatriculation'] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => VehiculeFormScreen(vehicule: _detail ?? widget.vehicule),
            )).then((ok) { if (ok == true) _charger(); }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            tooltip: 'Supprimer',
            onPressed: _confirmerSuppression,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? ErrorView(error: _loadError!, onRetry: _charger)
              : RefreshIndicator(
              onRefresh: _charger,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── En-tête ─────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${v['marque']} ${v['modele']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text('N° ${v['numeroInterne'] ?? '-'}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ])),
                          _statutBadge(statut),
                        ]),
                      ]),
                    ),

                    // ── Métriques ────────────────────────────────────
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _metrique('${_fmt(v['kilometrage'])} km', 'Kilométrage'),
                          const VerticalDivider(width: 1, color: AppTheme.border),
                          _metrique('${_fmt(v['heuresMoteur'])} h', 'Heures moteur'),
                          const VerticalDivider(width: 1, color: AppTheme.border),
                          _metrique('${v['anneeAcquisition'] ?? '-'}', 'Année acq.'),
                        ]),
                      ),
                    ),

                    // ── Actions rapides ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.build_circle_outlined,
                            label: 'Créer une DI',
                            color: AppTheme.primary,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DiCreateScreen(vehiculePreselectionne: v),
                              ));
                              _charger();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.speed_outlined,
                            label: 'Saisir km',
                            color: AppTheme.success,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ReleveKmScreen(vehicule: v),
                              ));
                              _charger();
                            },
                          ),
                        ),
                      ]),
                    ),

                    // ── Informations ─────────────────────────────────
                    _section('Identification', [
                      _ligne('Immatriculation', v['immatriculation']),
                      _ligne('N° interne', v['numeroInterne']),
                      _ligne('N° série / VIN', v['numeroSerie']),
                      _ligne('Type', v['typeVehicule']),
                      _ligne('Carburant', v['typeCarburant']),
                    ]),

                    _section('Caractéristiques', [
                      _ligne('Marque', v['marque']),
                      _ligne('Modèle', v['modele']),
                      _ligne('Puissance', v['puissance'] != null ? '${v['puissance']} cv' : null),
                      _ligne('Places', v['nombrePlaces']?.toString()),
                      _ligne('Charge utile', v['chargeUtile'] != null ? '${v['chargeUtile']} kg' : null),
                    ]),

                    _section('Affectation', [
                      _ligne('Structure', v['entite']?.toString()),
                      _ligne('Direction', v['departement']?.toString()),
                      _ligne('Site', v['siteGeographique']?.toString()),
                      _ligne('Chauffeur', v['conducteurHabituel'] != null
                          ? '${_nested(v, 'conducteurHabituel', 'prenom')} ${_nested(v, 'conducteurHabituel', 'nom')}'
                          : null),
                      _ligne('Mise en service', _formatDate(v['dateMiseEnService'])),
                      _ligne('Acquisition', _formatDate(v['dateAcquisition'])),
                    ]),

                    // ── Dernières DI ─────────────────────────────────
                    if (_dernieresDI.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Dernières interventions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, letterSpacing: 0.5)),
                      ),
                      ..._dernieresDI.map((d) {
                        final di = d as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(di['description'] ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            _statutBadgeDI(di['statut'] as String? ?? ''),
                          ]),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metrique(String valeur, String label) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Text(valeur, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    ),
  );

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) =>
    Material(
      color: color.withValues(alpha:0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );

  Widget _section(String titre, List<Widget> lignes) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Text(titre.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1)),
      ),
      const Divider(height: 1, color: AppTheme.border),
      ...lignes,
    ]),
  );

  Widget _ligne(String label, String? valeur) {
    if (valeur == null || valeur.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(valeur, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ]),
    );
  }

  Widget _statutBadge(String statut) {
    final (bg, fg, label) = switch (statut) {
      'DISPONIBLE'                    => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Disponible'),
      'EN_CIRCULATION'                => (AppTheme.primaryLight, AppTheme.primary, 'En circulation'),
      'EN_MAINTENANCE'                => (const Color(0xFFFFF7ED), AppTheme.warning, 'En maintenance'),
      'EN_ATTENTE_REPARATION_EXTERNE' => (const Color(0xFFFFF7ED), AppTheme.warning, 'Att. réparation ext.'),
      'EN_ATTENTE_PIECES'             => (const Color(0xFFFFF7ED), AppTheme.warning, 'Att. pièces'),
      'IMMOBILISE'                    => (const Color(0xFFFEF2F2), AppTheme.danger, 'Immobilisé'),
      'ACCIDENTE'                     => (const Color(0xFFFEF2F2), AppTheme.danger, 'Accidenté'),
      'HORS_SERVICE'                  => (const Color(0xFFF3F4F6), AppTheme.textSecondary, 'Hors service'),
      _                               => (const Color(0xFFF3F4F6), AppTheme.textSecondary, statut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _statutBadgeDI(String statut) {
    final (bg, fg, label) = switch (statut) {
      'EN_ATTENTE' => (const Color(0xFFFFF7ED), AppTheme.warning, 'En attente'),
      'EN_COURS'   => (AppTheme.primaryLight, AppTheme.primary, 'En cours'),
      'RESOLUE'    => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Résolue'),
      'REJETEE'    => (const Color(0xFFFEF2F2), AppTheme.danger, 'Rejetée'),
      _            => (const Color(0xFFF3F4F6), AppTheme.textSecondary, statut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  String? _nested(Map<String, dynamic> map, String key, String subKey) {
    final obj = map[key];
    if (obj == null || obj is! Map) return null;
    return (obj as Map<String, dynamic>)[subKey]?.toString();
  }

  String _fmt(dynamic val) {
    if (val == null) return '-';
    final n = num.tryParse(val.toString());
    if (n == null) return '-';
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }

  String? _formatDate(dynamic val) {
    if (val == null) return null;
    try {
      final d = DateTime.parse(val.toString());
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return null; }
  }
}

