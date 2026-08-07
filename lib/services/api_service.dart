// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  late final Dio dio;
  late final Dio dioNoAuth; // ← Sans token — pour PIN verrouillé

  // Mutex simple : si plusieurs requêtes échouent en 401 au même moment,
  // on ne déclenche qu'UN seul appel réseau de refresh, partagé par toutes.
  Future<String?>? _refreshFuture;

  void init() {
    // ── Dio avec token d'authentification
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auparavant : un refreshToken était généré et stocké, mais jamais
        // utilisé — tout 401 verrouillait direct la session (retour PIN),
        // même quand un refresh silencieux aurait suffi. On tente
        // maintenant un vrai refresh avant de verrouiller, en évitant :
        //  - de boucler si c'est l'appel /auth/refresh lui-même qui échoue
        //  - de tenter deux refresh en parallèle pour deux requêtes 401
        //    simultanées (mutex via _refreshFuture)
        final isRefreshCall = error.requestOptions.path.contains('/auth/refresh');
        if (error.response?.statusCode == 401 && !isRefreshCall) {
          final refreshed = await _refreshAccessToken();
          if (refreshed != null) {
            try {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $refreshed';
              final response = await dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (_) {
              // La requête rejouée échoue encore → on tombe dans le
              // verrouillage de session ci-dessous.
            }
          }
          await lockSession();
        }
        handler.next(error);
      },
    ));

    // ── Dio sans token — pour les endpoints PIN verrouillé
    dioNoAuth = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userType,
  }) async {
    await _storage.write(
        key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: AppConstants.refreshTokenKey, value: refreshToken);
    await _storage.write(key: AppConstants.userTypeKey, value: userType);
  }

  // ── Verrouiller session (garde userType et pin_is_set)
  Future<void> lockSession() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  // ── Déconnexion totale
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<String?> getUserType() =>
      _storage.read(key: AppConstants.userTypeKey);

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Rafraîchit l'access token via le refresh token stocké.
  // Retourne le nouvel access token si succès, null sinon (refresh token
  // absent, expiré, ou compte désactivé — dans tous ces cas l'appelant doit
  // verrouiller la session).
  Future<String?> _refreshAccessToken() {
    // Réutilise l'appel en cours plutôt que d'en lancer un second en
    // parallèle si plusieurs requêtes échouent au même instant.
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _doRefresh() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return null;

      // dioNoAuth : ne doit PAS embarquer l'ancien (expiré) access token.
      final response = await dioNoAuth.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
      await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}