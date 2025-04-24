import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants.dart';
// Make sure to add these packages to your pubspec.yaml
// permission_handler: ^10.4.5
// external_path: ^1.0.3 (for Android)
// open_file: ^3.3.2 (optional, for opening files)
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
// If on Android, also import:
// import 'package:external_path/external_path.dart';

class DownloadablesPage extends StatefulWidget {
  @override
  _DownloadablesPageState createState() => _DownloadablesPageState();
}

class _DownloadablesPageState extends State<DownloadablesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> categories = [];
  Map<int, List<dynamic>> materialsMap = {};
  bool isLoading = true;
  final String baseUrl = "http://172.19.35.252:5001"; // Replace with your backend IP
  
  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      print("Fetching categories from: $baseUrl/api/materials/categories");
      final response = await http.get(Uri.parse("$baseUrl/api/materials/categories"));
      
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          categories = data;
          _tabController = TabController(length: categories.length, vsync: this);
        });
        
        for (var category in categories) {
          // Check if category has categoryId or categoryID
          int categoryId = category['categoryId'] ?? category['categoryID'];
          print("Fetching materials for category ID: $categoryId");
          await fetchMaterials(categoryId);
        }
        
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load categories: Status ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load categories: $e")),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchMaterials(int categoryId) async {
    try {
      print("Fetching materials from: $baseUrl/api/materials/materials/$categoryId");
      final response = await http.get(Uri.parse("$baseUrl/api/materials/materials/$categoryId"));
      
      print("Materials response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Materials data for category $categoryId: $data");
        
        setState(() {
          materialsMap[categoryId] = data;
        });
      } else {
        print("Error response for materials: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching materials for category $categoryId: $e");
    }
  }

  Future<void> downloadFile(String url, String filename) async {
    // Show downloading started message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Starting download..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      print("📌 Attempting to download from URL: $url");
      
      // Request storage permission (for Android 10 and below)
      var status = await Permission.storage.request();
      bool hasPermission = status.isGranted;
      
      String savePath;
      
      // Determine where to save the file
      if (hasPermission) {
        // Try to use downloads directory first (more accessible to users)
        try {
          // For Android - use external storage if available
          if (Platform.isAndroid) {
            // If using external_path package:
            // String downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
            //   ExternalPath.DIRECTORY_DOWNLOADS
            // );
            // savePath = "$downloadPath/$filename";
            
            // Without external_path package, fallback to app's documents directory
            final Directory appDocDir = await getApplicationDocumentsDirectory();
            savePath = "${appDocDir.path}/$filename";
          } else {
            // For iOS - use documents directory
            final Directory appDocDir = await getApplicationDocumentsDirectory();
            savePath = "${appDocDir.path}/$filename";
          }
          print("📥 Will download to: $savePath");
        } catch (e) {
          print("❌ Error determining save path: $e");
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          savePath = "${appDocDir.path}/$filename";
          print("📥 Falling back to app directory: $savePath");
        }
      } else {
        // If permission denied, use app directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        savePath = "${appDocDir.path}/$filename";
        print("📥 Using app directory (no permission): $savePath");
      }
      
      // Create a dio instance with options
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            'Accept': '*/*',
          },
        ),
      );
      
      // Show a progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Downloading...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Downloading $filename'),
                  ],
                ),
              );
            },
          );
        },
      );

      // Track if the request was successful
      bool downloadSuccess = false;
      
      // Download the file
      try {
        Response response = await dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(0);
              print('Download progress: $progress%');
            }
          },
        );
        
        // Check if response status is success
        if (response.statusCode == 200) {
          downloadSuccess = true;
          // Verify the file exists and log details
          final File downloadedFile = File(savePath);
          if (downloadedFile.existsSync()) {
            print("✅ File exists: ${downloadedFile.existsSync()}");
            print("✅ File size: ${downloadedFile.lengthSync()} bytes");
          } else {
            print("⚠️ File doesn't exist after successful download");
          }
        }
      } catch (e) {
        print("❌ Dio download error: $e");
      } finally {
        // Close the progress dialog
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      
      // Show success or error message
      if (downloadSuccess) {
        final File file = File(savePath);
        if (file.existsSync() && file.lengthSync() > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File downloaded successfully"),
              action: SnackBarAction(
                label: 'OPEN',
                onPressed: () async {
                  try {
                    final result = await OpenFile.open(savePath);
                    print("Open file result: ${result.message}");
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not open file: ${result.message}")),
                      );
                    }
                  } catch (e) {
                    print("❌ Error opening file: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not open file")),
                    );
                  }
                },
              ),
            ),
          );
        } else {
          throw Exception("File download appears successful but file is missing or empty");
        }
      } else {
        throw Exception("Download process failed");
      }
    } catch (e) {
      // Detailed error reporting
      print("❌ Download function error: $e");
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download failed: ${e.toString().length > 100 
              ? e.toString().substring(0, 100) + '...' 
              : e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
          : categories.isEmpty
              ? Center(child: Text("No categories found. Please add categories first."))
              : TabBarView(
                  controller: _tabController,
                  children: categories.map((category) {
                    // Check if category has categoryId or categoryID
                    int categoryId = category['categoryId'] ?? category['categoryID'];
                    final materials = materialsMap[categoryId] ?? [];
                    
                    return materials.isEmpty
                        ? Center(child: Text("No materials found in this category."))
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