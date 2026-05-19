import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  late final FirebaseStorage _storage;

  factory PhotoUploadService() {
    return _instance;
  }

  PhotoUploadService._internal() {
    _storage = FirebaseStorage.instance;
  }

  /// Upload single photo to Firebase Storage
  /// Path: storage/photos/tasks/{taskId}/{timestamp}_{filename}
  Future<String?> uploadPhoto({
    required File photoFile,
    required String taskId,
    required String officerId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = photoFile.path.split('/').last;
      final storagePath = 'photos/tasks/$taskId/${timestamp}_$filename';

      final uploadTask = _storage.ref(storagePath).putFile(photoFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Photo uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      return null;
    }
  }

  /// Upload multiple photos for a task
  Future<List<String>> uploadMultiplePhotos({
    required List<File> photoFiles,
    required String taskId,
    required String officerId,
  }) async {
    final urls = <String>[];

    for (var photoFile in photoFiles) {
      try {
        final url = await uploadPhoto(
          photoFile: photoFile,
          taskId: taskId,
          officerId: officerId,
        );

        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        debugPrint('❌ Error uploading photo: $e');
      }
    }

    debugPrint('✅ Uploaded ${urls.length} photos out of ${photoFiles.length}');
    return urls;
  }

  /// Delete photo from Firebase Storage
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      // Extract storage path from download URL
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();

      debugPrint('✅ Photo deleted: $photoUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting photo: $e');
      return false;
    }
  }

  /// Delete all photos for a task
  Future<bool> deleteTaskPhotos(String taskId) async {
    try {
      final ref = _storage.ref('photos/tasks/$taskId');
      final items = await ref.listAll();

      for (var item in items.items) {
        await item.delete();
      }

      debugPrint('✅ All photos deleted for task: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting task photos: $e');
      return false;
    }
  }

  /// Get download URL for a photo
  Future<String?> getPhotoUrl(String photoPath) async {
    try {
      final url = await _storage.ref(photoPath).getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('❌ Error getting photo URL: $e');
      return null;
    }
  }

  /// Check if file exists in storage
  Future<bool> photoExists(String photoPath) async {
    try {
      await _storage.ref(photoPath).getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage info
  Future<Map<String, String>?> getStorageInfo(String taskId) async {
    try {
      final ref = _storage.ref('photos/tasks/$taskId');
      final items = await ref.listAll();

      int totalSize = 0;
      for (var item in items.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return {
        'count': '${items.items.length}',
        'size': '${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      };
    } catch (e) {
      debugPrint('❌ Error getting storage info: $e');
      return null;
    }
  }
}
