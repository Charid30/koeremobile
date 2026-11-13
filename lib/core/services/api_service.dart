import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../utils/navigator_key.dart';

enum _RefreshResult { success, authFailed, networkError }

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // Guard pour éviter de lancer plusieurs refreshs simultanément
  bool _refreshing = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_refreshing) {
          final result = await _refreshToken();

          if (result == _RefreshResult.success) {
            // Retry de la requête originale avec le nouveau token
            final token = await _storage.read(key: AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final retry = await _dio.fetch(error.requestOptions);
              return handler.resolve(retry);
            } catch (_) {}
          } else if (result == _RefreshResult.authFailed) {
            // Token refresh explicitement refusé par le serveur → déconnexion
            await _storage.deleteAll();
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
          }
          // _RefreshResult.networkError → on laisse passer l'erreur 401
          // sans supprimer les tokens (l'utilisateur reste connecté)
        }
        handler.next(error);
      },
    ));
  }

  Future<_RefreshResult> _refreshToken() async {
    _refreshing = true;
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null) {
        _refreshing = false;
        return _RefreshResult.authFailed;
      }
      final res = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      await _storage.write(key: AppConstants.tokenKey, value: res.data['accessToken']);
      _refreshing = false;
      return _RefreshResult.success;
    } on DioException catch (e) {
      _refreshing = false;
      // 401/403 du serveur = token vraiment invalide
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) return _RefreshResult.authFailed;
      // Erreur réseau / timeout = ne pas déconnecter
      return _RefreshResult.networkError;
    } catch (_) {
      _refreshing = false;
      return _RefreshResult.networkError;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
