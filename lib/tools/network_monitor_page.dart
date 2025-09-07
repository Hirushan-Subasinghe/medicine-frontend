import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkMonitorPage extends StatefulWidget {
  const NetworkMonitorPage({super.key});

  @override
  State<NetworkMonitorPage> createState() => _NetworkMonitorPageState();
}

class _NetworkMonitorPageState extends State<NetworkMonitorPage> {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  String _connectionStatus = 'Unknown';
  String _wifiIP = 'Unknown';
  String _wifiName = 'Unknown';
  String _serverStatus = 'Not checked';
  int _pingResult = -1;
  List<APITestResult> _testResults = [];
  
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _loadWifiInfo();
    _testServerConnection();
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      result = [ConnectivityResult.none];
    }
    
    if (!mounted) return;
    
    _updateConnectionStatus(result);
  }

  Future<void> _loadWifiInfo() async {
    try {
      _wifiIP = await _networkInfo.getWifiIP() ?? 'Not available';
      _wifiName = await _networkInfo.getWifiName() ?? 'Not available';
    } catch (e) {
      _wifiIP = 'Error: $e';
      _wifiName = 'Error getting WiFi name';
    }
    
    if (mounted) setState(() {});
  }
  
  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    switch (result.first) {
      case ConnectivityResult.wifi:
        _connectionStatus = 'WiFi';
        _loadWifiInfo();
        break;
      case ConnectivityResult.mobile:
        _connectionStatus = 'Mobile Data';
        break;
      case ConnectivityResult.none:
        _connectionStatus = 'No Connection';
        break;
      default:
        _connectionStatus = 'Unknown';
        break;
    }
    
    if (mounted) setState(() {});
  }
  
  Future<void> _pingServer() async {
    setState(() {
      _pingResult = -1;
    });
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 3));
      
      stopwatch.stop();
      
      setState(() {
        _pingResult = stopwatch.elapsedMilliseconds;
        _serverStatus = response.statusCode >= 200 && response.statusCode < 300
            ? 'Online (${response.statusCode})'
            : 'Error (${response.statusCode})';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _pingResult = stopwatch.elapsedMilliseconds;
        _serverStatus = 'Failed: ${e.toString().split(':').first}';
      });
    }
  }
  
  Future<void> _testServerConnection() async {
    setState(() {
      _testResults = [];
    });
    
    // Test status endpoint
    await _testAPI(
      name: 'Status Check',
      endpoint: '/api/status',
      method: 'GET',
    );
    
    // Test public endpoints - add any endpoints you want to test
    // that don't require authentication
    await _testAPI(
      name: 'Public Data',
      endpoint: '/api/common/public-data', // Replace with an actual endpoint
      method: 'GET',
    );
  }
  
  Future<void> _testAPI({
    required String name,
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final result = APITestResult(
      name: name,
      url: '$baseUrl$endpoint',
      method: method,
    );
    
    setState(() {
      _testResults.add(result);
    });
    
    final stopwatch = Stopwatch()..start();
    
    try {
      http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body,
          ).timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported method: $method');
      }
      
      stopwatch.stop();
      
      result.statusCode = response.statusCode;
      result.responseTime = stopwatch.elapsedMilliseconds;
      result.success = response.statusCode >= 200 && response.statusCode < 300;
      
      try {
        if (response.body.isNotEmpty) {
          result.responseBody = jsonDecode(response.body);
        }
      } catch (e) {
        result.error = 'Failed to parse JSON: $e';
      }
    } catch (e) {
      stopwatch.stop();
      result.responseTime = stopwatch.elapsedMilliseconds;
      result.success = false;
      result.error = e.toString();
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initConnectivity();
              _loadWifiInfo();
              _pingServer();
              _testServerConnection();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _initConnectivity();
          await _loadWifiInfo();
          await _pingServer();
          await _testServerConnection();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionInfo(),
              const Divider(height: 30),
              _buildServerStatus(),
              const Divider(height: 30),
              _buildAPITests(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Connection Type', _connectionStatus),
            _buildInfoRow('WiFi Name', _wifiName),
            _buildInfoRow('IP Address', _wifiIP),
            _buildInfoRow('API Base URL', baseUrl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServerStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', _serverStatus),
            _buildInfoRow(
              'Response Time', 
              _pingResult < 0 ? 'Not tested' : '$_pingResult ms'
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.network_ping),
                label: const Text('Ping Server'),
                onPressed: _pingServer,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAPITests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'API Connection Tests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _testServerConnection,
                  tooltip: 'Run all tests',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._testResults.map(_buildAPITestResult),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAPITestResult(APITestResult result) {    Color statusColor = Colors.grey;
    
    if (result.statusCode != null && result.success != null) {
      statusColor = result.success! ? Colors.green : Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),      color: result.success == null 
          ? Colors.grey[50]
          : result.success!
              ? Colors.green[50]
              : Colors.red[50],
      child: ExpansionTile(
        title: Row(
          children: [            Icon(
              result.success == null
                  ? Icons.hourglass_bottom
                  : result.success!
                      ? Icons.check_circle
                      : Icons.error,
              color: statusColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              result.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Text(
          result.statusCode == null
              ? 'Testing...'
              : 'Status: ${result.statusCode} - ${result.responseTime}ms',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Method', result.method),
                _buildInfoRow('URL', result.url),
                if (result.statusCode != null)
                  _buildInfoRow('Status Code', '${result.statusCode}'),
                if (result.responseTime != null)
                  _buildInfoRow('Response Time', '${result.responseTime} ms'),
                if (result.error != null)
                  _buildInfoRow('Error', result.error!),
                if (result.responseBody != null) ...[
                  const SizedBox(height: 8),
                  const Text('Response:'),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      const JsonEncoder.withIndent('  ')
                          .convert(result.responseBody),
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
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
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

class APITestResult {
  final String name;
  final String url;
  final String method;
  
  int? statusCode;
  int? responseTime;
  bool? success;
  String? error;
  Map<String, dynamic>? responseBody;
  
  APITestResult({
    required this.name,
    required this.url,
    required this.method,
  });
}
