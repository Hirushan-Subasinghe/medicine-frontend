import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(File imageFile, String userId) async {
    // Create a reference under a folder 'profile_images' with filename based on userId.
    final ref = storage.ref().child("profile_images").child("$userId.jpg");
    await ref.putFile(imageFile);
    // Return the download URL of the image.
    return await ref.getDownloadURL();
  }
}
