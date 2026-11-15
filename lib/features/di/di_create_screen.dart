import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class DiCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? vehiculePreselectionne;
  const DiCreateScreen({super.key, this.vehiculePreselectionne});

  @override
  State<DiCreateScreen> createState() => _DiCreateScreenState();
}

class _DiCreateScreenState extends State<DiCreateScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _descCtrl        = TextEditingController();
  final _localisationCtrl = TextEditingController();
  final _vehiculeSearchCtrl = TextEditingController();

  List<dynamic> _vehicules = [];
  List<dynamic> _vehiculesFiltres = [];
  Map<String, dynamic>? _vehiculeSelectionne;
  bool _showResults = false;

  String _priorite = 'NORMALE';
  bool _loading = false;
  bool _geoLoading = false;
  String? _geoErreur;

  @override
  void initState() {
    super.initState();
    _chargerVehicules();
    if (widget.vehiculePreselectionne != null) {
      _vehiculeSelectionne = widget.vehiculePreselectionne;
    }
    // Récupérer automatiquement la position GPS à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) => _geoLocaliser());
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _localisationCtrl.dispose();
    _vehiculeSearchCtrl.dispose();
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

  void _filtrerVehicules(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _showResults = query.isNotEmpty;
      _vehiculesFiltres = query.isEmpty
          ? []
          : _vehicules.where((v) {
              final vm = v as Map<String, dynamic>;
              return (vm['immatriculation'] as String).toLowerCase().contains(query) ||
                     (vm['numeroInterne'] as String).toLowerCase().contains(query) ||
                     '${vm['marque']} ${vm['modele']}'.toLowerCase().contains(query);
            }).take(8).toList();
    });
  }

  Future<void> _geoLocaliser() async {
    setState(() { _geoLoading = true; _geoErreur = null; });
    try {
      // Vérifier si le service de localisation est activé
      final serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) {
        setState(() { _geoErreur = 'GPS désactivé — activez la localisation dans les paramètres'; _geoLoading = false; });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() { _geoErreur = 'Permission de localisation refusée'; _geoLoading = false; });
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _geoErreur = 'Permission refusée définitivement — modifiez-la dans les paramètres de l\'application'; _geoLoading = false; });
        return;
      }

      // Essayer d'abord avec medium (plus rapide sur MIUI), puis high si besoin
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 20));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        setState(() { _geoErreur = 'Position indisponible — réessayez en extérieur'; _geoLoading = false; });
        return;
      }

      // Stocker les coordonnées GPS brutes pour suivi Google Maps
      _localisationCtrl.text =
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';

      setState(() => _geoLoading = false);
    } on LocationServiceDisabledException {
      setState(() { _geoErreur = 'GPS désactivé — activez la localisation'; _geoLoading = false; });
    } catch (e) {
      setState(() { _geoErreur = 'Erreur : ${e.runtimeType}'; _geoLoading = false; });
    }
  }

  Future<void> _soumettre() async {
    if (_vehiculeSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un véhicule'), backgroundColor: AppTheme.danger));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'vehiculeId': _vehiculeSelectionne!['id'],
        'description': _descCtrl.text.trim(),
        'priorite': _priorite,
      };
      final loc = _localisationCtrl.text.trim();
      if (loc.isNotEmpty) body['localisation'] = loc;
      await _api.post('/demandes-intervention', data: body);
      if (mounted) {
        showSuccessSnack(context, 'Demande créée avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Véhicule ─────────────────────────────────────────────
            const Text('Véhicule *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            if (_vehiculeSelectionne != null)
              _vehiculeBadge()
            else
              _vehiculeSearch(),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────
            const Text('Description *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Décrivez le problème constaté…'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description requise' : null,
            ),
            const SizedBox(height: 16),

            // ── Localisation ─────────────────────────────────────────
            const Text('Localisation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _localisationCtrl,
                  decoration: const InputDecoration(hintText: 'Rue, quartier, ville…'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _geoLoading ? null : _geoLocaliser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: AppTheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: _geoLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.my_location, size: 20),
                ),
              ),
            ]),
            if (_geoErreur != null) ...[
              const SizedBox(height: 4),
              Text(_geoErreur!, style: const TextStyle(fontSize: 12, color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),

            // ── Priorité ─────────────────────────────────────────────
            const Text('Priorité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final p in ['FAIBLE', 'NORMALE', 'URGENTE', 'CRITIQUE'])
                ChoiceChip(
                  label: Text(p),
                  selected: _priorite == p,
                  onSelected: (_) => setState(() => _priorite = p),
                  selectedColor: p == 'CRITIQUE' ? const Color(0xFFFEF2F2) : p == 'URGENTE' ? const Color(0xFFFFF7ED) : AppTheme.primaryLight,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _priorite == p
                        ? (p == 'CRITIQUE' ? AppTheme.danger : p == 'URGENTE' ? AppTheme.warning : AppTheme.primary)
                        : AppTheme.textSecondary,
                  ),
                ),
            ]),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _loading ? null : _soumettre,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Soumettre la demande'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _vehiculeBadge() => Container(
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
      IconButton(
        icon: const Icon(Icons.close, color: AppTheme.primary, size: 18),
        onPressed: () => setState(() { _vehiculeSelectionne = null; _vehiculeSearchCtrl.clear(); }),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ]),
  );

  Widget _vehiculeSearch() => Column(children: [
    TextField(
      controller: _vehiculeSearchCtrl,
      decoration: const InputDecoration(
        hintText: 'Immatriculation, n° interne, marque…',
        prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
      ),
      onChanged: _filtrerVehicules,
    ),
    if (_showResults && _vehiculesFiltres.isNotEmpty)
      Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: _vehiculesFiltres.map((v) {
            final vm = v as Map<String, dynamic>;
            return ListTile(
              dense: true,
              leading: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.directions_car, color: AppTheme.primary, size: 16),
              ),
              title: Text(vm['immatriculation'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('${vm['marque']} ${vm['modele']}', style: const TextStyle(fontSize: 12)),
              trailing: Text('${vm['kilometrage']} km', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () => setState(() {
                _vehiculeSelectionne = vm;
                _vehiculeSearchCtrl.clear();
                _showResults = false;
              }),
            );
          }).toList(),
        ),
      ),
  ]);
}
