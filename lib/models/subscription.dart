// lib/models/subscription.dart

/// Représente l'abonnement du gérant connecté, tel que renvoyé par
/// GET /api/subscriptions/me. `effectivePlan` tient déjà compte de
/// l'expiration côté backend — c'est TOUJOURS lui qu'il faut utiliser pour
/// l'affichage, jamais `plan` seul (qui peut être un plan payant expiré).
class TenantSubscription {
  final String
      plan; // FREE | STARTER | PRO (brut, sans tenir compte de l'expiration)
  final String status; // ACTIVE | PAST_DUE | CANCELED
  final DateTime? currentPeriodEnd;
  final bool isValid;
  final String
      effectivePlan; // FREE | STARTER | PRO (à utiliser pour l'affichage)
  final bool canReactivate;
  final Map<String, dynamic> limits;

  const TenantSubscription({
    required this.plan,
    required this.status,
    this.currentPeriodEnd,
    required this.isValid,
    required this.effectivePlan,
    required this.canReactivate,
    required this.limits,
  });

  factory TenantSubscription.fromJson(Map<String, dynamic> json) =>
      TenantSubscription(
        plan: json['plan'] ?? 'FREE',
        status: json['status'] ?? 'ACTIVE',
        currentPeriodEnd: json['currentPeriodEnd'] != null
            ? DateTime.parse(json['currentPeriodEnd'])
            : null,
        isValid: json['isValid'] ?? true,
        effectivePlan: json['effectivePlan'] ?? 'FREE',
        canReactivate: json['canReactivate'] ?? false,
        limits: Map<String, dynamic>.from(json['limits'] ?? {}),
      );

  bool get isFree => effectivePlan == 'FREE';
  bool get isCanceledButActive => status == 'CANCELED' && isValid;
  bool get isPastDue => status == 'PAST_DUE';
}

/// Description statique d'un plan (prix, libellé, limites) — miroir de
/// src/config/plans.js côté backend. Utilisé pour construire les cartes de
/// choix sur l'écran d'abonnement.
class PlanInfo {
  final String key; // FREE | STARTER | PRO
  final String label;
  final int amount; // en FCFA
  final List<String> features;
  final bool highlighted;

  const PlanInfo({
    required this.key,
    required this.label,
    required this.amount,
    required this.features,
    this.highlighted = false,
  });

  static const List<PlanInfo> all = [
    PlanInfo(
      key: 'FREE',
      label: 'Gratuit',
      amount: 0,
      features: [
        '1 groupe',
        'Jusqu\'à 8 membres par groupe',
      ],
    ),
    PlanInfo(
      key: 'STARTER',
      label: 'Starter',
      amount: 499,
      features: [
        'Groupes illimités',
        'Jusqu\'à 20 membres par groupe',
        'Rappels automatiques',
      ],
    ),
    PlanInfo(
      key: 'PRO',
      label: 'Pro',
      amount: 900,
      highlighted: true,
      features: [
        'Groupes et membres illimités',
        'Export CSV des cotisations',
        'Journal d\'audit complet',
      ],
    ),
  ];
}
