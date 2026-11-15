/// Mise en forme des valeurs pour l'affichage (français).
library;

const _mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? lireDate(dynamic val) {
  if (val == null) return null;
  return DateTime.tryParse(val.toString())?.toLocal();
}

/// 15/11/2026
String dateCourte(dynamic val) {
  final d = lireDate(val);
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// 15 nov. 2026 · 14:05
String dateHeure(dynamic val) {
  final d = lireDate(val);
  if (d == null) return '—';
  return '${d.day} ${_mois[d.month - 1]} ${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// « à l'instant », « il y a 3 h », « hier », « il y a 4 j », puis la date.
String ilYA(dynamic val) {
  final d = lireDate(val);
  if (d == null) return '—';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${d.day} ${_mois[d.month - 1]}${d.year != DateTime.now().year ? ' ${d.year}' : ''}';
}

/// 125 400 (espace fine comme séparateur de milliers)
String nombre(dynamic val) {
  if (val == null) return '—';
  final n = num.tryParse(val.toString());
  if (n == null) return '—';
  return n.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
}

/// Initiales d'une personne : « Kevin Bationo » → « KB »
String initiales(String? prenom, String? nom) {
  final a = (prenom ?? '').trim();
  final b = (nom ?? '').trim();
  final r = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'.toUpperCase();
  return r.isEmpty ? '?' : r;
}

/// Salutation selon l'heure.
String salutation() {
  final h = DateTime.now().hour;
  return h < 18 ? 'Bonjour' : 'Bonsoir';
}
