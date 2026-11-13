import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'maintenance_create_screen.dart';
import 'maintenance_detail_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final TabController _tabs;
  List<dynamic> _periodiques = [];
  List<dynamic> _generales = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rp = await _api.get('/maintenance-preventive/periodique');
      final rg = await _api.get('/maintenance-preventive/generale');
      setState(() {
        _periodiques = rp.data is List ? rp.data as List : [];
        _generales   = rg.data is List ? rg.data as List : [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e; _loading = false; });
    }
  }

  int _progressKm(Map<String, dynamic> p) {
    final km     = (p['vehicule']?['kilometrage'] as num?)?.toInt() ?? 0;
    final depart = (p['derniereExecutionKm'] as num?)?.toInt() ?? 0;
    final seuil  = (p['frequenceKm'] as num?)?.toInt() ?? 10000;
    if (seuil <= 0) return 0;
    return (((km - depart).clamp(0, seuil) / seuil) * 100).round();
  }

  int _joursRestants(Map<String, dynamic> p) {
    final dateStr = p['prochaineExecutionDate'] as String?;
    if (dateStr == null) return 999;
    return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'Périodique (${_periodiques.length})'),
            Tab(text: 'Générale (${_generales.length})'),
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorView(error: _error!, onRetry: _charger)
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: TabBarView(
                      controller: _tabs,
                      children: [_buildPeriodique(), _buildGenerale()],
                    ),
                  ),
      ),
      ]),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'fab_maintenance',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceCreateScreen()))
              .then((ok) { if (ok == true) _charger(); }),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    ]);
  }

  Widget _buildPeriodique() {
    if (_periodiques.isEmpty) return _emptyView('Aucun plan de maintenance périodique');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _periodiques.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p    = _periodiques[i] as Map<String, dynamic>;
        final pct  = _progressKm(p);
        final (barColor, statut) = pct >= 100
            ? (AppTheme.danger, 'alerte')
            : pct >= 80
                ? (AppTheme.warning, 'proche')
                : (AppTheme.success, 'ok');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(plan: p)))
                .then((ok) { if (ok == true) _charger(); }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(p['vehicule']?['immatriculation'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  if (statut == 'alerte')
                    _badge('MAINTENANCE REQUISE', AppTheme.danger, const Color(0xFFFEF2F2))
                  else if (statut == 'proche')
                    _badge('BIENTÔT', AppTheme.warning, const Color(0xFFFFF7ED)),
                ]),
                const SizedBox(height: 2),
                Text('${p['vehicule']?['marque']} ${p['vehicule']?['modele']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${p['vehicule']?['kilometrage'] ?? '-'} km actuels', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: barColor)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerale() {
    if (_generales.isEmpty) return _emptyView('Aucun plan de maintenance générale');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _generales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p    = _generales[i] as Map<String, dynamic>;
        final j    = _joursRestants(p);
        final (barColor, statut) = j <= 0
            ? (AppTheme.danger, 'alerte')
            : j <= 15
                ? (AppTheme.warning, 'proche')
                : (AppTheme.success, 'ok');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(plan: p)))
                .then((ok) { if (ok == true) _charger(); }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p['vehicule']?['immatriculation'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                if (statut == 'alerte')
                  _badge('DÉPASSÉ', AppTheme.danger, const Color(0xFFFEF2F2))
                else if (statut == 'proche')
                  _badge('BIENTÔT', AppTheme.warning, const Color(0xFFFFF7ED)),
              ]),
              const SizedBox(height: 2),
              Text(
                '${p['vehicule']?['marque']} ${p['vehicule']?['modele']} · tous les ${p['frequenceMois']} mois',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(j <= 0 ? Icons.warning_amber_rounded : Icons.schedule_rounded, size: 15, color: barColor),
                const SizedBox(width: 6),
                Text(
                  j <= 0 ? 'Dépassé de ${j.abs()} jour${j.abs() > 1 ? 's' : ''}' : '$j jour${j > 1 ? 's' : ''} restant${j > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: barColor),
                ),
              ]),
            ]),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );

  Widget _emptyView(String msg) => ListView(children: [
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.engineering_outlined, size: 56, color: AppTheme.border),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ]),
    ),
  ]);
}
