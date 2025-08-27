import 'package:flutter/material.dart';
import 'package:freshers_connect/services/twilio_service.dart';

// A simple Flutter app for testing Twilio SMS
void main() {
  runApp(const TwilioTestApp());
}

class TwilioTestApp extends StatelessWidget {
  const TwilioTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twilio Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TwilioTestScreen(),
    );
  }
}

class TwilioTestScreen extends StatefulWidget {
  const TwilioTestScreen({super.key});

  @override
  State<TwilioTestScreen> createState() => _TwilioTestScreenState();
}

class _TwilioTestScreenState extends State<TwilioTestScreen> {
  final TwilioService _twilioService = TwilioService();
  bool _isSending = false;
  String _status = '';
  
  Future<void> _sendTestSMS() async {
    setState(() {
      _isSending = true;
      _status = 'Sending test SMS to +18777804236...';
    });
    
    try {
      final result = await _twilioService.sendTestMessage('+18777804236');
      setState(() {
        _isSending = false;
        _status = result 
            ? 'SMS sent successfully!' 
            : 'Failed to send SMS. Check logs for details.';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _status = 'Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twilio SMS Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Testing Twilio SMS Service',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSending ? null : _sendTestSMS,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: _isSending 
                    ? const CircularProgressIndicator() 
                    : const Text('Send Test SMS', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  color: _status.contains('success') ? Colors.green : 
                         _status.contains('Error') ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
