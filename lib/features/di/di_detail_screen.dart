import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';

class DiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> di;
  const DiDetailScreen({super.key, required this.di});

  @override
  State<DiDetailScreen> createState() => _DiDetailScreenState();
}

class _DiDetailScreenState extends State<DiDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/demandes-intervention/${widget.di['id']}');
      setState(() { _detail = res.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      setState(() { _detail = widget.di; _loading = false; });
    }
  }

  // Corrigé : utilise /statut
  Future<void> _changerStatut(String statut) async {
    setState(() => _actionLoading = true);
    try {
      await _api.patch('/demandes-intervention/${widget.di['id']}/statut', data: {'statut': statut});
      await _charger();
      if (mounted) showSuccessSnack(context, 'Statut mis à jour');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
    setState(() => _actionLoading = false);
  }

  Future<void> _supprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la demande'),
        content: const Text('Cette action est irréversible. Confirmer la suppression ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.delete('/demandes-intervention/${widget.di['id']}');
      if (mounted) { Navigator.pop(context, true); showSuccessSnack(context, 'Demande supprimée'); }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _editer() async {
    final d = _detail ?? widget.di;
    final descCtrl  = TextEditingController(text: d['description'] as String? ?? '');
    final locCtrl   = TextEditingController(text: d['localisation'] as String? ?? '');
    String priorite = d['priorite'] as String? ?? 'NORMALE';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Modifier la demande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: _inputDecor('Décrivez le problème...'),
              ),
              const SizedBox(height: 14),

              // Localisation
              const Text('Localisation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(controller: locCtrl, decoration: _inputDecor('Rue, quartier, ville...')),
              const SizedBox(height: 14),

              // Priorité
              const Text('Priorité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final p in ['FAIBLE', 'NORMALE', 'URGENTE', 'CRITIQUE'])
                  ChoiceChip(
                    label: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: priorite == p ? Colors.white : AppTheme.textSecondary)),
                    selected: priorite == p,
                    selectedColor: p == 'CRITIQUE' ? AppTheme.danger : p == 'URGENTE' ? AppTheme.warning : AppTheme.primary,
                    backgroundColor: const Color(0xFFF3F4F6),
                    onSelected: (_) => setLocal(() => priorite = p),
                  ),
              ]),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _api.patch('/demandes-intervention/${widget.di['id']}', data: {
                        if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                        if (locCtrl.text.trim().isNotEmpty) 'localisation': locCtrl.text.trim(),
                        'priorite': priorite,
                      });
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) showErrorSnack(ctx, e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          );
        });
      },
    );
    descCtrl.dispose();
    locCtrl.dispose();
    if (saved == true) {
      await _charger();
      if (mounted) showSuccessSnack(context, 'Demande modifiée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail ?? widget.di;
    final statut = d['statut'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande d\'intervention'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editer, tooltip: 'Modifier'),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.danger), onPressed: _supprimer, tooltip: 'Supprimer'),
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _charger),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // ── En-tête ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          d['vehicule']?['immatriculation'] ?? '-',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                      ),
                      _statutBadge(statut),
                    ]),
                    Text('${d['vehicule']?['marque']} ${d['vehicule']?['modele']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    _prioriteBadge(d['priorite'] as String? ?? 'NORMALE'),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Description ──────────────────────────────────────
                _card('Description', d['description'] ?? '-'),
                const SizedBox(height: 12),

                // ── Localisation ─────────────────────────────────────
                if (d['localisation'] != null && (d['localisation'] as String).isNotEmpty) ...[
                  _localisationCard(d['localisation'] as String),
                  const SizedBox(height: 12),
                ],

                // ── Infos ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                  child: Column(children: [
                    _infoLigne('Demandeur', d['demandeur'] != null ? '${d['demandeur']['prenom']} ${d['demandeur']['nom']}' : '-'),
                    const Divider(height: 20, color: AppTheme.border),
                    _infoLigne('Date', _formatDate(d['createdAt'])),
                    if (d['assigneA'] != null) ...[
                      const Divider(height: 20, color: AppTheme.border),
                      _infoLigne('Assigné à', '${d['assigneA']['prenom']} ${d['assigneA']['nom']}'),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Actions de statut ────────────────────────────────
                if (statut != 'TRAITEE' && statut != 'REJETEE') ...[
                  const Text('Changer le statut', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (_actionLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (statut == 'EN_ATTENTE')
                        _actionBtn('PRISE_EN_CHARGE', 'Prendre en charge', AppTheme.primary, Icons.play_circle_outline),
                      if (statut == 'PRISE_EN_CHARGE')
                        _actionBtn('TRAITEE', 'Marquer traitée', AppTheme.success, Icons.check_circle_outline),
                      _actionBtn('REJETEE', 'Rejeter', AppTheme.danger, Icons.cancel_outlined),
                    ]),
                ],
              ]),
            ),
    );
  }

  // Retourne true si le texte ressemble à "lat, lon"
  bool _estCoordonnees(String loc) {
    final parts = loc.split(',');
    if (parts.length != 2) return false;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    return lat != null && lon != null;
  }

  Future<void> _ouvrirGoogleMaps(String loc) async {
    final parts = loc.split(',');
    final lat = parts[0].trim();
    final lon = parts[1].trim();
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _localisationCard(String loc) {
    final isGps = _estCoordonnees(loc);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(loc, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
        if (isGps) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _ouvrirGoogleMaps(loc),
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('Maps', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: AppTheme.primaryLight,
            ),
          ),
        ],
      ]),
    );
  }

  Widget _card(String titre, String contenu) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Text(contenu, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
    ]),
  );

  Widget _infoLigne(String label, String valeur) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    const Spacer(),
    Text(valeur, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  ]);

  Widget _actionBtn(String statut, String label, Color color, IconData icon) => OutlinedButton.icon(
    onPressed: () => _changerStatut(statut),
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  Widget _statutBadge(String statut) {
    final (bg, fg, label) = switch (statut) {
      'EN_ATTENTE'      => (const Color(0xFFFFF7ED), AppTheme.warning, 'En attente'),
      'PRISE_EN_CHARGE' => (const Color(0xFFEFF6FF), AppTheme.primary, 'Prise en charge'),
      'TRAITEE'         => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Traitée'),
      'REJETEE'         => (const Color(0xFFFEF2F2), AppTheme.danger, 'Rejetée'),
      _                 => (const Color(0xFFF3F4F6), AppTheme.textSecondary, statut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _prioriteBadge(String p) {
    final (bg, fg) = switch (p) {
      'CRITIQUE' => (const Color(0xFFFEF2F2), AppTheme.danger),
      'URGENTE'  => (const Color(0xFFFFF7ED), AppTheme.warning),
      'FAIBLE'   => (const Color(0xFFF3F4F6), AppTheme.textSecondary),
      _          => (AppTheme.primaryLight, AppTheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text('Priorité $p', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
    filled: true, fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  String _formatDate(dynamic val) {
    if (val == null) return '-';
    try {
      final d = DateTime.parse(val.toString()).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return '-'; }
  }
}
