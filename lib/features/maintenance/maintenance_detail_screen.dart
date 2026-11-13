import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const MaintenanceDetailScreen({super.key, required this.plan});

  @override
  State<MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  final _api = ApiService();
  bool _submitting = false;
  late Map<String, dynamic> _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  bool get _isPeriodique => _plan['typePlan'] == 'PERIODIQUE';

  int get _progressKm {
    final km     = (_plan['vehicule']?['kilometrage'] as num?)?.toInt() ?? 0;
    final depart = (_plan['derniereExecutionKm'] as num?)?.toInt() ?? 0;
    final seuil  = (_plan['frequenceKm'] as num?)?.toInt() ?? 10000;
    if (seuil <= 0) return 0;
    return (((km - depart).clamp(0, seuil) / seuil) * 100).round();
  }

  int get _joursRestants {
    final dateStr = _plan['prochaineExecutionDate'] as String?;
    if (dateStr == null) return 999;
    return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  Future<void> _marquerEffectuee() async {
    final v = _plan['vehicule'] as Map<String, dynamic>?;
    final kmActuel = (v?['kilometrage'] as num?)?.toInt();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer l\'exécution'),
        content: Text(
          _isPeriodique
              ? 'Marquer cette maintenance comme effectuée ?\nKm actuel : ${kmActuel ?? '-'}'
              : 'Marquer cette maintenance comme effectuée aujourd\'hui ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final body = _isPeriodique && kmActuel != null ? {'kilometrage': kmActuel} : <String, dynamic>{};
      await _api.patch('/maintenance-preventive/${_plan['id']}/execution', data: body);
      if (mounted) {
        showSuccessSnack(context, 'Maintenance enregistrée.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _desactiver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver le plan'),
        content: const Text('Ce plan sera désactivé et ne sera plus suivi. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await _api.delete('/maintenance-preventive/${_plan['id']}');
      if (mounted) {
        showSuccessSnack(context, 'Plan désactivé.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _plan['vehicule'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: _submitting ? null : _desactiver,
            tooltip: 'Désactiver',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Véhicule
          _card([
            _row(Icons.directions_car_outlined, 'Véhicule', v?['immatriculation'] ?? '-'),
            _divider(),
            _row(Icons.info_outline, 'Marque / Modèle', '${v?['marque'] ?? ''} ${v?['modele'] ?? ''}'),
            _divider(),
            _row(Icons.speed_outlined, 'Kilométrage actuel', '${(v?['kilometrage'] as num?)?.toStringAsFixed(0) ?? '-'} km'),
          ]),
          const SizedBox(height: 16),

          // Type et statut
          _card([
            _row(Icons.category_outlined, 'Type', _isPeriodique ? 'Périodique (km)' : 'Générale (temps)'),
            _divider(),
            _row(Icons.circle_outlined, 'Statut', _plan['actif'] == true ? 'Actif' : 'Inactif',
                valueColor: _plan['actif'] == true ? AppTheme.success : AppTheme.textSecondary),
          ]),
          const SizedBox(height: 16),

          // Progression
          if (_isPeriodique) ...[
            _progressCard(),
            const SizedBox(height: 16),
          ] else ...[
            _delaiCard(),
            const SizedBox(height: 16),
          ],

          // Historique
          _card([
            if (_isPeriodique) ...[
              _row(Icons.history_outlined, 'Dernier entretien km', '${_plan['derniereExecutionKm'] ?? '-'} km'),
              _divider(),
              _row(Icons.flag_outlined, 'Prochain entretien', '${_plan['prochaineExecutionKm'] ?? '-'} km'),
              _divider(),
              _row(Icons.repeat_outlined, 'Intervalle', '${_plan['frequenceKm'] ?? 10000} km'),
            ] else ...[
              _row(Icons.history_outlined, 'Dernier entretien', _formatDate(_plan['derniereExecutionDate'] as String?)),
              _divider(),
              _row(Icons.flag_outlined, 'Prochain entretien', _formatDate(_plan['prochaineExecutionDate'] as String?)),
              _divider(),
              _row(Icons.repeat_outlined, 'Fréquence', '${_plan['frequenceMois'] ?? '-'} mois'),
            ],
            if (_plan['description'] != null && (_plan['description'] as String).isNotEmpty) ...[
              _divider(),
              _row(Icons.notes_outlined, 'Description', _plan['description'] as String),
            ],
          ]),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _marquerEffectuee,
              icon: _submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Marquer comme effectuée', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final pct = _progressKm;
    final barColor = pct >= 100 ? AppTheme.danger : pct >= 80 ? AppTheme.warning : AppTheme.success;
    final label = pct >= 100 ? 'Maintenance requise' : pct >= 80 ? 'Bientôt' : 'OK';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Progression km', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: barColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: barColor)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_plan['derniereExecutionKm'] ?? 0} km', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: barColor)),
          Text('${_plan['prochaineExecutionKm'] ?? '-'} km', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _delaiCard() {
    final j = _joursRestants;
    final barColor = j <= 0 ? AppTheme.danger : j <= 15 ? AppTheme.warning : AppTheme.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: barColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(j <= 0 ? Icons.warning_amber_rounded : Icons.schedule_rounded, color: barColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            j <= 0 ? 'Dépassé de ${j.abs()} jour${j.abs() > 1 ? 's' : ''}' : '$j jour${j > 1 ? 's' : ''} restant${j > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: barColor),
          ),
          const SizedBox(height: 2),
          Text('Échéance : ${_formatDate(_plan['prochaineExecutionDate'] as String?)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(children: children),
  );

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );

  Widget _divider() => const Divider(height: 1, indent: 46);
}
