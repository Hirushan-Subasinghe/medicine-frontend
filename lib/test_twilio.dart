// A simple test script to verify Twilio SMS functionality
import 'dart:async';
import 'package:freshers_connect/services/twilio_service.dart';

void main() async {
  print('Starting Twilio SMS Test...');
  final twilioService = TwilioService();
  
  print('Sending test SMS to +18777804236...');
  try {
    final success = await twilioService.sendTestMessage('+18777804236');
    print(success 
        ? 'SMS sent successfully!' 
        : 'Failed to send SMS. Check console for details.');
  } catch (e) {
    print('Error sending SMS: $e');
  }
  
  // Wait for 3 seconds to allow the SMS to be sent before exiting
  await Future.delayed(const Duration(seconds: 3));
  print('Test completed.');
}
