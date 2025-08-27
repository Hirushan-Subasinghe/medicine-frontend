import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    print("🧪 Testing backend connection...");
    
    // Test connection to backend
    final response = await http.post(
      Uri.parse("http://10.0.2.2:5002/api/auth/loginWithToken"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idToken": "test-token"}),
    );

    print("📡 Status: ${response.statusCode}");
    print("📡 Response: ${response.body}");
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print("✅ Backend connection successful!");
        print("👤 Test user: ${data['user']['firstName']} ${data['user']['lastName']}");
      }
    }
    
  } catch (e) {
    print("❌ Connection error: $e");
  }
}
