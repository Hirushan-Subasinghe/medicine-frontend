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
      accountSid: 'ACcf2be9f9e8ad792e61a6664971e3b312', 
      authToken: '7538c8d34b35476624925dda467a774b',
      twilioNumber: '+18312573525'
    );
  }
  
  // Send SMS function
  Future<bool> sendSMS({
    required String to,
    required String messageBody,
  }) async {
    try {
      await _twilioFlutter.sendSMS(
        toNumber: to,
        messageBody: messageBody,
      );
      print('SMS sent successfully to $to');
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }
  
  // Send test message for verification
  Future<bool> sendTestMessage(String to) async {
    const String testMessage = 'This is a test message from your Ragging Alert app.';
    return await sendSMS(to: to, messageBody: testMessage);
  }
}
