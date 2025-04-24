import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants.dart'; // This import contains the baseUrl
import 'package:open_file/open_file.dart';

class DownloadablesPage extends StatefulWidget {
  @override
  _DownloadablesPageState createState() => _DownloadablesPageState();
}

class _DownloadablesPageState extends State<DownloadablesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> categories = [];
  Map<int, List<dynamic>> materialsMap = {};
  bool isLoading = true;
  // Removed the baseUrl declaration here, using the one from constants.dart
  
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
    try {
      // Show downloading started message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Starting download..."),
          duration: Duration(seconds: 1),
        ),
      );
      // Get app directory for download - this is guaranteed to work
      final Directory dir = await getApplicationDocumentsDirectory();
      final String savePath = "${dir.path}/$filename";
      print("📥 Downloading to: $savePath");
      
      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
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
      // Download file
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );
      // Close progress dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Verify the file exists
      final File downloadedFile = File(savePath);
      if (downloadedFile.existsSync()) {
        print("✅ File successfully downloaded to: $savePath");
        print("✅ File size: ${downloadedFile.lengthSync()} bytes");
        
        // Show success message with VIEW option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download complete"),
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () async {
                try {
                  // Open the file
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
                    SnackBar(content: Text("Could not open file. Make sure you have the open_file package.")),
                  );
                }
              },
            ),
          ),
        );
      } else {
        throw Exception("File download appeared to succeed but file doesn't exist at $savePath");
      }
    } catch (e) {
      // Close progress dialog if open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: ${e.toString().substring(0, 
            e.toString().length > 100 ? 100 : e.toString().length)}"),
          backgroundColor: Colors.red,
        ),
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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Downloadables", 
          style: TextStyle(color: Colors.white, fontSize: 25)
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (!isLoading && categories.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final isSelected = _tabController.index == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.animateTo(index);
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.activeTabBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categories[index]['categoryName'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          
          // Body
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : categories.isEmpty
                    ? Center(child: Text("No categories found. Please add categories first."))
                    : TabBarView(
                        controller: _tabController,
                        children: categories.map((category) {
                          int categoryId = category['categoryId'] ?? category['categoryID'];
                          final materials = materialsMap[categoryId] ?? [];
                          
                          return materials.isEmpty
                              ? Center(child: Text("No materials found in this category."))
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await fetchMaterials(categoryId);
                                  },
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(8),
                                    itemCount: materials.length,
                                    itemBuilder: (context, index) {
                                      final material = materials[index];
                                      return _buildMaterialItem(material);
                                    },
                                  ),
                                );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(dynamic material) {
    // Get file type icon
    IconData fileIcon = _getFileIcon(material['fileType'] ?? material['fileName'] ?? '');
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: InkWell(
        onTap: () {
          // Show material details or preview
          _showMaterialDetails(material);
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon, color: AppColors.primaryColor, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      material['description'] ?? 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          material['fileName'] ?? 'Unknown file',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.download_rounded, color: AppColors.primaryColor),
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
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    fileType = fileType.toLowerCase();
    
    if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('doc') || fileType.contains('word')) {
      return Icons.description;
    } else if (fileType.contains('xls') || fileType.contains('sheet')) {
      return Icons.table_chart;
    } else if (fileType.contains('ppt') || fileType.contains('presentation')) {
      return Icons.slideshow;
    } else if (fileType.contains('jpg') || fileType.contains('jpeg') || 
              fileType.contains('png') || fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('zip') || fileType.contains('rar') || 
              fileType.contains('7z') || fileType.contains('tar')) {
      return Icons.folder_zip;
    } else if (fileType.contains('mp3') || fileType.contains('wav') || 
              fileType.contains('audio')) {
      return Icons.audio_file;
    } else if (fileType.contains('mp4') || fileType.contains('mov') || 
              fileType.contains('video')) {
      return Icons.video_file;
    } else {
      return Icons.insert_drive_file;
    }
  }

  void _showMaterialDetails(dynamic material) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                material['title'] ?? 'Untitled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              if (material['description'] != null) ...[
                Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(material['description']),
                SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(_getFileIcon(material['fileType'] ?? material['fileName'] ?? ''), 
                      color: AppColors.primaryColor),
                  SizedBox(width: 8),
                  Text(material['fileName'] ?? 'Unknown file'),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      downloadFile(
                        material['materialLink'],
                        material['fileName'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}