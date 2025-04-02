import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import 'notification_detail.dart';

class NotificationTab extends StatefulWidget {
  @override
  _NotificationTabState createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationController _notificationController = NotificationController();
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  List<NotificationModel> _importantNotifications = [];
  List<NotificationModel> _spamNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadTabData(_tabController.index);
    }
  }

  Future<void> _loadTabData(int tabIndex) async {
    setState(() {
      _isLoading = true;
    });

    switch (tabIndex) {
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
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadAllNotifications();
      _unreadNotifications = await _notificationController.getUnreadNotifications();
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllNotifications() async {
    try {
      _allNotifications = await _notificationController.getAllNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading all notifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      _unreadNotifications = await _notificationController.getUnreadNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  Future<void> _loadImportantNotifications() async {
    try {
      _importantNotifications = await _notificationController.getImportantNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading important notifications: $e');
    }
  }

  Future<void> _loadSpamNotifications() async {
    try {
      _spamNotifications = await _notificationController.getSpamNotifications();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading spam notifications: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 25)),
        backgroundColor: AppColors.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "All"),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Unread"),
                  SizedBox(width: 4),
                  if (_unreadNotifications.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadNotifications.length.toString(),
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            Tab(text: "Important"),
            Tab(text: "Spam"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_allNotifications),
          _buildNotificationList(_unreadNotifications),
          _buildNotificationList(_importantNotifications),
          _buildNotificationList(_spamNotifications),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    if (notifications.isEmpty) {
      return Center(child: Text("No notifications found"));
    }

    return RefreshIndicator(
      onRefresh: () => _loadTabData(_tabController.index),
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
            builder: (context) => NotificationDetailScreen(notification: notification),
          ),
        ).then((_) {
          _loadTabData(_tabController.index);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
              child: notification.isImportant
                  ? Icon(Icons.star, color: Colors.amber, size: 16)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.senderName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(notification.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}
