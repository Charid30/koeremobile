import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'di_create_screen.dart';
import 'di_detail_screen.dart';

class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
  final _api = ApiService();
  List<dynamic> _list = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() { super.initState(); _charger(); }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/demandes-intervention', params: {'limit': '100'});
      setState(() { _list = res.data['data'] as List; _loading = false; });
    } catch (e) {
      setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiCreateScreen())).then((_) => _charger()),
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
                            final d = _list[i] as Map<String, dynamic>;
                            final statut = d['statut'] as String? ?? '';
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiDetailScreen(di: d))).then((_) => _charger()),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(
                                        d['vehicule'] != null ? '${d['vehicule']['immatriculation']}' : 'Véhicule inconnu',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                                      )),
                                      _statutBadge(statut),
                                    ]),
                                    if (d['vehicule'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d['vehicule']['marque']} ${d['vehicule']['modele']}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    if (d['description'] != null) ...[
                                      const SizedBox(height: 6),
                                      Text(d['description'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(d['localisation'] ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
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

  Widget _emptyView() => ListView(children: [
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.build_circle_outlined, size: 56, color: AppTheme.border),
        SizedBox(height: 16),
        Text('Aucune demande d\'intervention.\nAppuyez sur + pour en créer une.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          textAlign: TextAlign.center),
      ]),
    ),
  ]);

  Widget _statutBadge(String statut) {
    final (bg, fg, label) = switch (statut) {
      'EN_ATTENTE'      => (const Color(0xFFFFF7ED), AppTheme.warning, 'En attente'),
      'PRISE_EN_CHARGE' => (AppTheme.primaryLight, AppTheme.primary, 'Prise en charge'),
      'TRAITEE'         => (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Traitée'),
      'REJETEE'         => (const Color(0xFFFEF2F2), AppTheme.danger, 'Rejetée'),
      _                 => (const Color(0xFFF3F4F6), AppTheme.textSecondary, statut),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
