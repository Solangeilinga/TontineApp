// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'pin_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final PinService _pin = PinService();

  Dio get _dio => _api.dio;

  // ── GÉRANT ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> tenantRequestOTP({
    required String phone,
    required String name,
  }) async {
    final res = await _dio.post('/auth/tenant/register/request-otp', data: {
      'phone': phone,
      'name': name,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> tenantVerifyAndRegister({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/tenant/register/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> tenantLoginRequestOTP(String phone) async {
    final res = await _dio.post('/auth/tenant/login/request-otp', data: {
      'phone': phone,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> tenantLoginVerify({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/tenant/login/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    return res.data;
  }

  // ── MEMBRE ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> memberJoinRequestOTP({
    required String phone,
    required String name,
    required String inviteCode,
  }) async {
    final res = await _dio.post('/auth/member/join/request-otp', data: {
      'phone': phone,
      'name': name,
      'inviteCode': inviteCode,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> memberJoinVerify({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/member/join/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> memberLoginRequestOTP(String phone) async {
    final res = await _dio.post('/auth/member/login/request-otp', data: {
      'phone': phone,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> memberLoginVerify({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/member/login/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    return res.data;
  }

  /// À appeler quand memberLoginVerify a renvoyé `requiresSelection: true`
  /// (le numéro est membre chez plusieurs gérants) — finalise la connexion
  /// pour l'espace (tenantId) choisi par l'utilisateur.
  Future<Map<String, dynamic>> memberLoginSelectSpace({
    required String selectionToken,
    required String tenantId,
  }) async {
    final res = await _dio.post('/auth/member/login/select-space', data: {
      'selectionToken': selectionToken,
      'tenantId': tenantId,
    });
    return res.data;
  }

  // ── Après connexion SMS : décider où aller ────────────────────────────────
  // On vient de s'authentifier par SMS → pas de pin-login
  // Si PIN déjà défini → home directement
  // Si pas de PIN → créer un PIN
  Future<String> getPostLoginRoute(String userType) async {
    try {
      final hasPin = await _pin.isPinSet(userType);
      if (hasPin) {
        // PIN déjà défini → home directement (pas besoin de re-saisir)
        if (userType == 'tenant') return '/gerant/home';
        return '/membre/home';
      } else {
        // Pas encore de PIN → créer un PIN
        return '/set-pin/$userType';
      }
    } catch (_) {
      return '/set-pin/$userType';
    }
  }

  // ── DÉCONNEXION ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _api.clearTokens();
    await _pin.clearPinCache();
  }
}