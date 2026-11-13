import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/vehicule_picker_field.dart';

// Items prédéfinis par catégorie
const _defaultItems = [
  {'categorie': 'Éclairage',    'libelle': 'Phares avant'},
  {'categorie': 'Éclairage',    'libelle': 'Feux arrière'},
  {'categorie': 'Éclairage',    'libelle': 'Clignotants'},
  {'categorie': 'Éclairage',    'libelle': 'Feux de stop'},
  {'categorie': 'Pneumatiques', 'libelle': 'Pneu avant gauche'},
  {'categorie': 'Pneumatiques', 'libelle': 'Pneu avant droit'},
  {'categorie': 'Pneumatiques', 'libelle': 'Pneu arrière gauche'},
  {'categorie': 'Pneumatiques', 'libelle': 'Pneu arrière droit'},
  {'categorie': 'Carrosserie',  'libelle': 'État général carrosserie'},
  {'categorie': 'Carrosserie',  'libelle': 'Pare-brise'},
  {'categorie': 'Carrosserie',  'libelle': 'Rétroviseurs'},
  {'categorie': 'Mécanique',    'libelle': 'Niveau huile moteur'},
  {'categorie': 'Mécanique',    'libelle': 'Niveau liquide refroidissement'},
  {'categorie': 'Mécanique',    'libelle': 'Freins'},
  {'categorie': 'Mécanique',    'libelle': 'Direction'},
  {'categorie': 'Sécurité',     'libelle': 'Ceintures de sécurité'},
  {'categorie': 'Sécurité',     'libelle': 'Extincteur'},
  {'categorie': 'Sécurité',     'libelle': 'Triangle de signalisation'},
];

class _ItemState {
  final String categorie;
  final String libelle;
  String resultat = 'NA';
  String observation = '';
  _ItemState({required this.categorie, required this.libelle});
}

class InspectionCreateScreen extends StatefulWidget {
  const InspectionCreateScreen({super.key});

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
  final _api      = ApiService();
  final _formKey  = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _kmCtrl    = TextEditingController();

  List<dynamic> _vehicules = [];
  bool _loadingVehicules = true;
  bool _submitting = false;

  Map<String, dynamic>? _vehiculeSelectionne;
  bool _vehiculeErreur = false;
  String  _typeInspection = 'PRE_DEPART';
  DateTime _date = DateTime.now();
  final List<_ItemState> _items = _defaultItems
      .map((e) => _ItemState(categorie: e['categorie']!, libelle: e['libelle']!))
      .toList();

  @override
  void initState() { super.initState(); _chargerVehicules(); }

  @override
  void dispose() { _notesCtrl.dispose(); _kmCtrl.dispose(); super.dispose(); }

  Future<void> _chargerVehicules() async {
    try {
      final res = await _api.get('/vehicules', params: {'limit': '200'});
      setState(() { _vehicules = res.data['data'] as List; _loadingVehicules = false; });
    } catch (e) {
      setState(() => _loadingVehicules = false);
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehiculeSelectionne == null) {
      setState(() => _vehiculeErreur = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = {
        'vehiculeId':     _vehiculeSelectionne!['id'],
        'typeInspection': _typeInspection,
        'dateInspection': _date.toIso8601String(),
        if (_kmCtrl.text.isNotEmpty) 'kilometrageReleve': int.parse(_kmCtrl.text),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        'items': _items.map((e) => {
          'categorie':   e.categorie,
          'libelle':     e.libelle,
          'resultat':    e.resultat,
          if (e.observation.isNotEmpty) 'observation': e.observation,
        }).toList(),
      };
      await _api.post('/inspections', data: body);
      if (mounted) { showSuccessSnack(context, 'Inspection créée.'); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingVehicules) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Grouper items par catégorie
    final byCategorie = <String, List<_ItemState>>{};
    for (final it in _items) {
      byCategorie.putIfAbsent(it.categorie, () => []).add(it);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle inspection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Véhicule
            _label(Icons.directions_car_outlined, 'Véhicule'),
            const SizedBox(height: 8),
            VehiculePickerField(
              vehicules: _vehicules,
              selected: _vehiculeSelectionne,
              errorText: _vehiculeErreur ? 'Sélectionnez un véhicule' : null,
              onSelected: (v) => setState(() {
                _vehiculeSelectionne = v;
                _vehiculeErreur = false;
              }),
            ),
            const SizedBox(height: 16),

            // Type
            _label(Icons.category_outlined, 'Type d\'inspection'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final t in ['PRE_DEPART', 'PERIODIQUE', 'RETOUR_MISSION', 'TECHNIQUE'])
                ChoiceChip(
                  label: Text(_typeLabel(t), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: _typeInspection == t ? Colors.white : AppTheme.textPrimary)),
                  selected: _typeInspection == t,
                  selectedColor: AppTheme.primary,
                  backgroundColor: const Color(0xFFF3F4F6),
                  onSelected: (_) => setState(() => _typeInspection = t),
                ),
            ]),
            const SizedBox(height: 16),

            // Date
            _label(Icons.calendar_today_outlined, 'Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _choisirDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                      style: const TextStyle(fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Km
            _label(Icons.speed_outlined, 'Kilométrage relevé (optionnel)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _kmCtrl,
              decoration: _inputDecor('Km actuels'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Notes
            _label(Icons.notes_outlined, 'Notes (optionnel)'),
            const SizedBox(height: 8),
            TextFormField(controller: _notesCtrl, decoration: _inputDecor('Observations générales...'), maxLines: 3),
            const SizedBox(height: 20),

            // Checklist
            _label(Icons.checklist_outlined, 'Points de contrôle'),
            const SizedBox(height: 8),
            for (final entry in byCategorie.entries) ...[
              _categorieSection(entry.key, entry.value),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _soumettre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Créer l\'inspection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorieSection(String titre, List<_ItemState> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text(titre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        ),
        const Divider(height: 1),
        for (int i = 0; i < items.length; i++) ...[
          _itemRow(items[i]),
          if (i < items.length - 1) const Divider(height: 1, indent: 14),
        ],
      ]),
    );
  }

  Widget _itemRow(_ItemState item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.libelle, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          _resultatBtn(item, 'OK', const Color(0xFF15803D), const Color(0xFFDCFCE7)),
          const SizedBox(width: 4),
          _resultatBtn(item, 'KO', AppTheme.danger, const Color(0xFFFEF2F2)),
          const SizedBox(width: 4),
          _resultatBtn(item, 'NA', AppTheme.textSecondary, const Color(0xFFF3F4F6)),
        ]),
        if (item.resultat == 'KO') ...[
          const SizedBox(height: 6),
          TextField(
            onChanged: (v) => item.observation = v,
            decoration: InputDecoration(
              hintText: 'Observation...',
              hintStyle: const TextStyle(fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ]),
    );
  }

  Widget _resultatBtn(_ItemState item, String val, Color fg, Color bg) {
    final selected = item.resultat == val;
    return GestureDetector(
      onTap: () => setState(() => item.resultat = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? bg : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? fg.withValues(alpha: 0.4) : AppTheme.border),
        ),
        child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? fg : AppTheme.textSecondary)),
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
    'PRE_DEPART'     => 'Pré-départ',
    'PERIODIQUE'     => 'Périodique',
    'RETOUR_MISSION' => 'Retour mission',
    'TECHNIQUE'      => 'Technique',
    _                => t,
  };

  Widget _label(IconData icon, String text) => Row(children: [
    Icon(icon, size: 15, color: AppTheme.primary),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
  ]);

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
    filled: true, fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}
