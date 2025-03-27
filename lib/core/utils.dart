import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';

Future<void> downloadFile(String url, String fileName, BuildContext context) async {
  Dio dio = Dio();
  try {
    var dir = await getApplicationDocumentsDirectory();
    String savePath = "${dir.path}/$fileName";

    await dio.download(url, savePath);
    print("✅ File downloaded to $savePath");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloaded: $fileName")),
    );
  } catch (e) {
    print("❌ Download failed: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Download failed")),
    );
  }
}
