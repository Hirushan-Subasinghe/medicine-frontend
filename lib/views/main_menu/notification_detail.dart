// lib/views/main_menu/notification_detail.dart
import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../core/constants.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Details'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sender info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _formatDate(notification.sentDateTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.isImportant)
                  Icon(Icons.star, color: Colors.amber),
              ],
            ),

            Divider(height: 32),

            // Title
            Text(
              notification.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // Message content
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            SizedBox(height: 24),

            // Tags/Status
            Wrap(
              spacing: 8,
              children: [
                if (notification.isImportant)
                  _buildTag('Important', Colors.amber),
                if (notification.isSpam)
                  _buildTag('Spam', Colors.red[300]!),
                _buildTag(notification.isRead ? 'Read' : 'Unread',
                    notification.isRead ? Colors.grey : AppColors.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}