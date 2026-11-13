import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _inspection;
  bool _loading = true;
  Object? _error;
  bool _submitting = false;

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/inspections/${widget.inspectionId}');
      setState(() { _inspection = res.data as Map<String, dynamic>; _loading = false; });
    } catch (e) {
      setState(() { _error = e; _loading = false; });
    }
  }

  String _formatDate(dynamic val) {
    if (val == null) return '-';
    try {
      final d = DateTime.parse(val.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return '-'; }
  }

  String _typeLabel(String? t) => switch (t) {
    'PRE_DEPART'      => 'Pré-départ',
    'PERIODIQUE'      => 'Périodique',
    'RETOUR_MISSION'  => 'Retour mission',
    'TECHNIQUE'       => 'Technique',
    _                 => t ?? '-',
  };

  Future<void> _editerNotes() async {
    final ctrl = TextEditingController(text: _inspection?['notes'] as String? ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier les notes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Notes...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _submitting = true);
    try {
      await _api.patch('/inspections/${widget.inspectionId}', data: {'notes': result});
      await _charger();
      if (mounted) showSuccessSnack(context, 'Notes mises à jour.');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _supprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'inspection'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _submitting = true);
    try {
      await _api.delete('/inspections/${widget.inspectionId}');
      if (mounted) {
        showSuccessSnack(context, 'Inspection supprimée.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: ErrorView(error: _error!, onRetry: _charger));

    final ins = _inspection!;
    final v = ins['vehicule'] as Map<String, dynamic>?;
    final conforme = ins['conforme'] as bool? ?? false;
    final items = ins['items'] as List? ?? [];
    final byCategorie = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final m = item as Map<String, dynamic>;
      final cat = m['categorie'] as String? ?? 'Autre';
      byCategorie.putIfAbsent(cat, () => []).add(m);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _submitting ? null : _editerNotes, tooltip: 'Modifier notes'),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger), onPressed: _submitting ? null : _supprimer, tooltip: 'Supprimer'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: conforme ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(conforme ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: conforme ? const Color(0xFF15803D) : AppTheme.danger, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(conforme ? 'Conforme' : 'Non conforme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: conforme ? const Color(0xFF15803D) : AppTheme.danger)),
                if (ins['noteGlobale'] != null)
                  Text('Note : ${ins['noteGlobale']}',
                      style: TextStyle(fontSize: 13, color: conforme ? const Color(0xFF15803D) : AppTheme.danger)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Infos véhicule
          _card([
            _row(Icons.directions_car_outlined, 'Véhicule', v?['immatriculation'] ?? '-'),
            _divider(),
            _row(Icons.info_outline, 'Marque / Modèle', '${v?['marque'] ?? ''} ${v?['modele'] ?? ''}'),
            _divider(),
            _row(Icons.category_outlined, 'Type', _typeLabel(ins['typeInspection'] as String?)),
            _divider(),
            _row(Icons.calendar_today_outlined, 'Date', _formatDate(ins['dateInspection'])),
            if (ins['kilometrageReleve'] != null) ...[
              _divider(),
              _row(Icons.speed_outlined, 'Km relevé', '${ins['kilometrageReleve']} km'),
            ],
            if (ins['inspecteur'] != null) ...[
              _divider(),
              _row(Icons.person_outline, 'Inspecteur',
                  '${ins['inspecteur']?['prenom']} ${ins['inspecteur']?['nom']}'),
            ],
          ]),

          if (ins['notes'] != null && (ins['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            _card([
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.notes_outlined, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(ins['notes'] as String, style: const TextStyle(fontSize: 14, height: 1.5)),
                ]),
              ),
            ]),
          ],

          // Items par catégorie
          if (byCategorie.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Points de contrôle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            for (final entry in byCategorie.entries) ...[
              _categorieCard(entry.key, entry.value),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _categorieCard(String categorie, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(categorie, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        ),
        const Divider(height: 1),
        for (int i = 0; i < items.length; i++) ...[
          _itemRow(items[i]),
          if (i < items.length - 1) const Divider(height: 1, indent: 14),
        ],
      ]),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final resultat = item['resultat'] as String? ?? 'NA';
    final (color, icon, label) = switch (resultat) {
      'OK' => (const Color(0xFF15803D), Icons.check_circle_outline, 'OK'),
      'KO' => (AppTheme.danger, Icons.cancel_outlined, 'KO'),
      _    => (AppTheme.textSecondary, Icons.remove_circle_outline, 'N/A'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['libelle'] as String? ?? '', style: const TextStyle(fontSize: 13)),
          if (item['observation'] != null && (item['observation'] as String).isNotEmpty)
            Text(item['observation'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
        ])),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ]),
    );
  }

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(children: children),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    ]),
  );

  Widget _divider() => const Divider(height: 1, indent: 46);
}
