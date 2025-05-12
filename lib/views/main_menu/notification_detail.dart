import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../core/constants.dart';
import '../../controllers/notification_controller.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({Key? key, required this.notification}) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final NotificationController _notificationController = NotificationController();
  late bool _isRead;
  late NotificationModel _notification;
  
  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _isRead = _notification.isRead;
    
    // If the notification is not marked as read, mark it as read
    if (!_isRead) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    try {
      bool success = await _notificationController.markAsRead(_notification.notificationId);
      if (success && mounted) {
        setState(() {
          _isRead = true;
          // Create a new notification object with updated read status
          _notification = NotificationModel(
            notificationId: _notification.notificationId,
            title: _notification.title,
            message: _notification.message,
            sentDateTime: _notification.sentDateTime,
            isRead: true,
            isImportant: _notification.isImportant,
            senderName: _notification.senderName,
            senderProfileImageUrl: _notification.senderProfileImageUrl,
            senderRole: _notification.senderRole,
            senderFaculty: _notification.senderFaculty,
            senderEmail: _notification.senderEmail,
            readDateTime: DateTime.now(),
            categoryId: _notification.categoryId,
            categoryName: _notification.categoryName,
          );
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Return the updated notification model to update the list
            Navigator.of(context).pop(_notification);
          },
        ),
        title: Text('Notification Details', style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(_isRead ? Icons.mark_email_unread : Icons.mark_email_read),
                      title: Text(_isRead ? 'Mark as unread' : 'Mark as read'),
                      onTap: () {
                        if (!_isRead) {
                          _markAsRead();
                        } // For now, we only support marking as read
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.primaryColor.withOpacity(0.05), // Light tint of theme color
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main content card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender info with avatar
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                                backgroundImage: widget.notification.senderProfileImageUrl != null
                                    ? NetworkImage(widget.notification.senderProfileImageUrl!)
                                    : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.notification.senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(widget.notification.sentDateTime),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.notification.isImportant)
                                Icon(Icons.star, color: Colors.amber, size: 20),
                            ],
                          ),
                        ),

                        // Title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            widget.notification.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // Message content
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            widget.notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),

                        SizedBox(height: 20),
                        
                        // Divider between message content and sender details
                        Divider(color: Colors.grey[300]),
                        
                        // Sender details at bottom left
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side - sender details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sender',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    _buildSenderInfoRow('Name', widget.notification.senderName),
                                    if (widget.notification.senderRole != null)
                                      _buildSenderInfoRow('Role', widget.notification.senderRole!),
                                    if (widget.notification.senderFaculty != null)
                                      _buildSenderInfoRow('Faculty', widget.notification.senderFaculty!),
                                    if (widget.notification.senderEmail != null)
                                      _buildSenderInfoRow('Email', widget.notification.senderEmail!),
                                  ],
                                ),
                              ),
                              // Right side - read status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isRead ? Icons.visibility : Icons.visibility_off,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _isRead
                                            ? widget.notification.readDateTime != null
                                                ? "Read on ${_formatDateTime(widget.notification.readDateTime!)}"
                                                : "Read"
                                            : "Not read yet",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tags at the bottom
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (widget.notification.isImportant)
                      _buildTag('Important', AppColors.primaryColor),
                    _buildTag(_isRead ? 'Read' : 'Unread', AppColors.primaryColor),
                    _buildTag(widget.notification.categoryName, AppColors.primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
      padding: EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}