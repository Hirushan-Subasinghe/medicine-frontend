import 'package:flutter/material.dart';
import '../../services/rag_alert_service.dart';
import '../../core/constants.dart';

class RagAlertTestPage extends StatefulWidget {
  const RagAlertTestPage({Key? key}) : super(key: key);

  @override
  _RagAlertTestPageState createState() => _RagAlertTestPageState();
}

class _RagAlertTestPageState extends State<RagAlertTestPage> {
  final RagAlertService _ragAlertService = RagAlertService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isSending = false;
  String _statusMessage = '';
  
  @override
  void initState() {
    super.initState();
    // Pre-fill with your test number
    _phoneController.text = '+18777804236';
    _nameController.text = 'Test Student';
    _idController.text = 'ST12345';
    _locationController.text = 'Engineering Building, Floor 2';
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  Future<void> _sendTestAlert() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a phone number';
      });
      return;
    }
    
    setState(() {
      _isSending = true;
      _statusMessage = 'Sending alert...';
    });
    
    try {
      final success = await _ragAlertService.sendTestAlert(_phoneController.text);
      
      setState(() {
        _isSending = false;
        _statusMessage = success 
            ? 'Test alert sent successfully!' 
            : 'Failed to send alert. Check logs for details.';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _statusMessage = 'Error: $e';
      });
    }
  }
  
  Future<void> _sendRealAlert() async {
    if (_phoneController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _locationController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill all fields';
      });
      return;
    }
    
    setState(() {
      _isSending = true;
      _statusMessage = 'Sending ragging alert...';
    });
    
    try {
      final success = await _ragAlertService.sendRaggingAlertSMS(
        studentName: _nameController.text,
        studentId: _idController.text,
        location: _locationController.text,
        emergencyContactNumbers: [_phoneController.text],
      );
      
      setState(() {
        _isSending = false;
        _statusMessage = success 
            ? 'Ragging alert sent successfully!' 
            : 'Failed to send alert. Check logs for details.';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ragging Alert SMS Test', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Icon and title
            Center(
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, 
                       size: 60, 
                       color: Colors.red[700]),
                  const SizedBox(height: 10),
                  const Text(
                    'Ragging Alert SMS Test',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Test sending emergency SMS alerts',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Form fields
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: '+94XXXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendTestAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Send Test Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendRealAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Send Full Alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('success')
                      ? Colors.green[50]
                      : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                          ? Colors.red[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('success')
                        ? Colors.green
                        : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusMessage.contains('success')
                        ? Colors.green[700]
                        : _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                            ? Colors.red[700]
                            : Colors.blue[700],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
