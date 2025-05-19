import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class DeploymentInfoWidget extends StatefulWidget {
  const DeploymentInfoWidget({Key? key}) : super(key: key);

  @override
  State<DeploymentInfoWidget> createState() => _DeploymentInfoWidgetState();
}

class _DeploymentInfoWidgetState extends State<DeploymentInfoWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _deploymentInfo = {};
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadDeploymentInfo();
  }
  
  Future<void> _loadDeploymentInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _deploymentInfo = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load deployment info: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading deployment info: ${e.toString().split(":").first}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deployment Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadDeploymentInfo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deployment Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadDeploymentInfo,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            _buildInfoItem('Status', _deploymentInfo['status'] ?? 'Unknown', 
                _deploymentInfo['status'] == 'online' ? Colors.green : Colors.red),
            _buildInfoItem('Environment', _deploymentInfo['environment'] ?? 'Unknown'),
            _buildInfoItem('Version', _deploymentInfo['version'] ?? 'Unknown'),
            _buildInfoItem('Server Time', _formatDate(_deploymentInfo['time'] ?? '')),
            _buildInfoItem('Uptime', _deploymentInfo['uptime'] ?? 'Unknown'),
            
            const SizedBox(height: 8),
            const Text(
              'Database',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildInfoItem(
              'Connection', 
              _deploymentInfo['database'] != null && _deploymentInfo['database']['connected'] == true 
                ? 'Connected' 
                : 'Not connected',
              _deploymentInfo['database'] != null && _deploymentInfo['database']['connected'] == true
                ? Colors.green
                : Colors.red,
            ),
            if (_deploymentInfo['database'] != null && 
                _deploymentInfo['database']['error'] != null &&
                _deploymentInfo['database']['error'].toString().isNotEmpty)
              _buildInfoItem('Error', _deploymentInfo['database']['error'], Colors.red),
            
            if (_deploymentInfo['memory'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Memory Usage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildInfoItem('RSS', _deploymentInfo['memory']['rss'] ?? 'Unknown'),
              _buildInfoItem('Heap Total', _deploymentInfo['memory']['heapTotal'] ?? 'Unknown'),
              _buildInfoItem('Heap Used', _deploymentInfo['memory']['heapUsed'] ?? 'Unknown'),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, [Color? valueColor]) {
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
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
