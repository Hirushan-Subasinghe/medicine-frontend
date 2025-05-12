class NotificationCategory {
  final int categoryId;
  final String categoryName;

  NotificationCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory NotificationCategory.fromJson(Map<String, dynamic> json) {
    return NotificationCategory(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
    );
  }
}