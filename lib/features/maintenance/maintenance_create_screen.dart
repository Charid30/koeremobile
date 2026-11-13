import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/vehicule_picker_field.dart';

class MaintenanceCreateScreen extends StatefulWidget {
  const MaintenanceCreateScreen({super.key});

  @override
  State<MaintenanceCreateScreen> createState() => _MaintenanceCreateScreenState();
}

class _MaintenanceCreateScreenState extends State<MaintenanceCreateScreen> {
  final _api        = ApiService();
  final _formKey    = GlobalKey<FormState>();
  final _descCtrl   = TextEditingController();
  final _kmCtrl     = TextEditingController();
  final _moisCtrl   = TextEditingController();

  List<dynamic> _vehicules = [];
  bool _loadingVehicules = true;
  bool _submitting = false;

  int?    _vehiculeId;
  Map<String, dynamic>? _vehiculeSelectionne;
  bool _vehiculeErreur = false;
  String  _typePlan = 'PERIODIQUE';
  DateTime? _derniereDate;

  @override
  void initState() {
    super.initState();
    _chargerVehicules();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _kmCtrl.dispose();
    _moisCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerVehicules() async {
    try {
      final res = await _api.get('/vehicules', params: {'limit': '200'});
      setState(() {
        _vehicules = res.data['data'] as List;
        _loadingVehicules = false;
      });
    } catch (e) {
      setState(() => _loadingVehicules = false);
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _derniereDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _derniereDate = d);
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehiculeId == null) {
      showErrorSnack(context, 'Sélectionnez un véhicule.');
      return;
    }
    if (_vehiculeSelectionne == null) {
      setState(() => _vehiculeErreur = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'vehiculeId': _vehiculeSelectionne!['id'],
        'typePlan':   _typePlan,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_typePlan == 'PERIODIQUE' && _kmCtrl.text.isNotEmpty)
          'derniereExecutionKm': int.parse(_kmCtrl.text),
        if (_typePlan == 'GENERALE' && _moisCtrl.text.isNotEmpty)
          'frequenceMois': int.parse(_moisCtrl.text),
        if (_typePlan == 'GENERALE' && _derniereDate != null)
          'derniereExecutionDate': _derniereDate!.toIso8601String(),
      };
      await _api.post('/maintenance-preventive', data: body);
      if (mounted) {
        showSuccessSnack(context, 'Plan de maintenance créé.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau plan')),
      body: _loadingVehicules
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Véhicule', Icons.directions_car_outlined, [
                    VehiculePickerField(
                      vehicules: _vehicules,
                      selected: _vehiculeSelectionne,
                      errorText: _vehiculeErreur ? 'Sélectionnez un véhicule' : null,
                      onSelected: (v) => setState(() {
                        _vehiculeSelectionne = v;
                        _vehiculeId = v['id'] as int;
                        _vehiculeErreur = false;
                      }),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _section('Type de plan', Icons.category_outlined, [
                    Row(children: [
                      Expanded(child: _typeCard('PERIODIQUE', Icons.speed_outlined, 'Périodique', 'Basé sur les km')),
                      const SizedBox(width: 10),
                      Expanded(child: _typeCard('GENERALE', Icons.calendar_month_outlined, 'Générale', 'Basé sur le temps')),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  _section('Description', Icons.notes_outlined, [
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecor('Description (optionnel)'),
                      maxLines: 3,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (_typePlan == 'PERIODIQUE') ...[
                    _section('Kilométrage', Icons.speed_outlined, [
                      TextFormField(
                        controller: _kmCtrl,
                        decoration: _inputDecor('Km au dernier entretien'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Prochain entretien automatiquement fixé à +10 000 km',
                              style: TextStyle(fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ] else ...[
                    _section('Intervalle', Icons.schedule_outlined, [
                      TextFormField(
                        controller: _moisCtrl,
                        decoration: _inputDecor('Fréquence (mois)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (_typePlan == 'GENERALE' && (v == null || v.isEmpty)) return 'Requis';
                          if (v != null && v.isNotEmpty && int.parse(v) < 1) return 'Minimum 1 mois';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _choisirDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: _derniereDate != null ? AppTheme.primary : AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              _derniereDate != null
                                  ? 'Dernier entretien : ${_derniereDate!.day.toString().padLeft(2, '0')}/${_derniereDate!.month.toString().padLeft(2, '0')}/${_derniereDate!.year}'
                                  : 'Date du dernier entretien (optionnel)',
                              style: TextStyle(
                                fontSize: 14,
                                color: _derniereDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _soumettre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Créer le plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 8),
      ...children,
    ]);
  }

  Widget _typeCard(String value, IconData icon, String label, String sub) {
    final selected = _typePlan == value;
    return GestureDetector(
      onTap: () => setState(() => _typePlan = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: selected ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppTheme.primary : AppTheme.textPrimary)),
          Text(sub, style: TextStyle(fontSize: 11, color: selected ? AppTheme.primary : AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}
