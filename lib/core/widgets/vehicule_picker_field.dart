import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class VehiculePickerField extends StatefulWidget {
  final List<dynamic> vehicules;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final String? errorText;

  const VehiculePickerField({
    super.key,
    required this.vehicules,
    required this.onSelected,
    this.selected,
    this.errorText,
  });

  @override
  State<VehiculePickerField> createState() => _VehiculePickerFieldState();
}

class _VehiculePickerFieldState extends State<VehiculePickerField> {
  void _ouvrir() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _VehiculePickerSheet(
        vehicules: widget.vehicules,
        onSelected: (v) {
          Navigator.pop(context);
          widget.onSelected(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.selected;
    final hasError = widget.errorText != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: _ouvrir,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasError ? AppTheme.danger : AppTheme.border),
          ),
          child: Row(children: [
            Icon(Icons.directions_car_outlined, size: 18,
                color: v != null ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: v != null
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v['immatriculation'] as String? ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Text('${v['marque']} ${v['modele']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ])
                  : const Text('Rechercher un véhicule...',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ),
            Icon(Icons.search, size: 18, color: v != null ? AppTheme.primary : AppTheme.textSecondary),
          ]),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 12, color: AppTheme.danger)),
        ),
    ]);
  }
}

class _VehiculePickerSheet extends StatefulWidget {
  final List<dynamic> vehicules;
  final ValueChanged<Map<String, dynamic>> onSelected;
  const _VehiculePickerSheet({required this.vehicules, required this.onSelected});

  @override
  State<_VehiculePickerSheet> createState() => _VehiculePickerSheetState();
}

class _VehiculePickerSheetState extends State<_VehiculePickerSheet> {
  final _ctrl = TextEditingController();
  List<dynamic> _filtres = [];

  @override
  void initState() {
    super.initState();
    _filtres = widget.vehicules;
    _ctrl.addListener(_filtrer);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _filtrer() {
    final q = _ctrl.text.toLowerCase().trim();
    setState(() {
      _filtres = q.isEmpty
          ? widget.vehicules
          : widget.vehicules.where((v) {
              final m = v as Map<String, dynamic>;
              return (m['immatriculation'] as String? ?? '').toLowerCase().contains(q) ||
                     (m['numeroInterne'] as String? ?? '').toLowerCase().contains(q) ||
                     '${m['marque']} ${m['modele']}'.toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Sélectionner un véhicule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Immatriculation, numéro interne, marque...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
          child: _filtres.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucun véhicule trouvé', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtres.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final v = _filtres[i] as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 18),
                      ),
                      title: Text(v['immatriculation'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${v['marque']} ${v['modele']}  ·  ${v['numeroInterne'] ?? ''}',
                          style: const TextStyle(fontSize: 12)),
                      onTap: () => widget.onSelected(v),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
