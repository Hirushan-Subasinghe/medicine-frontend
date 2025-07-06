import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';

class DebugProfilePage extends StatefulWidget {
  @override
  _DebugProfilePageState createState() => _DebugProfilePageState();
}

class _DebugProfilePageState extends State<DebugProfilePage> {
  Map<String, dynamic>? debugInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDebugInfo();
  }

  Future<void> loadDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all stored values
      final allKeys = prefs.getKeys();
      Map<String, dynamic> storedData = {};
      
      for (String key in allKeys) {
        final value = prefs.get(key);
        storedData[key] = value;
      }
      
      // Try to fetch user data using stored student ID
      final studentId = prefs.getString('student_id') ?? prefs.getString('user_id');
      
      Map<String, dynamic>? userData;
      if (studentId != null) {
        try {
          final response = await http.get(
            Uri.parse("$baseUrl/api/test/test-user/$studentId")
          );
          
          if (response.statusCode == 200) {
            userData = json.decode(response.body);
          }
        } catch (e) {
          print("Error fetching user data: $e");
        }
      }
      
      setState(() {
        debugInfo = {
          'storedData': storedData,
          'userData': userData,
          'baseUrl': baseUrl,
        };
        isLoading = false;
      });
    } catch (e) {
      print("Error loading debug info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Profile Info'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  if (debugInfo != null) ...[
                    _buildSection('Base URL', debugInfo!['baseUrl']?.toString() ?? 'Not set'),
                    
                    _buildSection('Stored Data', debugInfo!['storedData']),
                    
                    if (debugInfo!['userData'] != null)
                      _buildSection('User Data from API', debugInfo!['userData'])
                    else
                      _buildSection('User Data', 'No user data retrieved'),
                  ] else
                    Text('No debug info available'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadDebugInfo,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _formatData(data),
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    if (data is String) return data;
    
    try {
      return JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
