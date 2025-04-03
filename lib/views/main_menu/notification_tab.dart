import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import 'notification_detail.dart';

class NotificationTab extends StatefulWidget {
  @override
  _NotificationTabState createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  final NotificationController _notificationController = NotificationController();

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  List<NotificationModel> _importantNotifications = [];
  List<NotificationModel> _spamNotifications = [];

  bool _isLoading = true;
  bool _firstLoadDone = false;
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['All', 'Unread', 'Important', 'Spam'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_firstLoadDone) {
      _loadTabData(_selectedTabIndex);
      _loadUnreadNotifications(); // preload badge
      _firstLoadDone = true;
    }
  }

  Future<void> _loadTabData(int index) async {
    setState(() => _isLoading = true);
    try {
      switch (index) {
        case 0:
          await _loadAllNotifications();
          break;
        case 1:
          await _loadUnreadNotifications();
          break;
        case 2:
          await _loadImportantNotifications();
          break;
        case 3:
          await _loadSpamNotifications();
          break;
      }
    } catch (e) {
      print('Error loading tab data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllNotifications() async {
    try {
      _allNotifications = await _notificationController.getAllNotifications();
    } catch (e) {
      print('Error loading all notifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      _unreadNotifications = await _notificationController.getUnreadNotifications();
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  Future<void> _loadImportantNotifications() async {
    try {
      _importantNotifications = await _notificationController.getImportantNotifications();
    } catch (e) {
      print('Error loading important notifications: $e');
    }
  }

  Future<void> _loadSpamNotifications() async {
    try {
      _spamNotifications = await _notificationController.getSpamNotifications();
    } catch (e) {
      print('Error loading spam notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 25)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: AppColors.primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedTabIndex = index);
                    await _loadTabData(index);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.activeTabBackground
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _tabs[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (index == 1 && _unreadNotifications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _unreadNotifications.length.toString(),
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Body
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _buildNotificationList(getCurrentTabData()),
            ),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> getCurrentTabData() {
    switch (_selectedTabIndex) {
      case 1:
        return _unreadNotifications;
      case 2:
        return _importantNotifications;
      case 3:
        return _spamNotifications;
      default:
        return _allNotifications;
    }
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (notifications.isEmpty) return Center(child: Text("No notifications found"));

    return RefreshIndicator(
      onRefresh: () => _loadTabData(_selectedTabIndex),
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          await _notificationController.markAsRead(notification.notificationId);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(notification: notification),
          ),
        ).then((_) => _loadTabData(_selectedTabIndex));
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: notification.senderProfileImageUrl != null
                  ? NetworkImage(notification.senderProfileImageUrl!)
                  : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
              child: notification.isImportant
                  ? Icon(Icons.star, color: Colors.amber, size: 16)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.senderName, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(notification.title, style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDateTime(notification.sentDateTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                SizedBox(height: 8),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } else if (diff.inDays > 0) {
      return "${diff.inDays}d ago";
    } else if (diff.inHours > 0) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}
