import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'dart:math' as math;
import '../services/rag_alert_service.dart';

class EmergencyFabMenu extends StatefulWidget {
  const EmergencyFabMenu({Key? key}) : super(key: key);

  @override
  _EmergencyFabMenuState createState() => _EmergencyFabMenuState();
}

class _EmergencyFabMenuState extends State<EmergencyFabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Emergency Alert',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to send an emergency ragging alert?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This will notify authorities about an ongoing ragging incident.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This action will:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 6),
                      Expanded(child: Text('Share your current location', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 6),
                      Expanded(child: Text('Include your student details', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.message, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 6),
                      Expanded(child: Text('Send an SMS alert to authorities', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 6),
                      Expanded(child: Text('Record the current time', style: TextStyle(fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _sendEmergencyAlert(),
            child: Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }
  
  // Separated the emergency alert sending into its own method for clarity
  void _sendEmergencyAlert() async {
    // First, close the confirmation dialog
    Navigator.pop(context);
    
    // Show loading dialog with animation
    BuildContext loadingContext = context;
    showDialog(
      context: loadingContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Sending Emergency Alert...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Getting location and sending notification to authorities',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );

    // Send the emergency alert
    final ragAlertService = RagAlertService();
    Map<String, dynamic> result;
      try {
      // Send the emergency alert
      result = await ragAlertService.sendEmergencyAlert();
      
      // Make sure to close the loading dialog after the call completes
      if (Navigator.of(loadingContext).mounted && Navigator.canPop(loadingContext)) {
        Navigator.of(loadingContext).pop();
      }
    } catch (e) {
      print('Error sending emergency alert: $e');
      result = {
        'success': false,
        'error': 'Failed to send alert: $e',
      };
      
      // Close loading dialog on error too
      if (Navigator.of(loadingContext).mounted && Navigator.canPop(loadingContext)) {
        Navigator.of(loadingContext).pop();
      }
    } finally {
      // In case any other error occurred, ensure the dialog is closed
      if (Navigator.of(loadingContext).mounted && Navigator.canPop(loadingContext)) {
        Navigator.of(loadingContext).pop();
      }
    }
    
    // Show appropriate feedback based on the result - only if context is still valid
    if (mounted) {
      _showResultDialog(result);
    }
  }
  
  // Shows the success or error dialog based on the result
  void _showResultDialog(Map<String, dynamic> result) {
    if (result['success']) {
      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Alert Sent Successfully'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your emergency alert has been sent to authorities.'),
                SizedBox(height: 10),
                Divider(),
                // Show alert ID if available from database
                if (result['alertRecord'] != null && 
                    result['alertRecord']['data'] != null &&
                    result['alertRecord']['data']['alertId'] != null)
                  Text('Alert ID: ${result['alertRecord']['data']['alertId']}', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                // Show timestamp preferring the database timestamp if available
                if (result['alertRecord'] != null && 
                    result['alertRecord']['data'] != null &&
                    result['alertRecord']['data']['alertDateTime'] != null)
                  Text('Time: ${result['alertRecord']['data']['alertDateTime']}', 
                      style: TextStyle(fontSize: 12))
                else if (result['timestamp'] != null)
                  Text('Time: ${result['timestamp']}', style: TextStyle(fontSize: 12)),
                // Show location coordinates
                if (result['location'] != null)
                  Text('Location: ${result['location']}', style: TextStyle(fontSize: 12)),
                // Show student details
                if (result['studentName'] != null && result['studentId'] != null)
                  Text('Sent as: ${result['studentName']} (${result['studentId']})', 
                      style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 10),
                Text('Alert Status'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result['error'] != null 
                  ? 'Error: ${result['error']}' 
                  : (result['alertSent'] == true
                    ? 'Alert was sent, but some features may not have worked properly.'
                    : 'Failed to send the alert. Please try again or contact help desk.'),
                ),
                if (result['databaseUpdated'] == false)
                  Text(
                    '\nNote: Location information was not saved to database, but the alert was still sent if possible.',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showRagInquiryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ragging Inquiry',
          style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Would you like to submit a ragging inquiry?'),
            SizedBox(height: 16),
            Text(
              'This will report non-emergency ragging incidents or concerns.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Implement ragging inquiry functionality
              Navigator.pop(context);
              // Show a confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ragging inquiry submitted'),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            child: Text('SUBMIT INQUIRY'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0, right: 4.0),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Label for the group of buttons
          Positioned(
            bottom: 8,
            right: 68,
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Emergency',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Main column for all the buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Only show these two buttons when expanded
              if (_isExpanded) ...[
                // Rag Alert Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: _showEmergencyDialog,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            // Small attention indicator
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Ragging Inquiry Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: _showRagInquiryDialog,
                        child: Center(
                          child: Icon(
                            Icons.question_answer,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Main button with separate functionality for button and arrow
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: _isExpanded ? Colors.grey.shade800 : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main button area - triggers the emergency dialog
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: CircleBorder(),
                          // Main button closes menu when expanded, otherwise shows emergency dialog
                          onTap: _isExpanded ? _toggleExpansion : _showEmergencyDialog,
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: _isExpanded
                                ? Icon(
                                    Icons.close,
                                    key: ValueKey('close'),
                                    color: Colors.white,
                                    size: 34,
                                  )
                                : Icon(
                                    Icons.warning_rounded,
                                    key: ValueKey('warning'),
                                    color: Colors.white,
                                    size: 34,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Small arrow indicator on the bottom right - toggles menu expansion
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // Toggle the expansion separately from the main button
                          _toggleExpansion();
                        },
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (_, child) {
                                return Transform.rotate(
                                  angle: _animationController.value * math.pi,
                                  child: Icon(
                                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}