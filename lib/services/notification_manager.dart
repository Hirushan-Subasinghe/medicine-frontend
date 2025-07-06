import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../services/local_notification_service.dart';
import '../services/navigation_service.dart';
import '../models/notification_model.dart';
import '../controllers/notification_controller.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final SocketService _socketService = SocketService();
  final NotificationController _notificationController = NotificationController();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;
  
  StreamSubscription<NotificationModel>? _newNotificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSentSubscription;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isSocketConnected => _socketService.isConnected;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 NotificationManager: Initializing...');
      
      // Initialize local notifications
      await LocalNotificationService.initialize();
      
      // Initialize Socket.IO
      await _socketService.initialize();
      
      // Set up stream listeners
      _setupStreamListeners();
      
      // Load existing notifications
      await _loadExistingNotifications();
      
      _isInitialized = true;
      notifyListeners();
      
      print('✅ NotificationManager: Initialized successfully');
    } catch (e) {
      print('❌ NotificationManager: Failed to initialize - $e');
    }
  }

  /// Set up stream listeners for real-time notifications
  void _setupStreamListeners() {
    // Listen for new notifications from Socket.IO
    _newNotificationSubscription = _socketService.newNotificationStream.listen(
      (notification) {
        print('🔔 NotificationManager: Received new notification - ${notification.title}');
        _handleNewNotification(notification);
      },
      onError: (error) {
        print('❌ NotificationManager: Error in new notification stream - $error');
      },
    );

    // Listen for notification sent confirmations (for admin users)
    _notificationSentSubscription = _socketService.notificationSentStream.listen(
      (data) {
        print('📤 NotificationManager: Notification sent confirmation - $data');
        // Handle admin confirmations if needed
      },
      onError: (error) {
        print('❌ NotificationManager: Error in notification sent stream - $error');
      },
    );
  }

  /// Handle new notification received via Socket.IO
  void _handleNewNotification(NotificationModel notification) {
    // Add to notifications list
    _notifications.insert(0, notification);
    _unreadCount++;
    
    // Notify listeners to update UI
    notifyListeners();
    
    // Show system notification
    LocalNotificationService.showNotification(
      id: notification.notificationId,
      title: notification.title,
      body: _stripHtmlTags(notification.message),
      isImportant: notification.isImportant,
      payload: notification.notificationId.toString(),
    );

    // Show in-app notification if app is in foreground
    _showInAppNotificationIfPossible(notification);
  }

  /// Show in-app notification using global navigator context
  void _showInAppNotificationIfPossible(NotificationModel notification) {
    try {
      // Import the main.dart file's navigator key
      final context = (WidgetsBinding.instance.rootElement ?? 
                      WidgetsBinding.instance.renderViewElement);
      
      if (context != null) {
        LocalNotificationService.showInAppNotification(
          context,
          notification,
          onTap: () {
            // Navigate to notifications tab using NavigationService
            print('🔔 In-app notification tapped - navigating to notifications');
            NavigationService.navigateToNotifications();
          },
        );
      } else {
        print('⚠️  No context available for in-app notification');
      }
    } catch (e) {
      print('❌ Failed to show in-app notification: $e');
    }
  }

  /// Show in-app notification banner for current context
  void showInAppNotification(BuildContext context, NotificationModel notification) {
    LocalNotificationService.showInAppNotification(
      context,
      notification,
      onTap: () {
        // Navigate to notifications tab using NavigationService
        NavigationService.navigateToNotifications();
      },
    );
  }

  /// Load existing notifications from API
  Future<void> _loadExistingNotifications() async {
    try {
      _notifications = await _notificationController.getAllNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      print('📱 NotificationManager: Loaded ${_notifications.length} existing notifications');
    } catch (e) {
      print('❌ NotificationManager: Failed to load existing notifications - $e');
    }
  }

  /// Refresh notifications manually
  Future<void> refreshNotifications() async {
    await _loadExistingNotifications();
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      // Update local state
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = NotificationModel(
          notificationId: _notifications[index].notificationId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          sentDateTime: _notifications[index].sentDateTime,
          isRead: true, // Mark as read
          isImportant: _notifications[index].isImportant,
          senderName: _notifications[index].senderName,
          senderProfileImageUrl: _notifications[index].senderProfileImageUrl,
          senderRole: _notifications[index].senderRole,
          senderFaculty: _notifications[index].senderFaculty,
          senderEmail: _notifications[index].senderEmail,
          readDateTime: DateTime.now(),
          categoryId: _notifications[index].categoryId,
          categoryName: _notifications[index].categoryName,
        );
        
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
      
      // Update on server
      await _notificationController.markAsRead(notificationId);
      
      print('✅ NotificationManager: Marked notification $notificationId as read');
    } catch (e) {
      print('❌ NotificationManager: Failed to mark notification as read - $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Update local state
      _notifications = _notifications.map((n) => NotificationModel(
        notificationId: n.notificationId,
        title: n.title,
        message: n.message,
        sentDateTime: n.sentDateTime,
        isRead: true,
        isImportant: n.isImportant,
        senderName: n.senderName,
        senderProfileImageUrl: n.senderProfileImageUrl,
        senderRole: n.senderRole,
        senderFaculty: n.senderFaculty,
        senderEmail: n.senderEmail,
        readDateTime: DateTime.now(),
        categoryId: n.categoryId,
        categoryName: n.categoryName,
      )).toList();
      
      _unreadCount = 0;
      notifyListeners();
      
      // TODO: Update all on server when API is available
      
      print('✅ NotificationManager: Marked all notifications as read');
    } catch (e) {
      print('❌ NotificationManager: Failed to mark all as read - $e');
    }
  }

  /// Reconnect socket if disconnected
  Future<void> reconnectSocket() async {
    await _socketService.reconnect();
  }

  /// Dispose resources
  void dispose() {
    _newNotificationSubscription?.cancel();
    _notificationSentSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  /// Helper to strip HTML tags
  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
