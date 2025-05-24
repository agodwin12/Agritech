// lib/services/file_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'permission_service.dart';

class FileService {
  static final ImagePicker _imagePicker = ImagePicker();

  // PDF file selection
  static Future<File?> pickPdfFile(BuildContext context) async {
    try {
      // Request storage permission
      final hasPermission = await PermissionService.requestStoragePermission();
      if (!hasPermission) {
        PermissionService.showStoragePermissionDialog(context);
        return null;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      rethrow;
    }
  }

  // Image selection with source choice
  static Future<File?> pickImage(
      BuildContext context, {
        bool fromCamera = false,
        int maxWidth = 1024,
        int maxHeight = 1024,
        int imageQuality = 85,
      }) async {
    try {
      bool hasPermission;
      if (fromCamera) {
        hasPermission = await PermissionService.requestCameraPermission();
        if (!hasPermission) {
          PermissionService.showCameraPermissionDialog(context);
          return null;
        }
      } else {
        hasPermission = await PermissionService.requestPhotosPermission();
        if (!hasPermission) {
          PermissionService.showPhotosPermissionDialog(context);
          return null;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Video selection with source choice
  static Future<File?> pickVideo(
      BuildContext context, {
        bool fromCamera = false,
        Duration maxDuration = const Duration(minutes: 10),
      }) async {
    try {
      bool hasPermission;
      if (fromCamera) {
        hasPermission = await PermissionService.requestVideoRecordingPermissions();
        if (!hasPermission) {
          PermissionService.showCameraPermissionDialog(context);
          return null;
        }
      } else {
        hasPermission = await PermissionService.requestPhotosPermission();
        if (!hasPermission) {
          PermissionService.showPhotosPermissionDialog(context);
          return null;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  // Show image source selection dialog
  static Future<File?> showImageSourceDialog(
      BuildContext context, {
        int maxWidth = 1024,
        int maxHeight = 1024,
        int imageQuality = 85,
      }) async {
    try {
      print('🖼️ Showing image source dialog...');

      return await showModalBottomSheet<File?>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      print('📷 Camera option selected');
                      Navigator.pop(context);
                      final file = await pickImage(
                        context,
                        fromCamera: true,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                        imageQuality: imageQuality,
                      );
                      Navigator.pop(context, file);
                    },
                  ),
                  _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      print('🖼️ Gallery option selected');
                      Navigator.pop(context);
                      final file = await pickImage(
                        context,
                        fromCamera: false,
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                        imageQuality: imageQuality,
                      );
                      Navigator.pop(context, file);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('💥 Error in showImageSourceDialog: $e');
      return null;
    }
  }

  // Show video source selection dialog
  static Future<File?> showVideoSourceDialog(
      BuildContext context, {
        Duration maxDuration = const Duration(minutes: 10),
      }) async {
    try {
      print('🎥 Showing video source dialog...');

      return await showModalBottomSheet<File?>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Video Source',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: context,
                    icon: Icons.videocam,
                    label: 'Camera',
                    onTap: () async {
                      print('📹 Video camera option selected');
                      Navigator.pop(context);
                      final file = await pickVideo(
                        context,
                        fromCamera: true,
                        maxDuration: maxDuration,
                      );
                      Navigator.pop(context, file);
                    },
                  ),
                  _buildSourceOption(
                    context: context,
                    icon: Icons.video_library,
                    label: 'Gallery',
                    onTap: () async {
                      print('📱 Video gallery option selected');
                      Navigator.pop(context);
                      final file = await pickVideo(
                        context,
                        fromCamera: false,
                        maxDuration: maxDuration,
                      );
                      Navigator.pop(context, file);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('💥 Error in showVideoSourceDialog: $e');
      return null;
    }
  }

  // Helper method to build source option widget
  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // File validation methods
  static bool isValidImageFile(File file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  static bool isValidVideoFile(File file) {
    final allowedExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', '3gp', 'mkv'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  static bool isValidPdfFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  // Get file size in human readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get file extension
  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  // Get file name without extension
  static String getFileNameWithoutExtension(File file) {
    final fileName = file.path.split('/').last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return fileName;
    return fileName.substring(0, lastDotIndex);
  }

  // Advanced file operations

  // Check if file exists
  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  // Delete file
  static Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Copy file to new location
  static Future<File?> copyFile(File sourceFile, String destinationPath) async {
    try {
      final newFile = await sourceFile.copy(destinationPath);
      return newFile;
    } catch (e) {
      debugPrint('Error copying file: $e');
      return null;
    }
  }

  // Move file to new location
  static Future<File?> moveFile(File sourceFile, String destinationPath) async {
    try {
      final newFile = await sourceFile.rename(destinationPath);
      return newFile;
    } catch (e) {
      debugPrint('Error moving file: $e');
      return null;
    }
  }

  // Get file creation date
  static DateTime? getFileCreationDate(File file) {
    try {
      final stat = file.statSync();
      return stat.modified;
    } catch (e) {
      debugPrint('Error getting file creation date: $e');
      return null;
    }
  }

  // Check if file size is within limit
  static bool isFileSizeValid(File file, int maxSizeInMB) {
    try {
      final bytes = file.lengthSync();
      final sizeInMB = bytes / (1024 * 1024);
      return sizeInMB <= maxSizeInMB;
    } catch (e) {
      debugPrint('Error checking file size: $e');
      return false;
    }
  }

  // Get MIME type based on file extension
  static String getMimeType(File file) {
    final extension = getFileExtension(file);

    switch (extension) {
    // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';

    // Videos
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case '3gp':
        return 'video/3gpp';
      case 'mkv':
        return 'video/x-matroska';

    // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';

      default:
        return 'application/octet-stream';
    }
  }

  // Compress image file (basic compression by reducing quality)
  static Future<File?> compressImage(
      File imageFile, {
        int quality = 70,
        int maxWidth = 1920,
        int maxHeight = 1080,
      }) async {
    try {
      // This is a basic implementation - for production, consider using
      // packages like flutter_image_compress for better compression
      final String fileName = getFileNameWithoutExtension(imageFile);
      final String extension = getFileExtension(imageFile);
      final String tempPath = '${imageFile.parent.path}/${fileName}_compressed.$extension';

      // Use ImagePicker to compress (basic approach)
      final XFile? compressedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (compressedImage != null) {
        return File(compressedImage.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // Pick multiple files
  static Future<List<File>> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: type,
        allowedExtensions: allowedExtensions,
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      return [];
    }
  }

  // Show file info dialog
  static void showFileInfoDialog(BuildContext context, File file) {
    final fileName = file.path.split('/').last;
    final fileSize = getFileSize(file);
    final fileExtension = getFileExtension(file);
    final mimeType = getMimeType(file);
    final creationDate = getFileCreationDate(file);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', fileName),
            _buildInfoRow('Size:', fileSize),
            _buildInfoRow('Type:', fileExtension.toUpperCase()),
            _buildInfoRow('MIME:', mimeType),
            if (creationDate != null)
              _buildInfoRow('Modified:', creationDate.toString().split('.')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}