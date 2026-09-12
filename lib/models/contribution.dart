// lib/models/contribution.dart
import 'member.dart';

class Contribution {
  final String id;
  final String groupId;
  final String userId;
  final int roundNumber;
  final String status;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? note;
  final Member? user;
  final bool serverIsLate;

  const Contribution({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.roundNumber,
    required this.status,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.note,
    this.user,
    this.serverIsLate = false,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
        id: json['id'],
        groupId: json['groupId'],
        userId: json['userId'],
        roundNumber: json['roundNumber'] ?? 1,
        status: json['status'],
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate']),
        paidDate:
            json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
        note: json['note'],
        user: json['user'] != null ? Member.fromJson(json['user']) : null,
        serverIsLate: json['isLate'] ?? false,
      );

  String get statusLabel {
    const labels = {
      'PENDING': 'En attente',
      'RECEIVED': 'Reçue',
      'LATE': 'En retard',
    };
    return labels[status] ?? status;
  }

  bool get isPending => status == 'PENDING';
  bool get isReceived => status == 'RECEIVED';
  bool get isLate => status == 'LATE' || serverIsLate;
}
