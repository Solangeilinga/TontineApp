// lib/models/group.dart
class Group {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final int frequencyValue;
  final String frequencyUnit; // DAYS | WEEKS | MONTHS
  final double amount;
  final String currency;
  final String? description;
  final String inviteCode;
  final bool isActive;
  final bool isFull;
  final int? maxMembers;
  final DateTime createdAt;
  final int? memberCount;

  const Group({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.frequencyValue,
    required this.frequencyUnit,
    required this.amount,
    required this.currency,
    this.description,
    required this.inviteCode,
    required this.isActive,
    this.isFull = false,
    this.maxMembers,
    required this.createdAt,
    this.memberCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        tenantId: json['tenantId'],
        name: json['name'],
        type: json['type'],
        frequencyValue: json['frequencyValue'] ?? 1,
        frequencyUnit: json['frequencyUnit'] ?? 'MONTHS',
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] ?? 'XOF',
        description: json['description'],
        inviteCode: json['inviteCode'],
        isActive: json['isActive'] ?? true,
        isFull: json['isFull'] ?? false,
        maxMembers: json['maxMembers'],
        createdAt: DateTime.parse(json['createdAt']),
        memberCount: json['_count']?['groupMembers'],
      );

  // V1 — Argent uniquement
  String get typeLabel => 'Argent';

  String get frequencyUnitLabel {
    switch (frequencyUnit) {
      case 'DAYS':
        return frequencyValue == 1 ? 'jour' : 'jours';
      case 'WEEKS':
        return frequencyValue == 1 ? 'semaine' : 'semaines';
      case 'MONTHS':
      default:
        return frequencyValue == 1 ? 'mois' : 'mois';
    }
  }

  // Ex: "Tous les 5 jours" / "Tous les mois"
  String get frequencyLabel => 'Tous les $frequencyValue $frequencyUnitLabel';

  // Durée en jours d'un intervalle (approximation pour les mois : 30 jours,
  // utilisée uniquement pour des estimations d'affichage côté client — le
  // calcul faisant foi est toujours effectué côté serveur).
  int get frequencyDaysApprox {
    switch (frequencyUnit) {
      case 'DAYS':
        return frequencyValue;
      case 'WEEKS':
        return frequencyValue * 7;
      case 'MONTHS':
      default:
        return frequencyValue * 30;
    }
  }
}