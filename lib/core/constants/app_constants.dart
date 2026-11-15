class AppConstants {
  /// Adresse de l'API. Par défaut le serveur SOFARY ; pour un autre serveur :
  /// flutter build apk --dart-define=API_URL=https://autre-domaine/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://sofary-gmao.duckdns.org/api',
  );
  static const String appName = 'SOFARY';
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userCacheKey    = 'user_cache';

  /// Adresse complète d'un fichier envoyé (photo…) à partir du chemin renvoyé par l'API.
  static String urlFichier(String? chemin) {
    if (chemin == null || chemin.isEmpty) return '';
    if (chemin.startsWith('http')) return chemin;
    return baseUrl.replaceFirst(RegExp(r'/api/?$'), '') + chemin;
  }
}
