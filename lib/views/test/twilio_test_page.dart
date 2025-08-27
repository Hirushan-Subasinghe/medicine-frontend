// File: lib/views/test/twilio_test_page.dart
import 'package:flutter/material.dart';
import '../../widgets/rag_alert/sms_test_widget.dart';
import '../../core/constants.dart';

class TwilioTestPage extends StatelessWidget {
  const TwilioTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twilio SMS Test', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sms, size: 80, color: AppColors.primaryColor),
              const SizedBox(height: 24),
              const Text(
                'Twilio SMS Test',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Press the button below to send a test SMS to +18777804236.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              const SMSTestWidget(),
              const SizedBox(height: 40),
              const Text(
                'Note: Make sure you have a valid Twilio account with sufficient credit to send messages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
