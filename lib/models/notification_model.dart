// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        message: json['message'],
        isRead: json['isRead'] ?? false,
        sentAt: DateTime.parse(json['sentAt']),
      );
}
