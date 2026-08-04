// lib/services/pin_service.dart
import 'package:dio/dio.dart';
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
  static const _userIdKey = 'user_id';

  // ── Sauvegarder le numéro pour PIN verrouillé
  Future<void> savePhone(String phone) async {
    await _storage.write(key: _phoneKey, value: phone);
  }

  Future<String?> getPhone() async {
    return await _storage.read(key: _phoneKey);
  }

  // ── Sauvegarder l'identifiant du compte précis (gérant ou membre) pour
  // lever toute ambiguïté au déverrouillage — essentiel quand un même
  // numéro est membre chez plusieurs gérants (cf. userVerifyPinLocked côté
  // backend, qui sinon devrait deviner via le téléphone seul).
  Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
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
  //
  // Retourne :
  //  - Map<String,dynamic> si le PIN est correct (tokens à sauvegarder)
  //  - null si le PIN est VRAIMENT incorrect (401 du backend)
  //  - lève une exception pour toute autre erreur (réseau, serveur down,
  //    timeout...) — l'appelant NE DOIT PAS afficher "code incorrect" dans
  //    ce cas, mais un message distinct, sinon un simple souci réseau se
  //    fait passer pour un mauvais code PIN et ronge les tentatives.
  Future<Map<String, dynamic>?> verifyPinLocked(
      String pin, String userType) async {
    final phone = await getPhone();
    if (phone == null) return null;
    final userId = userType == 'user' ? await getUserId() : null;

    try {
      final endpoint = userType == 'tenant'
          ? '/auth/tenant/pin/verify-locked'
          : '/auth/member/pin/verify-locked';

      final res = await _api.dioNoAuth.post(endpoint, data: {
        'phone': phone,
        'pin': pin,
        if (userId != null) 'userId': userId,
      });
      return res.data['data'];
    } on DioException catch (e) {
      // 401 = le backend a explicitement dit "PIN incorrect" — c'est le
      // SEUL cas où on retourne null (vrai mauvais code).
      if (e.response?.statusCode == 401) return null;
      // Tout le reste (pas de réponse, timeout, 500, 429...) doit remonter
      // pour être affiché distinctement par l'écran appelant.
      rethrow;
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