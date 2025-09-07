import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'dart:math' as math;

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
        title: Text(
          'Emergency Ragging Alert',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to send an emergency ragging alert?'),
            SizedBox(height: 16),
            Text(
              'This will notify authorities about an ongoing ragging incident.',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Implement emergency alert functionality
              Navigator.pop(context);
              // Show a confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('SEND ALERT'),
          ),
        ],
      ),
    );
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
                  'GetButton',
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
                        child: Center(
                          child: Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
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
              
              // Main FAB with separate arrow button
              Container(
                height: 64,
                width: 64,
                child: Stack(
                  children: [
                    // Main button
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: CircleBorder(),
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
                    
                    // Arrow button overlay (only interactive area is the arrow)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: CircleBorder(),
                          onTap: _toggleExpansion,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              shape: BoxShape.circle,
                            ),
                            width: 20,
                            height: 20,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (_, child) {
                                return Transform.rotate(
                                  angle: _animationController.value * math.pi,
                                  child: Icon(
                                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                    color: Colors.white,
                                    size: 12,
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
