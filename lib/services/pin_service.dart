// lib/services/pin_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final _api = ApiService();

  static const _pinSetKey = 'pin_is_set';
  static const _phoneKey = 'user_phone';

  // ── Sauvegarder le numéro pour PIN verrouillé
  Future<void> savePhone(String phone) async {
    await _storage.write(key: _phoneKey, value: phone);
  }

  Future<String?> getPhone() async {
    return await _storage.read(key: _phoneKey);
  }

  // ── Vérification locale rapide (sans appel API)
  Future<bool> isPinSetLocally() async {
    final val = await _storage.read(key: _pinSetKey);
    return val == 'true';
  }

  // ── Vérification via API + mise à jour cache local
  Future<bool> isPinSet(String userType) async {
    try {
      final endpoint = userType == 'tenant'
          ? '/auth/tenant/pin/status'
          : '/auth/member/pin/status';
      final res = await _api.dio.get(endpoint);
      final hasPin = res.data['data']['hasPin'] as bool;
      await _storage.write(key: _pinSetKey, value: hasPin ? 'true' : 'false');
      return hasPin;
    } catch (_) {
      final val = await _storage.read(key: _pinSetKey);
      return val == 'true';
    }
  }

  // ── Vérifier PIN en session verrouillée (sans token)
  Future<Map<String, dynamic>?> verifyPinLocked(
      String pin, String userType) async {
    try {
      final phone = await getPhone();
      if (phone == null) return null;

      final endpoint = userType == 'tenant'
          ? '/auth/tenant/pin/verify-locked'
          : '/auth/member/pin/verify-locked';

      final res = await _api.dioNoAuth.post(endpoint, data: {
        'phone': phone,
        'pin': pin,
      });
      return res.data['data'];
    } catch (_) {
      return null;
    }
  }

  // ── Vérifier PIN en session active (avec token)
  Future<bool> verifyPin(String pin, String userType) async {
    try {
      final endpoint = userType == 'tenant'
          ? '/auth/tenant/pin/verify'
          : '/auth/member/pin/verify';
      await _api.dio.post(endpoint, data: {'pin': pin});
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Sauvegarder PIN via API + cache local
  Future<void> savePin(String pin, String userType) async {
    final endpoint = userType == 'tenant'
        ? '/auth/tenant/pin/set'
        : '/auth/member/pin/set';
    await _api.dio.post(endpoint, data: {'pin': pin});
    await _storage.write(key: _pinSetKey, value: 'true');
  }

  // ── Reset cache PIN (déconnexion totale)
  Future<void> clearPinCache() async {
    await _storage.write(key: _pinSetKey, value: 'false');
  }
}