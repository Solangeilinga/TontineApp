// lib/services/onboarding_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sait si le gérant a déjà vu l'écran d'onboarding (présentation de
/// l'appli + des forfaits). Stocké localement, par appareil — un gérant qui
/// change de téléphone le reverra une fois, ce qui est acceptable.
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _seenKey = 'onboarding_seen';

  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _seenKey);
    return value == 'true';
  }

  Future<void> markOnboardingSeen() async {
    await _storage.write(key: _seenKey, value: 'true');
  }
}