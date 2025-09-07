import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import '../models/notification_model.dart';
import 'navigation_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize local notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Navigate to notifications page
    NavigationService.navigateToNotifications();
  }

  /// Show local notification (system notification)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required bool isImportant,
    String? payload,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      isImportant ? 'important_channel' : 'default_channel',
      isImportant ? 'Important Notifications' : 'Default Notifications',
      channelDescription: isImportant 
          ? 'Important university notifications'
          : 'General university notifications',
      importance: isImportant ? Importance.high : Importance.defaultImportance,
      priority: isImportant ? Priority.high : Priority.defaultPriority,
      ticker: 'University Notification',
      icon: '@mipmap/ic_launcher',
      color: isImportant ? const Color(0xFFFF5722) : const Color(0xFF2196F3),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show in-app notification overlay (Facebook-style)
  static void showInAppNotification(
    BuildContext context,
    NotificationModel notification,
    {VoidCallback? onTap}
  ) {
    showOverlayNotification(
      (context) {
        return NotificationBanner(
          notification: notification,
          onTap: onTap,
          onDismiss: () {
            OverlaySupportEntry.of(context)?.dismiss();
          },
        );
      },
      duration: const Duration(seconds: 5),
      position: NotificationPosition.top,
    );
  }
}

/// Custom notification banner widget (Facebook-style)
class NotificationBanner extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationBanner({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  _NotificationBannerState createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.notification.isImportant 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.notification.isImportant 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.notification.isImportant 
                            ? Icons.priority_high
                            : Icons.notifications,
                        color: widget.notification.isImportant 
                            ? Colors.red
                            : Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category badge and title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.notification.isImportant 
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.notification.categoryName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: widget.notification.isImportant 
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (widget.notification.isImportant) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'URGENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Title
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          
                          // Message preview
                          Text(
                            _stripHtmlTags(widget.notification.message),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Sender and time
                          Row(
                            children: [
                              Text(
                                'From: ${widget.notification.senderName}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tap to view →',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Dismiss button
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
