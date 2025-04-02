class NotificationModel {
  final int notificationId;
  final String title;
  final String message;
  final DateTime sentDateTime;
  final bool isRead;
  final bool isImportant;
  final bool isSpam;
  final String senderName; // Could be department or staff name

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.sentDateTime,
    required this.isRead,
    required this.isImportant,
    required this.isSpam,
    required this.senderName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      title: json['title'],
      message: json['message'],
      sentDateTime: DateTime.parse(json['sentDateTime']),
      isRead: json['isRead'] ?? false,
      isImportant: json['isImportant'] ?? false,
      isSpam: json['isSpam'] ?? false,
      senderName: json['senderName'] ?? 'University Admin',
    );
  }
}