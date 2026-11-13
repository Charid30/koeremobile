import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'inspection_detail_screen.dart';
import 'inspection_create_screen.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final _api = ApiService();
  List<dynamic> _list = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/inspections', params: {'limit': '50'});
      setState(() { _list = res.data['data'] as List; _loading = false; });
    } catch (e) {
      setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_inspections',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionCreateScreen()))
            .then((ok) { if (ok == true) _charger(); }),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error!, onRetry: _charger)
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: _list.isEmpty
                      ? _emptyView()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final ins = _list[i] as Map<String, dynamic>;
                            final conforme = ins['conforme'] as bool? ?? false;
                            final (iconColor, bgColor) = conforme
                                ? (const Color(0xFF15803D), const Color(0xFFDCFCE7))
                                : (AppTheme.danger, const Color(0xFFFEF2F2));
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => InspectionDetailScreen(inspectionId: ins['id'] as int)),
                                ).then((_) => _charger()),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                                      child: Icon(
                                        conforme ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                                        color: iconColor, size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(ins['vehicule']?['immatriculation'] ?? '-',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(_typeLabel(ins['typeInspection'] as String?),
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                      if (ins['dateInspection'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(_formatDate(ins['dateInspection']),
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          conforme ? 'Conforme' : 'Non conforme',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iconColor),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
                                    ]),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  String _typeLabel(String? t) => switch (t) {
    'PRE_DEPART'     => 'Pré-départ',
    'PERIODIQUE'     => 'Périodique',
    'RETOUR_MISSION' => 'Retour mission',
    'TECHNIQUE'      => 'Technique',
    _                => t ?? '-',
  };

  Widget _emptyView() => ListView(children: [
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.checklist_outlined, size: 56, color: AppTheme.border),
        SizedBox(height: 16),
        Text('Aucune inspection enregistrée.\nAppuyez sur + pour en créer une.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6), textAlign: TextAlign.center),
      ]),
    ),
  ]);

  String _formatDate(dynamic val) {
    if (val == null) return '';
    try {
      final d = DateTime.parse(val.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return ''; }
  }
}
