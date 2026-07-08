// lib/models/member.dart
class Member {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final String? photoUrl;
  final int? orderTurn;

  const Member({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.orderTurn,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        tenantId: json['tenantId'],
        name: json['name'],
        phone: json['phone'],
        photoUrl: json['photoUrl'],
        orderTurn: json['orderTurn'],
      );
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final int orderTurn;
  final DateTime joinedAt;
  final Member user;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.orderTurn,
    required this.joinedAt,
    required this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'],
        groupId: json['groupId'],
        userId: json['userId'],
        orderTurn: json['orderTurn'],
        joinedAt: DateTime.parse(json['joinedAt']),
        user: Member.fromJson(json['user']),
      );
}
