// Simple test to verify password change page loads correctly
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// This is a simplified version for testing basic widget functionality
class TestChangePasswordPage extends StatefulWidget {
  const TestChangePasswordPage({Key? key}) : super(key: key);

  @override
  _TestChangePasswordPageState createState() => _TestChangePasswordPageState();
}

class _TestChangePasswordPageState extends State<TestChangePasswordPage> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password Test')),
      body: Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Step 1 indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 0 ? Colors.blue : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: _currentStep >= 0 ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1 ? Colors.blue : Colors.grey[300],
                  ),
                ),
                // Step 2 indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep >= 1 ? Colors.blue : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: _currentStep >= 1 ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Step 1: Enter Current Password'),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Step 2: Enter New Password'),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle password change
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully!')),
                    );
                  },
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
