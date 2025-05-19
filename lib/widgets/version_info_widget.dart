import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfoWidget extends StatefulWidget {
  final String? backendVersion;
  
  const VersionInfoWidget({
    Key? key,
    this.backendVersion,
  }) : super(key: key);

  @override
  State<VersionInfoWidget> createState() => _VersionInfoWidgetState();
}

class _VersionInfoWidgetState extends State<VersionInfoWidget> {
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  String _packageName = '';
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _packageName = packageInfo.packageName;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Error: ${e.toString().split(':').first}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Mobile App', _appVersion + (_buildNumber.isNotEmpty ? ' (${_buildNumber})' : '')),
            if (_packageName.isNotEmpty)
              _buildInfoRow('Package Name', _packageName),
            if (widget.backendVersion != null)
              _buildInfoRow('Backend', widget.backendVersion!),
              
            const SizedBox(height: 8),
            _buildVersionCompatibility(),
          ],
        ),
      ),
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
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
  
  Widget _buildVersionCompatibility() {
    // This is a placeholder for version compatibility checking logic
    // In a real app, you might want to check if the mobile app version 
    // is compatible with the backend version
    
    bool isCompatible = true; // Implement actual compatibility logic
    
    return Row(
      children: [
        Icon(
          isCompatible ? Icons.check_circle : Icons.warning,
          color: isCompatible ? Colors.green : Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isCompatible 
                ? 'App and backend versions are compatible' 
                : 'Warning: App and backend versions may not be fully compatible',
            style: TextStyle(
              color: isCompatible ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
