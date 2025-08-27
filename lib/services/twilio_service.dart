// File: lib/services/twilio_service.dart
import 'package:twilio_flutter/twilio_flutter.dart';

class TwilioService {
  static final TwilioService _instance = TwilioService._internal();
  late TwilioFlutter _twilioFlutter;
  
  // Singleton pattern
  factory TwilioService() {
    return _instance;
  }
  
  TwilioService._internal() {
    // Initialize Twilio with your credentials
    _twilioFlutter = TwilioFlutter(
      accountSid: 'AC6433d1553032a17e830cd4639de7658e', 
      authToken: '60dc2f5c55bac3d0026caec70a0ac5bc',
      twilioNumber: '+17754179533'  // Updated sender number
    );
  }
    // Send SMS function with improved error handling
  Future<bool> sendSMS({
    required String to,
    required String messageBody,
  }) async {
    try {
      // Validate phone number format
      if (!_isValidPhoneNumber(to)) {
        print('Invalid phone number format: $to');
        return false;
      }
      
      print('Sending SMS to $to with length ${messageBody.length}');
      
      // Check if the message is too long (Twilio has a 1600 character limit)
      if (messageBody.length > 1600) {
        print('Warning: Message exceeds Twilio\'s 1600 character limit. Truncating...');
        messageBody = messageBody.substring(0, 1597) + '...';
      }
      
      // Send the message
      await _twilioFlutter.sendSMS(
        toNumber: to,
        messageBody: messageBody,
      );
      
      print('SMS sent successfully to $to');
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      
      // Provide more detailed error logging
      if (e.toString().contains('Authentication')) {
        print('Twilio authentication error - check your account SID and auth token');
      } else if (e.toString().contains('network')) {
        print('Network error - check internet connection');
      }
      
      return false;
    }
  }
  
  // Basic validation for phone numbers
  bool _isValidPhoneNumber(String phoneNumber) {
    // Phone number must start with + and have at least 10 digits
    return phoneNumber.startsWith('+') && 
           phoneNumber.length >= 10 &&
           phoneNumber.substring(1).replaceAll(RegExp(r'[^0-9]'), '').length >= 8;
  }
  
  // Send test message for verification
  Future<bool> sendTestMessage(String to) async {
    const String testMessage = 'This is a test message from your Ragging Alert app.';
    return await sendSMS(to: to, messageBody: testMessage);
  }
}
