import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../utils/navigator_key.dart';

enum _RefreshResult { success, authFailed, networkError }

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // Renouvellement en cours : les requêtes qui reçoivent un 401 en même temps l'attendent
  Future<_RefreshResult>? _refreshEnCours;

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
        final opts = error.requestOptions;
        final dejaRejouee = opts.extra['rejouee'] == true;
        if (error.response?.statusCode == 401 && !dejaRejouee && !opts.path.contains('/auth/login') && !opts.path.contains('/auth/refresh')) {
          final envoye = opts.headers['Authorization'] as String?;
          final actuel = await _storage.read(key: AppConstants.tokenKey);

          // Jeton déjà renouvelé par une autre requête : on rejoue simplement
          var result = _RefreshResult.success;
          if (actuel == null || envoye == 'Bearer $actuel') {
            result = await (_refreshEnCours ??= _refreshToken().whenComplete(() => _refreshEnCours = null));
          }

          if (result == _RefreshResult.success) {
            final token = await _storage.read(key: AppConstants.tokenKey);
            opts.headers['Authorization'] = 'Bearer $token';
            opts.extra['rejouee'] = true;
            try {
              final retry = await _dio.fetch(opts);
              return handler.resolve(retry);
            } on DioException catch (e) {
              return handler.next(e);
            }
          } else if (result == _RefreshResult.authFailed) {
            // Renouvellement explicitement refusé par le serveur → déconnexion
            await _storage.deleteAll();
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
          }
          // _RefreshResult.networkError → on laisse passer l'erreur
          // sans supprimer les jetons (l'utilisateur reste connecté)
        }
        handler.next(error);
      },
    ));
  }

  Future<_RefreshResult> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null) return _RefreshResult.authFailed;
      final res = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refresh'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      await _storage.write(key: AppConstants.tokenKey, value: res.data['accessToken']);
      // Le serveur fait tourner le refresh token : il faut garder le nouveau
      final nouveauRefresh = res.data['refreshToken'];
      if (nouveauRefresh is String && nouveauRefresh.isNotEmpty) {
        await _storage.write(key: AppConstants.refreshTokenKey, value: nouveauRefresh);
      }
      return _RefreshResult.success;
    } on DioException catch (e) {
      // 401/403 du serveur = session vraiment invalide
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) return _RefreshResult.authFailed;
      // Erreur réseau / timeout / serveur indisponible = ne pas déconnecter
      return _RefreshResult.networkError;
    } catch (_) {
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
