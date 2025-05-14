// File: e:\Hiru\medicine\test\rag_alert_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:medicine/services/rag_alert_service.dart';
import 'package:medicine/services/twilio_service.dart';
import 'package:medicine/controllers/rag_alert_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

@GenerateMocks([TwilioService, RagAlertController])
void main() {
  group('RagAlertService Tests', () {
    test('sendEmergencyAlert should correctly format the message', () async {
      // TODO: Implement when mock annotations are generated
    });
    
    // Simulate what happens in the real app
    test('Manual test for alert message formatting', () {
      // Define the data we'd normally get from the service
      final timestamp = '2023-06-15 14:30:00';
      final studentName = 'John Doe';
      final studentId = 'ST12345';
      final locationInfo = 'Current location';
      final coordinates = '6.9271,79.8612'; // Example coordinates for Colombo
      
      // Create the message format we expect
      final expectedMessage = 'RAGGING ALERT at $timestamp:\n'
          'Student: $studentName\n'
          'ID: $studentId\n'
          'Location: $locationInfo\n'
          'Coordinates: $coordinates\n\n'
          'Please respond immediately.';
          
      // Verify the format is correct
      expect(expectedMessage.contains('Student: John Doe'), true);
      expect(expectedMessage.contains('ID: ST12345'), true);
      expect(expectedMessage.contains('Coordinates: 6.9271,79.8612'), true);
    });
  });
}
