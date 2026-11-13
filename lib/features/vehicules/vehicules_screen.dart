import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'vehicule_detail_screen.dart';
import 'vehicule_form_screen.dart';

class VehiculesScreen extends StatefulWidget {
  const VehiculesScreen({super.key});

  @override
  State<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends State<VehiculesScreen> {
  final _api = ApiService();
  List<dynamic> _vehicules = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/vehicules', params: {'limit': '200'});
      setState(() { _vehicules = res.data['data'] as List; _loading = false; });
    } catch (e) {
      setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiculeFormScreen()))
            .then((ok) { if (ok == true) _charger(); }),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error!, onRetry: _charger)
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: _vehicules.isEmpty
                      ? const _EmptyView(
                          icon: Icons.directions_car_outlined,
                          message: 'Aucun véhicule enregistré.\nAppuyez sur + pour en ajouter un.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vehicules.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final v = _vehicules[i] as Map<String, dynamic>;
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => VehiculeDetailScreen(vehicule: v)),
                                ).then((_) => _charger()),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(v['immatriculation'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text('${v['marque']} ${v['modele']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text('${(v['kilometrage'] as num?)?.toStringAsFixed(0) ?? '-'} km', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    ])),
                                    _statutBadge(v['statut'] as String? ?? ''),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _statutBadge(String statut) {
    final (bg, fg, label) = switch (statut) {
      'DISPONIBLE'                    => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Disponible'),
      'EN_CIRCULATION'                => (const Color(0xFFEFF6FF), AppTheme.primary, 'En circulation'),
      'EN_MAINTENANCE'                => (const Color(0xFFFFF7ED), AppTheme.warning, 'Maintenance'),
      'EN_ATTENTE_REPARATION_EXTERNE' => (const Color(0xFFFFF7ED), AppTheme.warning, 'Att. réparation'),
      'EN_ATTENTE_PIECES'             => (const Color(0xFFFFF7ED), AppTheme.warning, 'Att. pièces'),
      'IMMOBILISE'                    => (const Color(0xFFFEF2F2), AppTheme.danger, 'Immobilisé'),
      'ACCIDENTE'                     => (const Color(0xFFFEF2F2), AppTheme.danger, 'Accidenté'),
      'HORS_SERVICE'                  => (const Color(0xFFF3F4F6), AppTheme.textSecondary, 'Hors service'),
      _                               => (const Color(0xFFF3F4F6), AppTheme.textSecondary, statut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => ListView(children: [
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: AppTheme.border),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6), textAlign: TextAlign.center),
      ]),
    ),
  ]);
}
