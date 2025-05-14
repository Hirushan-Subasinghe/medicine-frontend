import 'package:flutter/material.dart';
import '../../core/constants.dart';

class EmergencyFabWidget extends StatelessWidget {
  const EmergencyFabWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      onPressed: () {
        // Show a simple dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Emergency Alert'),
            content: Text('This is a test emergency button.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Icon(Icons.warning, color: Colors.white),
    );
  }
}
