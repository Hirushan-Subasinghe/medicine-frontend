import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import 'notification_detail.dart';

class NotificationTab extends StatefulWidget {
  @override
  _NotificationTabState createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> with SingleTickerProviderStateMixin {
  final NotificationController _notificationController = NotificationController();

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  List<NotificationModel> _importantNotifications = [];

  bool _isLoading = true;
  bool _firstLoadDone = false;
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['All', 'Unread', 'Important'];
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _loadTabData(_tabController.index);
    }
  }

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
      setState(() {}); // Update UI with new data
    } catch (e) {
      print('Error loading all notifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      _unreadNotifications = await _notificationController.getUnreadNotifications();
      setState(() {}); // Update UI with new data
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  Future<void> _loadImportantNotifications() async {
    try {
      _importantNotifications = await _notificationController.getImportantNotifications();
      setState(() {}); // Update UI with new data
    } catch (e) {
      print('Error loading important notifications: $e');
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: "All",
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Unread"),
                  if (_unreadNotifications.isNotEmpty)
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
            Tab(
              text: "Important",
            ),
          ],
          onTap: (index) {
            _loadTabData(index);
          },
        ),
      ),
      body: Column(
        children: [
          // Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_allNotifications),
                _buildNotificationList(_unreadNotifications),
                _buildNotificationList(_importantNotifications),
              ],
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
        // Navigate to detail screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(notification: notification),
          ),
        ).then((_) async {          
          // Reload data for all tabs
          await Future.wait([
            _loadAllNotifications(),
            _loadUnreadNotifications(),
            _loadImportantNotifications(),
          ]);
          
          if (mounted) {
            setState(() {}); // Update UI to reflect changes
          }
        });
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
