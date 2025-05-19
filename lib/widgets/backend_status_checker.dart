import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';
import 'dart:async';

class BackendStatusChecker extends StatefulWidget {
  final Duration checkInterval;
  
  const BackendStatusChecker({
    Key? key,
    this.checkInterval = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  State<BackendStatusChecker> createState() => _BackendStatusCheckerState();
}

class _BackendStatusCheckerState extends State<BackendStatusChecker> {
  bool _isConnected = false;
  String _statusMessage = "Checking connection...";
  Timer? _checkTimer;
  Map<String, dynamic> _serverInfo = {};

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _startPeriodicChecks();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicChecks() {
    _checkTimer = Timer.periodic(widget.checkInterval, (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      // Try to connect to the /health or /status endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      setState(() {
        _isConnected = response.statusCode >= 200 && response.statusCode < 300;
        if (_isConnected) {
          _statusMessage = "Connected to backend";
          try {
            // Try to parse response as JSON if available
            Map<String, dynamic> data = {};
            if (response.body.isNotEmpty) {
              data = Map<String, dynamic>.from(
                  jsonDecode(response.body) as Map);
            }
            _serverInfo = data;
          } catch (e) {
            _serverInfo = {"message": "Backend is reachable"};
          }
        } else {
          _statusMessage = "Backend error: HTTP ${response.statusCode}";
        }
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = "Cannot connect to backend: ${e.toString().split(':').first}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.error,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _checkConnection,
                tooltip: 'Check connection now',
                iconSize: 20,
              ),
            ],
          ),
          if (_isConnected && _serverInfo.isNotEmpty) ...[
            const Divider(),
            Text(
              'Server Info:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            ...(_serverInfo.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('${entry.key}: ${entry.value}'),
              )
            )),
          ],
        ],
      ),
    );
  }
}

// Helper function to safely decode JSON
dynamic jsonDecode(String data) {
  try {
    return json.decode(data);
  } catch (_) {
    return {};
  }
}
