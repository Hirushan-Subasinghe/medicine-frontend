// File: lib/widgets/rag_alert/sms_test_widget.dart
import 'package:flutter/material.dart';
import '../../services/twilio_service.dart';

class SMSTestWidget extends StatefulWidget {
  const SMSTestWidget({Key? key}) : super(key: key);

  @override
  _SMSTestWidgetState createState() => _SMSTestWidgetState();
}

class _SMSTestWidgetState extends State<SMSTestWidget> {
  final TwilioService _twilioService = TwilioService();
  bool _isSending = false;
  String _statusMessage = '';
  
  Future<void> _sendTestSMS() async {
    setState(() {
      _isSending = true;
      _statusMessage = 'Sending test SMS...';
    });
    
    try {
      // Send to your phone number
      final result = await _twilioService.sendTestMessage('+18777804236');
      
      setState(() {
        _isSending = false;
        _statusMessage = result 
            ? 'Test SMS sent successfully!' 
            : 'Failed to send test SMS. Check console for details.';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _isSending ? null : _sendTestSMS,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSending 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Send Test SMS',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
        const SizedBox(height: 16),
        if (_statusMessage.isNotEmpty)
          Text(
            _statusMessage,
            style: TextStyle(
              color: _statusMessage.contains('success') 
                  ? Colors.green 
                  : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
