import 'package:flutter/material.dart';

// Choose the appropriate URL based on your testing environment:

// For Android Emulator (this uses 10.0.2.2 which points to host's localhost):
const String baseUrl = "http://10.0.2.2:5002"; // Using test server port

// For iOS Simulator (uncomment if using iOS simulator):
// const String baseUrl = "http://localhost:5002";

// For Physical Device (uncomment and replace with your computer's IP address):
// const String baseUrl = "http://192.168.x.x:5002"; // Replace with your actual IP

// For testing directly on the same device as server:
// const String baseUrl = "http://localhost:5002";

// For local testing in emulator (uncomment to use local test server):
// const String baseUrl = "http://10.0.2.2:5002";  

// Debug mode (set to true to see detailed logging)
const bool debugMode = true;

class AppColors {
  static const Color primaryColor = Color(0xFF2C5DE1);
  static const Color secondaryColor = Color(0xFF4976F1);
  static const Color textColor = Color(0xFF202020);
  static const Color backgroundColor = Colors.white;
  static const Color activeTabBackground = Color(0xFF6885EC);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 17,
    color: AppColors.primaryColor,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppButtons {
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text, style: AppTextStyles.button),
    );
  }
}
