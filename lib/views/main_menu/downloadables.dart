import 'package:flutter/material.dart';
import '../../core/constants.dart';

class DownloadablesPage extends StatefulWidget {
  @override
  _DownloadablesPageState createState() => _DownloadablesPageState();
}

class _DownloadablesPageState extends State<DownloadablesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> categories = [
    "Exam Time Tables",
    "Time Tables",
    "Repeat Forms",
    "Lecture Notes",
    "Assignments",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.folder, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Downloadables",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          labelPadding: EdgeInsets.symmetric(horizontal: 12),
          isScrollable: true,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,

          tabs: categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            categories.map((category) => _buildMaterialList(category)).toList(),
      ),
    );
  }

  Widget _buildMaterialList(String category) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: 6, // Placeholder count
      itemBuilder: (context, index) {
        return _buildMaterialItem(
          "Sample File $index",
          "${(index + 1) * 100} MB, ${index + 1} days ago",
        );
      },
    );
  }

  Widget _buildMaterialItem(String fileName, String fileSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              color: AppColors.primaryColor,
              size: 40,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.download, color: AppColors.primaryColor),
              onPressed: () {
                // TODO: Handle file download
              },
            ),
          ],
        ),
      ),
    );
  }
}
