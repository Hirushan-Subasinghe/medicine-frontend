import 'package:flutter/material.dart';
import 'dart:io';

// Dynamic base URL based on platform and environment
String get baseUrl {
  if (Platform.isAndroid) {
    // For Android emulator and real devices - use your computer's IP
    return "http://192.168.56.1:5002";
  } else if (Platform.isIOS) {
    // For iOS simulator and real devices - use your computer's IP
    return "http://192.168.56.1:5002";
  } else {
    // For web or other platforms - use localhost
    return "http://localhost:5002";
  }
}
seUrl {
//   if (Platform.isAndroid) {
//     // For Android emulator and real devices - use your computer's IP
//     return "https://freshersconnect.app/api/";
//   } else if (Platform.isIOS) {
//     // For iOS simulator and real devices - use your computer's IP
//     return "https://freshersconnect.app/api/";
//   } else {
//     // For web or other platforms - use localhost
//     return "https://freshersconnect.app/api/";
//   }
// }

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
