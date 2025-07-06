import 'package:flutter/material.dart';

const String baseUrl = "http://10.0.2.2:5002"; // Android emulator localhost

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
