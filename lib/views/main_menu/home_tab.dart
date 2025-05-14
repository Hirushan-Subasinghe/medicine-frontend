import 'package:flutter/material.dart';
import '../../core/constants.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home, color: Colors.white),
            SizedBox(width: 8),
            Text("Home", style: TextStyle(color: Colors.white, fontSize: 25)),
          ],
        ),
        backgroundColor: AppColors.primaryColor, // Top bar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserBanner(), // Banner with secondary color now
            _buildCategoriesSection(),
            _buildAdditionalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor, // Changed to secondary color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, Student!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Stay updated with important notifications and quick access to materials.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            children: [
              _buildCategoryItem(Icons.payment, "Payments"),
              _buildCategoryItem(Icons.schedule, "Schedules"),
              _buildCategoryItem(Icons.info, "Information"),
              _buildCategoryItem(Icons.groups, "Social"),
              _buildCategoryItem(Icons.analytics, "Reports"),
              _buildCategoryItem(Icons.event, "Events"),
            ],
          ),
        ],
      ),
    );
  }  Widget _buildAdditionalSection() {
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tools & Features",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                children: [
              _buildCategoryItem(Icons.calculate, "Calculator"),
              _buildCategoryItem(Icons.library_books, "Library"),
              _buildCategoryItem(Icons.support_agent, "Support"),
              _buildCategoryItem(Icons.map, "Campus Map"),
              _buildCategoryItem(Icons.assignment, "Assignments"),              _buildNavigationItem(context, Icons.sms, "SMS Test", '/twilio_test'),
              _buildNavigationItem(context, Icons.warning_amber, "Ragging Alert", '/rag_alert_test'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primaryColor, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildNavigationItem(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(route);
      },
      child: _buildCategoryItem(icon, label),
    );
  }
}
