import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class ReleveKmScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicule;
  const ReleveKmScreen({super.key, this.vehicule});

  @override
  State<ReleveKmScreen> createState() => _ReleveKmScreenState();
}

class _ReleveKmScreenState extends State<ReleveKmScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<dynamic> _vehicules = [];
  List<dynamic> _vehiculesFiltres = [];
  Map<String, dynamic>? _vehiculeSelectionne;
  bool _showResults = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicule != null) {
      _vehiculeSelectionne = widget.vehicule;
      _kmCtrl.text = (widget.vehicule!['kilometrage'] ?? '').toString();
    }
    _chargerVehicules();
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerVehicules() async {
    try {
      final res = await _api.get('/vehicules', params: {'limit': '200'});
      setState(() => _vehicules = res.data['data'] as List);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _filtrer(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _showResults = query.isNotEmpty;
      _vehiculesFiltres = _vehicules.where((v) {
        final vm = v as Map<String, dynamic>;
        return (vm['immatriculation'] as String).toLowerCase().contains(query) ||
               (vm['numeroInterne'] as String).toLowerCase().contains(query) ||
               '${vm['marque']} ${vm['modele']}'.toLowerCase().contains(query);
      }).take(8).toList();
    });
  }

  Future<void> _soumettre() async {
    if (_vehiculeSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un véhicule'), backgroundColor: AppTheme.danger));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final km = int.parse(_kmCtrl.text.trim());
      final vehiculeId = _vehiculeSelectionne!['id'];
      await _api.put('/vehicules/$vehiculeId', data: {'kilometrage': km});
      if (mounted) {
        showSuccessSnack(context, 'Relevé enregistré avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmActuel = _vehiculeSelectionne?['kilometrage'];

    return Scaffold(
      appBar: AppBar(title: const Text('Relevé kilométrique')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Véhicule ─────────────────────────────────────────────
            const Text('Véhicule *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            if (_vehiculeSelectionne != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha:0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.directions_car, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_vehiculeSelectionne!['immatriculation'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    Text('${_vehiculeSelectionne!['marque']} ${_vehiculeSelectionne!['modele']}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                  ])),
                  if (widget.vehicule == null)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primary, size: 18),
                      onPressed: () => setState(() { _vehiculeSelectionne = null; _kmCtrl.clear(); _searchCtrl.clear(); }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ]),
              )
            else
              Column(children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un véhicule…',
                    prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                  ),
                  onChanged: _filtrer,
                ),
                if (_showResults && _vehiculesFiltres.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: _vehiculesFiltres.map((v) {
                        final vm = v as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          title: Text(vm['immatriculation'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${vm['marque']} ${vm['modele']}', style: const TextStyle(fontSize: 12)),
                          trailing: Text('${vm['kilometrage']} km', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          onTap: () => setState(() {
                            _vehiculeSelectionne = vm;
                            _kmCtrl.text = (vm['kilometrage'] ?? '').toString();
                            _searchCtrl.clear();
                            _showResults = false;
                          }),
                        );
                      }).toList(),
                    ),
                  ),
              ]),
            const SizedBox(height: 20),

            // ── Km actuel info ───────────────────────────────────────
            if (kmActuel != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text('Dernier relevé enregistré : $kmActuel km', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              ),

            // ── Nouveau km ───────────────────────────────────────────
            const Text('Kilométrage actuel *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _kmCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'ex. 48 250',
                suffixText: 'km',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Kilométrage requis';
                final km = int.tryParse(v.trim());
                if (km == null || km < 0) return 'Valeur invalide';
                if (kmActuel != null && km < (kmActuel as num).toInt()) return 'Inférieur au dernier relevé ($kmActuel km)';
                return null;
              },
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _loading ? null : _soumettre,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer le relevé'),
            ),
          ]),
        ),
      ),
    );
  }
}
