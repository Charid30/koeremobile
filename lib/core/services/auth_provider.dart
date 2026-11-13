import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'api_service.dart';
import '../utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService(ApiService());

  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return;

    // 1. Restauration instantanée depuis le cache (pas de réseau requis)
    _user = await _authService.getCachedUser();
    if (_user != null) notifyListeners();

    // 2. Rafraîchissement en arrière-plan pour mettre à jour le profil
    _authService.getProfile().then((fresh) {
      if (fresh != null && _user != null) {
        _user = fresh;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _authService.login(email, password);
      _user = data['user'] as Map<String, dynamic>?;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final appErr = parseError(e);
      _error = appErr.statusCode == 401
          ? 'Email ou mot de passe incorrect.'
          : appErr.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }
}
