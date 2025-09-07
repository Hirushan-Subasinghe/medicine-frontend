import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ConnectionTester {
  /// Tests the connection to the backend and returns detailed information
  static Future<ConnectionTestResult> testConnection() async {
    final result = ConnectionTestResult();
    
    // Start timing
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get local IP for debugging
      try {
        final interfaces = await NetworkInterface.list(
          includeLinkLocal: false,
          type: InternetAddressType.IPv4,
        );
          result.localIpAddresses = interfaces
            .expand((interface) => interface.addresses.map((addr) => 
              '${addr.address} (${interface.name})'))
            .toList();
      } catch (e) {
        result.localIpAddresses = ['Error getting IP: ${e.toString()}'];
      }
      
      // Test backend connection
      try {
        result.requestUrl = '$baseUrl/api/status';
        final response = await http.get(
          Uri.parse(result.requestUrl),
        ).timeout(const Duration(seconds: 10));
        
        result.statusCode = response.statusCode;
        result.responseTime = stopwatch.elapsedMilliseconds;
        result.isConnected = response.statusCode >= 200 && response.statusCode < 300;
        
        if (response.body.isNotEmpty) {
          try {
            result.responseBody = jsonDecode(response.body);
          } catch (e) {
            result.responseBody = {'error': 'Failed to parse JSON: ${e.toString()}'};
          }
        }
      } catch (e) {
        result.error = e.toString();
        result.isConnected = false;
        result.responseTime = stopwatch.elapsedMilliseconds;
      }
    } finally {
      stopwatch.stop();
    }
    
    return result;
  }

  /// Shows a connection test dialog with real-time results
  static Future<void> showConnectionTestDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConnectionTestDialog(),
    );
  }
}

/// Dialog that shows connection test progress and results
class ConnectionTestDialog extends StatefulWidget {
  const ConnectionTestDialog({Key? key}) : super(key: key);

  @override
  State<ConnectionTestDialog> createState() => _ConnectionTestDialogState();
}

class _ConnectionTestDialogState extends State<ConnectionTestDialog> {
  bool _isLoading = true;
  late ConnectionTestResult _result;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    _result = await ConnectionTester.testConnection();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connection Test'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing connection to backend...'),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result.isConnected
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _result.isConnected
                              ? Colors.green
                              : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _result.isConnected
                                ? 'Connected successfully'
                                : 'Connection failed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _result.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoSection('Request details', [
                      _buildInfoRow('URL', _result.requestUrl),
                      _buildInfoRow('Base URL from constants', baseUrl),
                      _buildInfoRow('Response time', '${_result.responseTime}ms'),
                      if (_result.statusCode != null)
                        _buildInfoRow('Status code', _result.statusCode.toString()),
                      if (_result.error != null)
                        _buildInfoRow('Error', _result.error!),
                    ]),
                    _buildInfoSection('Device network', [
                      ..._result.localIpAddresses.map(
                        (ip) => _buildInfoRow('Local IP', ip),
                      ),
                    ]),
                    if (_result.responseBody != null) ...[
                      const Divider(),
                      const Text(
                        'Server response:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        width: double.infinity,
                        child: Text(
                          const JsonEncoder.withIndent('  ')
                              .convert(_result.responseBody),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _runTest();
            },
            child: const Text('Test Again'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Holds the results of a connection test
class ConnectionTestResult {
  bool isConnected = false;
  String requestUrl = '';
  int? statusCode;
  String? error;
  int responseTime = 0;
  Map<String, dynamic>? responseBody;
  List<String> localIpAddresses = [];
}
