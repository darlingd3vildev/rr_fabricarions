import 'dart:io' show File;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error capturing photo from camera: $e');
      rethrow;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking photo from gallery: $e');
      rethrow;
    }
  }

  Future<List<XFile>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      return pickedFiles;
    } catch (e) {
      debugPrint('Error picking multiple photos from gallery: $e');
      rethrow;
    }
  }

  /// Internal helper to upload file to a specific storage reference
  Future<String> _uploadToRef(Reference ref, XFile file, Uint8List bytes) async {
    final SettableMetadata metadata = SettableMetadata(
      contentType: file.mimeType ?? 'image/jpeg',
    );

    UploadTask uploadTask;
    if (!kIsWeb && file.path.isNotEmpty) {
      try {
        final localFile = File(file.path);
        if (await localFile.exists()) {
          uploadTask = ref.putFile(localFile, metadata);
        } else {
          uploadTask = ref.putData(bytes, metadata);
        }
      } catch (_) {
        uploadTask = ref.putData(bytes, metadata);
      }
    } else {
      uploadTask = ref.putData(bytes, metadata);
    }

    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadProductImage(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final String cleanFileName =
        file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

    // List of bucket formats to attempt (default, .appspot.com, .firebasestorage.app)
    final List<FirebaseStorage> storageInstances = [
      FirebaseStorage.instance,
    ];

    try {
      final app = Firebase.app();
      final defaultBucket = app.options.storageBucket ?? '';

      if (defaultBucket.isNotEmpty) {
        if (defaultBucket.endsWith('.firebasestorage.app')) {
          final altBucket =
              defaultBucket.replaceAll('.firebasestorage.app', '.appspot.com');
          storageInstances.add(FirebaseStorage.instanceFor(bucket: altBucket));
          storageInstances
              .add(FirebaseStorage.instanceFor(bucket: 'gs://$altBucket'));
        } else if (defaultBucket.endsWith('.appspot.com')) {
          final altBucket =
              defaultBucket.replaceAll('.appspot.com', '.firebasestorage.app');
          storageInstances.add(FirebaseStorage.instanceFor(bucket: altBucket));
          storageInstances
              .add(FirebaseStorage.instanceFor(bucket: 'gs://$altBucket'));
        }
      }
    } catch (e) {
      debugPrint('Storage instance setup note: $e');
    }

    Object? lastError;

    for (final storage in storageInstances) {
      try {
        final Reference ref = storage.ref().child('products/$fileName');
        final String downloadUrl = await _uploadToRef(ref, file, bytes);
        return downloadUrl;
      } on FirebaseException catch (fe) {
        lastError = fe;
        debugPrint(
            'Upload attempt with bucket "${storage.bucket}" failed: [${fe.code}] ${fe.message}');
        if (fe.code == 'object-not-found' || fe.code == 'bucket-not-found') {
          // Try next bucket
          continue;
        } else {
          rethrow;
        }
      } catch (e) {
        lastError = e;
        debugPrint('Upload attempt failed: $e');
      }
    }

    debugPrint('All Storage upload attempts failed: $lastError');
    throw lastError ??
        Exception(
            'Failed to upload image. Please verify Firebase Storage is enabled in Firebase Console.');
  }

  Future<List<String>> uploadMultipleProductImages(List<XFile> files) async {
    final List<String> urls = [];
    for (final file in files) {
      try {
        final url = await uploadProductImage(file);
        urls.add(url);
      } catch (e) {
        debugPrint('Failed to upload image ${file.name}: $e');
        rethrow;
      }
    }
    return urls;
  }
}
