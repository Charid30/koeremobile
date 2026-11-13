import 'package:dio/dio.dart';

/// Transforme n'importe quelle exception en message utilisateur lisible en français.
class AppError {
  final String message;
  final bool isNetwork;
  final bool isAuth;
  final int? statusCode;

  const AppError({
    required this.message,
    this.isNetwork = false,
    this.isAuth = false,
    this.statusCode,
  });

  @override
  String toString() => message;
}

AppError parseError(Object e) {
  if (e is AppError) return e;
  if (e is DioException) return _fromDio(e);
  return AppError(message: e.toString());
}

AppError _fromDio(DioException e) {
  // Pas de réseau
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.unknown) {
    return const AppError(
      message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      isNetwork: true,
    );
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const AppError(
      message: 'Le serveur met trop de temps à répondre. Réessayez.',
      isNetwork: true,
    );
  }

  final code = e.response?.statusCode;
  final data = e.response?.data;

  // Essayer d'extraire le message du backend NestJS
  String? backendMsg = _extractBackendMessage(data);

  return switch (code) {
    400 => AppError(message: backendMsg ?? 'Données invalides. Vérifiez les champs.', statusCode: 400),
    401 => AppError(message: 'Session expirée. Veuillez vous reconnecter.', isAuth: true, statusCode: 401),
    403 => AppError(message: 'Accès refusé. Vous n\'avez pas les droits nécessaires.', statusCode: 403),
    404 => AppError(message: backendMsg ?? 'Ressource introuvable.', statusCode: 404),
    409 => AppError(message: backendMsg ?? 'Cet enregistrement existe déjà (doublon).', statusCode: 409),
    422 => AppError(message: backendMsg ?? 'Données invalides.', statusCode: 422),
    _ when (code ?? 0) >= 500 => AppError(message: 'Erreur interne du serveur. Réessayez plus tard.', statusCode: code),
    _ => AppError(message: backendMsg ?? 'Une erreur inattendue s\'est produite.', statusCode: code),
  };
}

String? _extractBackendMessage(dynamic data) {
  if (data == null) return null;
  if (data is Map) {
    // NestJS class-validator renvoie { message: [...] }
    final msg = data['message'];
    if (msg is List && msg.isNotEmpty) {
      return _translateValidationMsg(msg.first.toString());
    }
    if (msg is String && msg.isNotEmpty) return msg;

    final err = data['error'];
    if (err is String && err.isNotEmpty) return err;
  }
  return null;
}

/// Traduit les messages de validation NestJS courants en français.
String _translateValidationMsg(String msg) {
  final translations = <String, String>{
    'must be a string': 'doit être une chaîne de caractères',
    'must not be empty': 'ne doit pas être vide',
    'must be an integer': 'doit être un nombre entier',
    'must be a number': 'doit être un nombre',
    'must be a valid email': 'doit être un email valide',
    'must be one of the following values': 'valeur non reconnue',
    'must be a Date': 'doit être une date valide',
    'must not be less than': 'ne doit pas être inférieur à',
    'should not be empty': 'ne doit pas être vide',
    'is not valid': 'n\'est pas valide',
    'already exists': 'existe déjà',
  };
  for (final entry in translations.entries) {
    if (msg.toLowerCase().contains(entry.key)) return entry.value;
  }
  return msg;
}
