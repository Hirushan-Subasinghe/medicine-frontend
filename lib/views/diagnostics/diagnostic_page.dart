import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/backend_status_checker.dart';
import '../../widgets/deployment_info_widget.dart';
import '../../widgets/version_info_widget.dart';
import '../../core/constants.dart';
import '../../tools/connection_tester.dart';
import '../../tools/network_monitor_page.dart';
import 'dart:io';

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({Key? key}) : super(key: key);

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  Map<String, dynamic> _deviceInfo = {};
  String _connectionType = 'Unknown';
  bool _isLoading = true;
  String? _backendVersion;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }
  Future<void> _loadInfo() async {
    // Get backend version
    _fetchBackendVersion();
    
    // Get device info
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      info = {
        'platform': 'Web',
        'browser': webInfo.browserName.toString(),
        'userAgent': webInfo.userAgent ?? 'Unknown',
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      info = {
        'platform': 'Android',
        'version': androidInfo.version.release,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      info = {
        'platform': 'iOS',
        'version': iosInfo.systemVersion,
        'model': iosInfo.model,
        'name': iosInfo.name,
      };
    } else {
      info = {
        'platform': Platform.operatingSystem,
        'version': 'Unknown'
      };
    }

    // Get connectivity info
    final connectivityResult = await Connectivity().checkConnectivity();
    String connectionType;

    switch (connectivityResult) {
      case ConnectivityResult.mobile:
        connectionType = 'Mobile Data';
        break;
      case ConnectivityResult.wifi:
        connectionType = 'WiFi';
        break;
      case ConnectivityResult.ethernet:
        connectionType = 'Ethernet';
        break;
      case ConnectivityResult.bluetooth:
        connectionType = 'Bluetooth';
        break;
      case ConnectivityResult.vpn:
        connectionType = 'VPN';
        break;
      case ConnectivityResult.other:
        connectionType = 'Other';
        break;
      default:
        connectionType = 'None';
    }    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _connectionType = connectionType;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchBackendVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _backendVersion = data['version'];
          });
        }
      }
    } catch (e) {
      // Handle error silently, the version widget will show "Unknown" if null
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadInfo();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Backend Status
                  const Text(
                    'Backend Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),                  const SizedBox(height: 8),
                  const BackendStatusChecker(),
                  const SizedBox(height: 10),
                    // Connection Test Button
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.speed),
                          label: const Text('Connection Test'),
                          onPressed: () {
                            ConnectionTester.showConnectionTestDialog(context);
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.monitor),
                          label: const Text('Network Monitor'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NetworkMonitorPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Deployment Information
                  const Text(
                    'Deployment Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),                  const SizedBox(height: 8),
                  const DeploymentInfoWidget(),
                  const SizedBox(height: 20),
                  
                  // Version Information
                  const Text(
                    'Version Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VersionInfoWidget(backendVersion: _backendVersion),
                  const SizedBox(height: 20),

                  // API Configuration
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Base URL: $baseUrl'),
                          const SizedBox(height: 8),
                          Text('Debug Mode: ${kDebugMode ? 'Enabled' : 'Disabled'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Network Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Network Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Connection Type: $_connectionType'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Device Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._deviceInfo.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('${e.key}: ${e.value}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Authentication Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Authentication Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Logged in: ${FirebaseAuth.instance.currentUser != null ? 'Yes' : 'No'}',
                          ),
                          if (FirebaseAuth.instance.currentUser != null) ...[
                            const SizedBox(height: 8),
                            Text('User ID: ${FirebaseAuth.instance.currentUser!.uid}'),
                            const SizedBox(height: 8),
                            Text('Email: ${FirebaseAuth.instance.currentUser!.email ?? 'Not available'}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
