import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;
  final _storage = const FlutterSecureStorage();

  AuthService(this._api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api.post('/auth/login', data: {'email': email, 'motDePasse': password});
    final data = res.data as Map<String, dynamic>;
    await _storage.write(key: AppConstants.tokenKey, value: data['accessToken']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
    // Cacher le profil pour restauration sans réseau
    final user = data['user'];
    if (user != null) {
      await _storage.write(key: AppConstants.userCacheKey, value: jsonEncode(user));
    }
    return data;
  }

  Future<void> logout() async {
    // Ferme la session côté serveur (sans bloquer si le réseau est coupé)
    try {
      await _api.post('/auth/logout').timeout(const Duration(seconds: 5));
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null;
  }

  // Retourne le profil depuis le cache local (aucune requête réseau)
  Future<Map<String, dynamic>?> getCachedUser() async {
    final raw = await _storage.read(key: AppConstants.userCacheKey);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  // Rafraîchit le profil depuis l'API et met à jour le cache
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await _api.get('/auth/profil');
      final user = res.data as Map<String, dynamic>;
      await _storage.write(key: AppConstants.userCacheKey, value: jsonEncode(user));
      return user;
    } catch (_) {
      return null;
    }
  }
}
