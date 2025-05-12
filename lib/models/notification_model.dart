class NotificationModel {
  final int notificationId;
  final String title;
  final String message;
  final DateTime sentDateTime;
  final bool isRead;
  final bool isImportant;
  final String senderName; // Staff name who sent the notification
  final String? senderProfileImageUrl;
  final String? senderRole; // Staff role (Admin, Dean, HOD, etc.)
  final String? senderFaculty; // Faculty the sender belongs to
  final String? senderEmail; // Sender's email address
  final DateTime? readDateTime;
  final int categoryId;
  final String categoryName;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.sentDateTime,
    required this.isRead,
    required this.isImportant,
    required this.senderName,
    this.senderProfileImageUrl,
    this.senderRole,
    this.senderFaculty,
    this.senderEmail,
    this.readDateTime,
    required this.categoryId,
    required this.categoryName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      title: json['title'],
      message: json['message'],
      sentDateTime: DateTime.parse(json['sentDateTime']),
      isRead: json['isRead'] ?? false,
      isImportant: json['isImportant'] ?? false,
      senderName: json['senderName'] ?? 'University Admin',
      senderProfileImageUrl: json['senderProfileImageUrl'],
      senderRole: json['senderRole'],
      senderFaculty: json['senderFaculty'],
      senderEmail: json['senderEmail'],
      readDateTime: json['readDateTime'] != null ? 
          DateTime.parse(json['readDateTime']) : null,
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? 'Uncategorized',
    );
  }
}