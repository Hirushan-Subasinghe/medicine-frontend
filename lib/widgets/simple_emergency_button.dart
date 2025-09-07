import 'package:flutter/material.dart';

class SimpleEmergencyButton extends StatelessWidget {
  const SimpleEmergencyButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      child: Icon(Icons.warning_amber_rounded, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Emergency Ragging Alert'),
            content: Text('This is a test emergency button for ragging alerts.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
