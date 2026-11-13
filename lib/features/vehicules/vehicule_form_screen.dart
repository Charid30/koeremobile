import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class VehiculeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicule;
  const VehiculeFormScreen({super.key, this.vehicule});

  @override
  State<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends State<VehiculeFormScreen> {
  final _api     = ApiService();
  final _pageCtrl = PageController();
  int _etape     = 0;
  bool _loading  = false;
  bool get _isEdit => widget.vehicule != null;

  // Étape 1
  final _fk1 = GlobalKey<FormState>();
  late final TextEditingController _numeroInterneCtrl;
  late final TextEditingController _immatriculationCtrl;
  late final TextEditingController _numeroSerieCtrl;

  // Étape 2
  final _fk2 = GlobalKey<FormState>();
  late final TextEditingController _marqueCtrl;
  late final TextEditingController _modeleCtrl;
  late final TextEditingController _couleurCtrl;
  late final TextEditingController _anneeCtrl;
  String _typeVehicule = 'VOITURE';
  String _carburant    = 'DIESEL';

  // Étape 3
  final _fk3 = GlobalKey<FormState>();
  late final TextEditingController _entiteCtrl;
  late final TextEditingController _departementCtrl;
  late final TextEditingController _siteCtrl;

  // Étape 4
  final _fk4 = GlobalKey<FormState>();
  late final TextEditingController _kmCtrl;
  late final TextEditingController _heuresCtrl;
  late final TextEditingController _dateMiseEnServiceCtrl;
  late final TextEditingController _dateAcquisitionCtrl;
  late final TextEditingController _notesCtrl;
  String _statut = 'DISPONIBLE';

  static const _steps = [
    (icon: Icons.badge_outlined,        label: 'Identification'),
    (icon: Icons.directions_car_outlined, label: 'Véhicule'),
    (icon: Icons.apartment_outlined,    label: 'Affectation'),
    (icon: Icons.tune_outlined,         label: 'Finalisation'),
  ];

  static const _typesVehicule = ['VOITURE', 'CAMION', 'EQUIPEMENT_SPECIAL', 'ENGIN_TP'];
  static const _carburants    = ['DIESEL', 'ESSENCE', 'HYBRIDE', 'ELECTRIQUE', 'GPL'];
  static const _statuts       = [
    'DISPONIBLE', 'EN_CIRCULATION', 'EN_MAINTENANCE',
    'EN_ATTENTE_REPARATION_EXTERNE', 'EN_ATTENTE_PIECES',
    'IMMOBILISE', 'ACCIDENTE', 'HORS_SERVICE',
  ];
  static const _statutLabels = {
    'DISPONIBLE':                   'Disponible',
    'EN_CIRCULATION':               'En circulation',
    'EN_MAINTENANCE':               'En maintenance',
    'EN_ATTENTE_REPARATION_EXTERNE':'En attente réparation ext.',
    'EN_ATTENTE_PIECES':            'En attente de pièces',
    'IMMOBILISE':                   'Immobilisé',
    'ACCIDENTE':                    'Accidenté',
    'HORS_SERVICE':                 'Hors service',
  };
  static const _typeIcons = {
    'VOITURE':          Icons.directions_car,
    'CAMION':           Icons.local_shipping,
    'EQUIPEMENT_SPECIAL': Icons.construction,
    'ENGIN_TP':         Icons.agriculture,
  };

  @override
  void initState() {
    super.initState();
    final v = widget.vehicule ?? {};
    _numeroInterneCtrl     = TextEditingController(text: v['numeroInterne'] ?? '');
    _immatriculationCtrl   = TextEditingController(text: v['immatriculation'] ?? '');
    _numeroSerieCtrl       = TextEditingController(text: v['numeroSerie'] ?? '');
    _marqueCtrl            = TextEditingController(text: v['marque'] ?? '');
    _modeleCtrl            = TextEditingController(text: v['modele'] ?? '');
    _couleurCtrl           = TextEditingController(text: v['couleur'] ?? '');
    _anneeCtrl             = TextEditingController(text: v['annee']?.toString() ?? '');
    _entiteCtrl            = TextEditingController(text: v['entite'] ?? '');
    _departementCtrl       = TextEditingController(text: v['departement'] ?? '');
    _siteCtrl              = TextEditingController(text: v['siteGeographique'] ?? '');
    _kmCtrl                = TextEditingController(text: v['kilometrage']?.toString() ?? '');
    _heuresCtrl            = TextEditingController(text: v['heuresMoteur']?.toString() ?? '');
    _dateMiseEnServiceCtrl = TextEditingController(text: _toDate(v['dateMiseEnService']));
    _dateAcquisitionCtrl   = TextEditingController(text: _toDate(v['dateAcquisition']));
    _notesCtrl             = TextEditingController(text: v['notes'] ?? '');
    if (_isEdit) {
      _typeVehicule = v['typeVehicule'] ?? 'VOITURE';
      _carburant    = v['typeCarburant'] ?? v['carburant'] ?? 'DIESEL';
      _statut       = v['statut'] ?? 'DISPONIBLE';
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [_numeroInterneCtrl, _immatriculationCtrl, _numeroSerieCtrl,
      _marqueCtrl, _modeleCtrl, _couleurCtrl, _anneeCtrl, _entiteCtrl,
      _departementCtrl, _siteCtrl, _kmCtrl, _heuresCtrl,
      _dateMiseEnServiceCtrl, _dateAcquisitionCtrl, _notesCtrl]) { c.dispose(); }
    super.dispose();
  }

  String _toDate(dynamic v) {
    if (v == null) return '';
    try { return DateTime.parse(v.toString()).toIso8601String().substring(0, 10); }
    catch (_) { return ''; }
  }

  GlobalKey<FormState> get _fk => [_fk1, _fk2, _fk3, _fk4][_etape];

  void _next() {
    if (!_fk.currentState!.validate()) return;
    if (_etape < 3) {
      setState(() => _etape++);
      _pageCtrl.animateToPage(_etape, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_etape > 0) {
      setState(() => _etape--);
      _pageCtrl.animateToPage(_etape, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final data = <String, dynamic>{
      'numeroInterne':   _numeroInterneCtrl.text.trim(),
      'immatriculation': _immatriculationCtrl.text.trim(),
      'marque':          _marqueCtrl.text.trim(),
      'modele':          _modeleCtrl.text.trim(),
      'typeVehicule':    _typeVehicule,
      'carburant':       _carburant,
      'statut':          _statut,
    };
    void opt(String k, String raw, {bool isInt = false, bool isDate = false}) {
      final t = raw.trim();
      if (t.isEmpty) return;
      if (isInt) {
        final n = int.tryParse(t);
        if (n != null) data[k] = n;
      } else if (isDate) {
        data[k] = '${t}T00:00:00.000Z';
      } else {
        data[k] = t;
      }
    }
    opt('numeroSerie', _numeroSerieCtrl.text);
    opt('couleur', _couleurCtrl.text);
    opt('annee', _anneeCtrl.text, isInt: true);
    opt('entite', _entiteCtrl.text);
    opt('departement', _departementCtrl.text);
    opt('siteGeographique', _siteCtrl.text);
    opt('kilometrage', _kmCtrl.text, isInt: true);
    opt('heuresMoteur', _heuresCtrl.text, isInt: true);
    opt('dateMiseEnService', _dateMiseEnServiceCtrl.text, isDate: true);
    opt('dateAcquisition', _dateAcquisitionCtrl.text, isDate: true);
    opt('notes', _notesCtrl.text);
    try {
      if (_isEdit) {
        await _api.put('/vehicules/${widget.vehicule!['id']}', data: data);
      } else {
        await _api.post('/vehicules', data: data);
      }
      if (mounted) {
        showSuccessSnack(context, _isEdit ? 'Véhicule mis à jour' : 'Véhicule créé avec succès');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          _isEdit ? 'Modifier le véhicule' : 'Nouveau véhicule',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(children: [
        // ── Stepper visuel ───────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final idx = i ~/ 2;
              return Expanded(child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: idx < _etape ? AppTheme.primary : const Color(0xFFE5E7EB),
                ),
              ));
            }
            final idx = i ~/ 2;
            final done    = idx < _etape;
            final current = idx == _etape;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.primary : current ? AppTheme.primary : const Color(0xFFF1F5F9),
                  boxShadow: current ? [BoxShadow(color: AppTheme.primary.withValues(alpha:0.25), blurRadius: 10, spreadRadius: 2)] : [],
                ),
                child: Icon(
                  done ? Icons.check_rounded : _steps[idx].icon,
                  size: 18,
                  color: (done || current) ? Colors.white : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(_steps[idx].label, style: TextStyle(
                fontSize: 10,
                fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                color: current ? AppTheme.primary : done ? AppTheme.primary : AppTheme.textSecondary,
              )),
            ]);
          })),
        ),

        // ── Pages ─────────────────────────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [_page1(), _page2(), _page3(), _page4()],
          ),
        ),

        // ── Barre de navigation ───────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          child: Row(children: [
            if (_etape > 0) ...[
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    foregroundColor: AppTheme.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Row(children: [
                    Icon(Icons.arrow_back_ios, size: 14),
                    SizedBox(width: 4),
                    Text('Retour'),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            _etape == 3 ? (_isEdit ? 'Enregistrer' : 'Créer le véhicule') : 'Continuer',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          if (_etape < 3) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_ios, size: 14)],
                        ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── ÉTAPE 1 ──────────────────────────────────────────────────
  Widget _page1() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _fk1, child: Column(children: [
      _pageHeader(Icons.badge_outlined, 'Identification', 'Les données administratives du véhicule'),
      _card(children: [
        _fld('N° interne', _numeroInterneCtrl, icon: Icons.tag, hint: 'ex. VH-001', required: true),
        _divider(),
        _fld('Immatriculation', _immatriculationCtrl, icon: Icons.credit_card_outlined, hint: 'ex. AB-123-CD', required: true, caps: true),
        _divider(),
        _fld('N° de série / VIN', _numeroSerieCtrl, icon: Icons.qr_code_outlined, hint: 'Optionnel'),
      ]),
    ])),
  );

  // ── ÉTAPE 2 ──────────────────────────────────────────────────
  Widget _page2() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _fk2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.directions_car_outlined, 'Caractéristiques', 'Marque, modèle et motorisation'),
      _card(children: [
        _fld('Marque', _marqueCtrl, icon: Icons.business_outlined, hint: 'ex. Toyota', required: true),
        _divider(),
        _fld('Modèle', _modeleCtrl, icon: Icons.model_training_outlined, hint: 'ex. Hilux', required: true),
        _divider(),
        _fld('Couleur', _couleurCtrl, icon: Icons.palette_outlined, hint: 'ex. Blanc'),
        _divider(),
        _fld('Année', _anneeCtrl, icon: Icons.calendar_month_outlined, hint: 'ex. 2022', numeric: true),
      ]),
      const SizedBox(height: 16),
      _cardTitle('Type de véhicule'),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: _typesVehicule.map((t) {
          final sel = t == _typeVehicule;
          return GestureDetector(
            onTap: () => setState(() => _typeVehicule = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_typeIcons[t] ?? Icons.directions_car, color: sel ? Colors.white : AppTheme.textSecondary, size: 20),
                const SizedBox(height: 4),
                Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textSecondary), textAlign: TextAlign.center),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      _cardTitle('Carburant'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _carburants.map((c) {
        final sel = c == _carburant;
        return GestureDetector(
          onTap: () => setState(() => _carburant = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
            ),
            child: Text(c, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppTheme.textSecondary)),
          ),
        );
      }).toList()),
    ])),
  );

  // ── ÉTAPE 3 ──────────────────────────────────────────────────
  Widget _page3() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _fk3, child: Column(children: [
      _pageHeader(Icons.apartment_outlined, 'Affectation', 'Structure et localisation du véhicule'),
      _card(children: [
        _fld('Structure / Entité', _entiteCtrl, icon: Icons.domain_outlined, hint: 'ex. Ministère de la Santé'),
        _divider(),
        _fld('Direction', _departementCtrl, icon: Icons.account_tree_outlined, hint: 'ex. Direction Générale'),
        _divider(),
        _fld('Site géographique', _siteCtrl, icon: Icons.location_city_outlined, hint: 'ex. Ouagadougou'),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Ces informations permettent de rattacher le véhicule à la bonne entité administrative.',
            style: TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.4),
          )),
        ]),
      ),
    ])),
  );

  // ── ÉTAPE 4 ──────────────────────────────────────────────────
  Widget _page4() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _fk4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.tune_outlined, 'Finalisation', 'Compteurs, dates et état du véhicule'),
      _card(children: [
        _fld('Kilométrage (km)', _kmCtrl, icon: Icons.speed_outlined, hint: 'ex. 45 200', numeric: true),
        _divider(),
        _fld('Heures moteur (h)', _heuresCtrl, icon: Icons.timer_outlined, hint: 'ex. 1 250', numeric: true),
      ]),
      const SizedBox(height: 16),
      _card(children: [
        _dateFld('Date de mise en service', _dateMiseEnServiceCtrl, Icons.event_available_outlined),
        _divider(),
        _dateFld('Date d\'acquisition', _dateAcquisitionCtrl, Icons.shopping_bag_outlined),
      ]),
      const SizedBox(height: 16),
      _cardTitle('Statut du véhicule'),
      const SizedBox(height: 10),
      ..._statuts.map((s) {
        final sel = s == _statut;
        final (color, bg) = switch (s) {
          'DISPONIBLE'                    => (const Color(0xFF15803D), const Color(0xFFDCFCE7)),
          'EN_CIRCULATION'                => (AppTheme.primary, const Color(0xFFEFF6FF)),
          'EN_MAINTENANCE'                => (AppTheme.warning, const Color(0xFFFFF7ED)),
          'EN_ATTENTE_REPARATION_EXTERNE' => (AppTheme.warning, const Color(0xFFFFF7ED)),
          'EN_ATTENTE_PIECES'             => (AppTheme.warning, const Color(0xFFFFF7ED)),
          'IMMOBILISE'                    => (AppTheme.danger, const Color(0xFFFEF2F2)),
          'ACCIDENTE'                     => (AppTheme.danger, const Color(0xFFFEF2F2)),
          'HORS_SERVICE'                  => (AppTheme.textSecondary, const Color(0xFFF3F4F6)),
          _                               => (AppTheme.textSecondary, const Color(0xFFF3F4F6)),
        };
        return GestureDetector(
          onTap: () => setState(() => _statut = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: sel ? bg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? color : AppTheme.border, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? color : AppTheme.border),
              ),
              const SizedBox(width: 12),
              Text(_statutLabels[s] ?? s, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? color : AppTheme.textSecondary)),
              const Spacer(),
              if (sel) Icon(Icons.check_circle, color: color, size: 18),
            ]),
          ),
        );
      }),
      const SizedBox(height: 16),
      _cardTitle('Notes'),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
        child: TextFormField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Remarques, observations particulières…',
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        ),
      ),
    ])),
  );

  // ── Widgets utilitaires ───────────────────────────────────────

  Widget _pageHeader(IconData icon, String titre, String sous) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text(sous, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ])),
    ]),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
    child: Column(children: children),
  );

  Widget _cardTitle(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.3));

  Widget _divider() => const Divider(height: 1, indent: 52, color: AppTheme.border);

  Widget _fld(String label, TextEditingController ctrl, {required IconData icon, String? hint, bool required = false, bool numeric = false, bool caps = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
          ),
        ),
      ]),
    );

  Widget _dateFld(String label, TextEditingController ctrl, IconData icon) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: ctrl.text.isNotEmpty ? DateTime.tryParse(ctrl.text) ?? DateTime.now() : DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => ctrl.text = d.toIso8601String().substring(0, 10));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(ctrl.text.isEmpty ? 'Sélectionner une date' : ctrl.text,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ctrl.text.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)),
                ])),
                if (ctrl.text.isNotEmpty)
                  GestureDetector(onTap: () => setState(() => ctrl.clear()), child: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary))
                else
                  const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
              ]),
            ),
          ),
        ),
      ]),
    );

}
