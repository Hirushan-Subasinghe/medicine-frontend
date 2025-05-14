import 'package:medicine/services/twilio_service.dart';

class RagAlertService {
  static final RagAlertService _instance = RagAlertService._internal();
  final TwilioService _twilioService = TwilioService();
  
  factory RagAlertService() {
    return _instance;
  }
  
  RagAlertService._internal();
  
  /// Send a ragging alert SMS to emergency contacts and staff
  /// 
  /// Parameters:
  ///   - studentName: Name of the student sending the alert
  ///   - studentId: ID of the student
  ///   - location: Description of location (e.g., "Engineering Building, Floor 2")
  ///   - coordinates: Optional latitude and longitude as string "lat,lng"
  ///   - emergencyContactNumbers: List of emergency contact phone numbers
  Future<bool> sendRaggingAlertSMS({
    required String studentName,
    required String studentId,
    required String location,
    String? coordinates,
    required List<String> emergencyContactNumbers,
  }) async {
    bool allSent = true;
    
    // Create the alert message
    final String message = _createAlertMessage(
      studentName: studentName,
      studentId: studentId,
      location: location,
      coordinates: coordinates,
    );
    
    // Send to all emergency contacts
    for (final phoneNumber in emergencyContactNumbers) {
      try {
        final success = await _twilioService.sendSMS(
          to: phoneNumber,
          messageBody: message,
        );
        
        if (!success) {
          allSent = false;
          print('Failed to send SMS to $phoneNumber');
        }
      } catch (e) {
        allSent = false;
        print('Error sending SMS to $phoneNumber: $e');
      }
    }
    
    return allSent;
  }
  
  /// Create the alert message text
  String _createAlertMessage({
    required String studentName,
    required String studentId,
    required String location,
    String? coordinates,
  }) {
    final String locationInfo = coordinates != null 
        ? '$location (Coordinates: $coordinates)' 
        : location;
        
    return 'RAGGING ALERT: $studentName (ID: $studentId) has reported a ragging incident at $locationInfo. Please respond immediately.';
  }
  
  /// Send a test alert message
  Future<bool> sendTestAlert(String phoneNumber) async {
    const String testMessage = 'This is a TEST RAGGING ALERT from the Anti-Ragging System. If this were a real alert, emergency response would be activated.';
    return await _twilioService.sendSMS(to: phoneNumber, messageBody: testMessage);
  }
}
