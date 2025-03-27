import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants.dart';

class DownloadablesPage extends StatefulWidget {
  @override
  _DownloadablesPageState createState() => _DownloadablesPageState();
}

class _DownloadablesPageState extends State<DownloadablesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> categories = [];
  Map<int, List<dynamic>> materialsMap = {};
  bool isLoading = true;

  final String baseUrl = "http://192.168.8.191:5000"; // 🔁 Replace with your backend IP

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/materials/categories"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = data;
          _tabController = TabController(length: categories.length, vsync: this);
        });

        for (var category in categories) {
          await fetchMaterials(category['categoryID']);
        }

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load categories")),
      );
    }
  }

  Future<void> fetchMaterials(int categoryID) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/materials/materials/$categoryID"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          materialsMap[categoryID] = data;
        });
      }
    } catch (e) {
      print("❌ Error fetching materials: $e");
    }
  }

  Future<void> downloadFile(String url, String filename) async {
    try {
      // ✅ Save inside app directory (no permission needed)
      final Directory dir = await getApplicationDocumentsDirectory();
      final String savePath = "${dir.path}/$filename";
      print("📥 Downloading to: $savePath");

      await Dio().download(url, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Downloaded to internal storage")),
      );
    } catch (e) {
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed")),
      );
    }
  }

  @override
  void dispose() {
    if (categories.isNotEmpty) _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text("Downloadables",
           style: TextStyle(color: Colors.white, fontSize: 25)
       ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // ✅ Back button in white
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: isLoading || categories.isEmpty
            ? null
            : TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((cat) => Tab(text: cat['categoryName'])).toList(),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: categories.map((category) {
          final int categoryID = category['categoryID'];
          final materials = materialsMap[categoryID] ?? [];

          return materials.isEmpty
              ? Center(child: Text("No materials found."))
              : ListView.builder(
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
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
                      Icon(Icons.insert_drive_file,
                          color: AppColors.primaryColor, size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material['title'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              material['fileName'],
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.download, color: AppColors.primaryColor),
                        onPressed: () {
                          downloadFile(
                            material['materialLink'],
                            material['fileName'],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

