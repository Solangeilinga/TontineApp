// lib/services/profile_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();
  Dio get _dio => _api.dio;

  // ── GÉRANT ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTenantProfile() async {
    final res = await _dio.get('/auth/tenant/me');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateTenantProfile({
    required String name,
    String? photoUrl,
  }) async {
    final res = await _dio.put('/auth/tenant/profile', data: {
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return res.data['data'];
  }

  /// Étape 1/2 : envoie un code par SMS au NOUVEAU numéro (pas à l'ancien).
  Future<void> tenantChangePhoneRequestOtp(String newPhone) async {
    await _dio.post('/auth/tenant/phone/request-otp', data: {'newPhone': newPhone});
  }

  /// Étape 2/2 : applique le changement si le code est correct. Notifie
  /// automatiquement tous les membres côté backend.
  Future<Map<String, dynamic>> tenantChangePhoneVerify({
    required String newPhone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/tenant/phone/verify', data: {
      'newPhone': newPhone,
      'otp': otp,
    });
    return res.data['data'];
  }

  /// Suppression définitive du compte gérant, confirmée par PIN. Notifie
  /// automatiquement tous les membres côté backend.
  Future<void> deleteTenantAccount(String pin) async {
    await _dio.post('/auth/tenant/account/delete', data: {'pin': pin});
  }

  // ── MEMBRE ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMemberProfile() async {
    final res = await _dio.get('/auth/member/me');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateMemberProfile({
    required String name,
    String? photoUrl,
  }) async {
    final res = await _dio.put('/auth/member/profile', data: {
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    return res.data['data'];
  }

  /// Étape 1/2 : envoie un code par SMS au NOUVEAU numéro.
  Future<void> memberChangePhoneRequestOtp(String newPhone) async {
    await _dio.post('/auth/member/phone/request-otp', data: {'newPhone': newPhone});
  }

  /// Étape 2/2 : applique le changement si le code est correct. Notifie
  /// automatiquement le gérant et les co-membres côté backend.
  Future<Map<String, dynamic>> memberChangePhoneVerify({
    required String newPhone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/member/phone/verify', data: {
      'newPhone': newPhone,
      'otp': otp,
    });
    return res.data['data'];
  }

  /// Suppression définitive du compte membre (uniquement chez ce gérant),
  /// confirmée par PIN. Notifie automatiquement le gérant côté backend.
  Future<void> deleteMemberAccount(String pin) async {
    await _dio.post('/auth/member/account/delete', data: {'pin': pin});
  }
}