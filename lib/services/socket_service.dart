import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../models/notification_model.dart';
import 'user_state_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Stream controllers for real-time events
  final StreamController<NotificationModel> _newNotificationController = 
      StreamController<NotificationModel>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationSentController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters for streams
  Stream<NotificationModel> get newNotificationStream => _newNotificationController.stream;
  Stream<Map<String, dynamic>> get notificationSentStream => _notificationSentController.stream;
  
  bool get isConnected => _isConnected;

  /// Initialize Socket.IO connection
  Future<void> initialize() async {
    try {
      // Disconnect if already connected
      if (_socket != null) {
        _socket!.disconnect();
      }

      // Create socket connection with proper server URL
      _socket = IO.io(baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build());

      // Set up event listeners
      _setupEventListeners();

      // Connect to server
      _socket!.connect();
      
      print('🔌 Socket.IO: Attempting to connect to $baseUrl');
    } catch (e) {
      print('❌ Socket.IO: Failed to initialize - $e');
    }
  }

  /// Set up event listeners for Socket.IO
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      print('🔌 Socket.IO: Connected successfully');
      _joinUserRoom();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('🔌 Socket.IO: Disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      print('❌ Socket.IO: Connection error - $error');
    });

    _socket!.onError((error) {
      print('❌ Socket.IO: Error - $error');
    });

    // Custom notification events
    _socket!.on('new_notification', (data) {
      print('🔔 Socket.IO: Received new notification - $data');
      _handleNewNotification(data);
    });

    _socket!.on('notification_sent', (data) {
      print('📤 Socket.IO: Notification sent confirmation - $data');
      _notificationSentController.add(data);
    });
  }

  /// Join user-specific room for targeted notifications
  Future<void> _joinUserRoom() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && _socket != null && _isConnected) {
        // Get database userId from UserStateService instead of Firebase UID
        final userStateService = UserStateService();
        final databaseUserId = userStateService.currentUserId;
        
        if (databaseUserId != null) {
          _socket!.emit('join_user_room', databaseUserId);
          print('👤 Socket.IO: Joined user room for database user ID: $databaseUserId');
        } else {
          print('⚠️ Socket.IO: Database user ID not available, cannot join room');
          // Try to initialize user data if not already loaded
          await userStateService.initializeUser();
          final retryUserId = userStateService.currentUserId;
          if (retryUserId != null) {
            _socket!.emit('join_user_room', retryUserId);
            print('👤 Socket.IO: Joined user room for database user ID (retry): $retryUserId');
          }
        }
      }
    } catch (e) {
      print('❌ Socket.IO: Failed to join user room - $e');
    }
  }

  /// Handle incoming new notification
  void _handleNewNotification(dynamic data) {
    try {
      // Convert socket data to NotificationModel
      final notification = NotificationModel.fromJson({
        'notificationId': data['id'] ?? 0,
        'title': data['title'] ?? '',
        'message': data['message'] ?? '',
        'sentDateTime': data['sentDateTime'] ?? DateTime.now().toIso8601String(),
        'isRead': false,
        'isImportant': data['isImportant'] ?? false,
        'senderName': data['sender'] ?? 'University Admin',
        'categoryId': 1,
        'categoryName': data['category'] ?? 'General',
      });

      // Emit to stream for listeners
      _newNotificationController.add(notification);
    } catch (e) {
      print('❌ Socket.IO: Failed to parse notification data - $e');
    }
  }

  /// Reconnect to socket
  Future<void> reconnect() async {
    if (_socket != null) {
      _socket!.connect();
    } else {
      await initialize();
    }
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
    print('🔌 Socket.IO: Manually disconnected');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _newNotificationController.close();
    _notificationSentController.close();
  }
}
