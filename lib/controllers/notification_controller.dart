import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../core/constants.dart';

class NotificationController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all notifications for the current user
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      // Get the current user's ID token
      String? idToken = await _auth.currentUser?.getIdToken();

      if (idToken == null) {
        throw Exception("Not authenticated");
      }      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print('Notifications API response: ${data.length} notifications received');
        // Log the first few notifications with sender info
        if (data.isNotEmpty) {
          print('First notification: ${data[0]['title']} (ID: ${data[0]['notificationId']})');
          print('Sender: ${data[0]['senderName']} (${data[0]['senderEmail']})');
          
          // Log all notifications for debugging
          for (int i = 0; i < data.length && i < 5; i++) {
            print('Notification ${i + 1}: ${data[i]['title']} - Sender: ${data[i]['senderName']}');
          }
        }
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      String? idToken = await _auth.currentUser?.getIdToken();

      if (idToken == null) {
        throw Exception("Not authenticated");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load unread notifications');
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      String? idToken = await _auth.currentUser?.getIdToken();

      if (idToken == null) {
        throw Exception("Not authenticated");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      // Return true if the API call was successful
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Get important notifications
  Future<List<NotificationModel>> getImportantNotifications() async {
    try {
      String? idToken = await _auth.currentUser?.getIdToken();

      if (idToken == null) {
        throw Exception("Not authenticated");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/important'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load important notifications');
      }
    } catch (e) {
      print('Error fetching important notifications: $e');
      return [];
    }
  }
}