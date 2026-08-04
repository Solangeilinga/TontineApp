// lib/services/subscription_service.dart
import 'package:dio/dio.dart';
import '../models/subscription.dart';
import 'api_service.dart';

class SubscriptionService {
  final ApiService _api = ApiService();
  Dio get _dio => _api.dio;

  Future<TenantSubscription> getMySubscription() async {
    final res = await _dio.get('/subscriptions/me');
    return TenantSubscription.fromJson(res.data['data']);
  }

  /// Liste des opérateurs Mobile Money autorisés (Orange/Moov, filtré côté
  /// serveur). Sans `country`, retourne TOUS les opérateurs autorisés, tous
  /// pays confondus — pratique pour dériver dynamiquement la liste des pays
  /// supportés sans avoir à la coder en dur côté app (SebPay ajoute des
  /// pays régulièrement).
  Future<List<Map<String, dynamic>>> getOperators({String? country}) async {
    final res = await _dio.get('/subscriptions/operators',
        queryParameters: country != null ? {'country': country} : null);
    final list = res.data['data'] as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Initie le paiement d'un abonnement. Renvoie la référence externe
  /// (utile pour un éventuel suivi manuel/support) — le statut réel arrive
  /// par push une fois le webhook SebPay traité côté backend.
  Future<Map<String, dynamic>> subscribe({
    required String plan, // STARTER | PRO
    required String phone,
    required String operator,
    String country = 'BJ',
    String? otpCode,
  }) async {
    final res = await _dio.post('/subscriptions/subscribe', data: {
      'plan': plan,
      'phone': phone,
      'operator': operator,
      'country': country,
      if (otpCode != null) 'otpCode': otpCode,
    });
    return res.data['data'] ?? {};
  }

  /// Annule l'abonnement. Par défaut : accès conservé jusqu'à la fin de la
  /// période déjà payée. `immediate: true` bascule tout de suite en Gratuit
  /// (sans remboursement du reliquat).
  Future<String> cancel({bool immediate = false}) async {
    final res = await _dio.post('/subscriptions/cancel', data: {
      'immediate': immediate,
    });
    return res.data['message'] ?? 'Abonnement annulé.';
  }

  /// Réactive un abonnement annulé tant que la période payée n'est pas
  /// terminée (annule l'annulation, en somme).
  Future<String> reactivate() async {
    final res = await _dio.post('/subscriptions/reactivate');
    return res.data['message'] ?? 'Abonnement réactivé.';
  }
}