// lib/services/permission_service.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionService {
  // Storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status == PermissionStatus.denied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus == PermissionStatus.granted;
      }
      return status == PermissionStatus.granted;
    }
    return true; // iOS doesn't need explicit storage permission
  }

  // Camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  // Photo library permission
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status == PermissionStatus.granted;
  }

  // Microphone permission (for video recording)
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Combined permissions for video recording
  static Future<bool> requestVideoRecordingPermissions() async {
    final Map<Permission, PermissionStatus> permissions = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return permissions.values.every((status) => status == PermissionStatus.granted);
  }

  // Check if permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.granted;
  }

  // Show permission dialog
  static void showPermissionDialog(
      BuildContext context,
      String title,
      String message, {
        VoidCallback? onSettingsPressed,
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (onSettingsPressed != null) {
                onSettingsPressed();
              } else {
                openAppSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Settings',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Predefined dialog messages
  static void showStoragePermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'Storage Permission Required',
      'Storage permission is needed to access and save files on your device.',
    );
  }

  static void showCameraPermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'Camera Permission Required',
      'Camera permission is needed to take photos and record videos.',
    );
  }

  static void showPhotosPermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'Photos Permission Required',
      'Photos permission is needed to access your photo library.',
    );
  }

  static void showMicrophonePermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'Microphone Permission Required',
      'Microphone permission is needed to record audio with videos.',
    );
  }

  // Handle permission request with automatic dialog
  static Future<bool> handlePermissionRequest(
      BuildContext context,
      Permission permission, {
        String? customTitle,
        String? customMessage,
      }) async {
    final status = await permission.request();

    if (status == PermissionStatus.granted) {
      return true;
    }

    if (status == PermissionStatus.permanentlyDenied) {
      String title = customTitle ?? 'Permission Required';
      String message = customMessage ?? 'This permission is required for the app to function properly.';

      // Show dialog for permanently denied permissions
      showPermissionDialog(context, title, message);
      return false;
    }

    return false;
  }

  // Request multiple permissions
  static Future<Map<Permission, bool>> requestMultiplePermissions(
      List<Permission> permissions,
      ) async {
    final Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.map((permission, status) =>
        MapEntry(permission, status == PermissionStatus.granted));
  }

  // Get permission status text for debugging
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }
}