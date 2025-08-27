import 'package:flutter/material.dart';
import 'package:freshers_connect/services/twilio_service.dart';

class TwilioTestPage extends StatefulWidget {
  const TwilioTestPage({super.key});

  @override
  State<TwilioTestPage> createState() => _TwilioTestPageState();
}

class _TwilioTestPageState extends State<TwilioTestPage> {
  final TwilioService _twilioService = TwilioService();
  bool _isSending = false;
  String _status = '';
  final String _testPhoneNumber = '+18777804236';
  
  Future<void> _sendTestMessage() async {
    setState(() {
      _isSending = true;
      _status = 'Sending test SMS...';
    });
    
    try {
      final bool success = await _twilioService.sendTestMessage(_testPhoneNumber);
      
      setState(() {
        _isSending = false;
        _status = success 
            ? 'SMS sent successfully to $_testPhoneNumber' 
            : 'Failed to send SMS. Check logs for details.';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _status = 'Error: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twilio SMS Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Test Twilio SMS Integration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Phone Number: $_testPhoneNumber'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSending ? null : _sendTestMessage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _isSending
                      ? const CircularProgressIndicator()
                      : const Text('Send Test SMS', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                style: TextStyle(
                  color: _status.contains('success') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
