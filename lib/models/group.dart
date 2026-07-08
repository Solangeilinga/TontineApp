// lib/models/group.dart
class Group {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final String frequency;
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
    required this.frequency,
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
        frequency: json['frequency'],
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

  // Fréquence = description si disponible, sinon fréquence brute
  String get frequencyLabel {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    switch (frequency) {
      case 'WEEKLY': return 'Hebdomadaire';
      case 'MONTHLY': return 'Mensuelle';
      default: return 'Personnalisée';
    }
  }
}
