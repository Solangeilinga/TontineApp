// lib/models/tenant.dart
class Tenant {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;

  const Tenant({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        photoUrl: json['photoUrl'],
      );
}
