// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../model/category_model.dart';
import '../model/ebook_model.dart' show Ebook;
import '../model/video_model.dart';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 15);

  final String? _token;

  ApiService({String? token}) : _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers).timeout(timeoutDuration);
  }

  Future<http.Response> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return await http.post(
      uri,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    ).timeout(timeoutDuration);
  }

  // Category methods
  Future<List<Category>> getEbookCategories() async {
    try {
      final response = await _get('ebooks/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson({
          ...json,
          'type': 'ebook',
        })).toList();
      }
      throw Exception('Failed to load ebook categories: ${response.statusCode}');
    } catch (e) {
      print('Error fetching ebook categories: $e');
      rethrow;
    }
  }

  Future<List<Category>> getVideoCategories() async {
    try {
      final response = await _get('videos/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson({
          ...json,
          'type': 'video',
        })).toList();
      }
      throw Exception('Failed to load video categories: ${response.statusCode}');
    } catch (e) {
      print('Error fetching video categories: $e');
      rethrow;
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final futures = await Future.wait([
        getEbookCategories(),
        getVideoCategories(),
      ]);

      final ebookCategories = futures[0];
      final videoCategories = futures[1];

      final Map<String, Category> categoryMap = {};

      // Add ebook categories
      for (final category in ebookCategories) {
        categoryMap[category.name] = category;
      }

      // Merge video categories
      for (final category in videoCategories) {
        if (categoryMap.containsKey(category.name)) {
          // Update existing category to 'both' type
          final existing = categoryMap[category.name]!;
          categoryMap[category.name] = Category(
            id: existing.id,
            name: existing.name,
            type: 'both',
            videoId: category.id,
          );
        } else {
          categoryMap[category.name] = category;
        }
      }

      return categoryMap.values.toList();
    } catch (e) {
      print('Error fetching all categories: $e');
      rethrow;
    }
  }

  // Ebook methods
  Future<List<Ebook>> getEbooks({int? categoryId, bool? approved}) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (approved != null) {
        queryParams['approved'] = approved.toString();
      }

      final response = await _get('ebooks', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ebook.fromJson(json)).toList();
      }
      throw Exception('Failed to load ebooks: ${response.statusCode}');
    } catch (e) {
      print('Error fetching ebooks: $e');
      rethrow;
    }
  }

  Future<bool> purchaseEbook(int ebookId) async {
    try {
      final response = await _post('ebooks/purchase', body: {
        'ebook_id': ebookId,
      });

      if (response.statusCode == 201) {
        return true;
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? errorData['message'] ?? 'Purchase failed');
    } catch (e) {
      print('Error purchasing ebook: $e');
      rethrow;
    }
  }

  // Video methods
  Future<List<Video>> getVideos({int? categoryId}) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null && categoryId > 0) {
        queryParams['category_id'] = categoryId.toString();
      }

      final response = await _get('videos', queryParams: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Video.fromJson(json)).toList();
      }
      throw Exception('Failed to load videos: ${response.statusCode}');
    } catch (e) {
      print('Error fetching videos: $e');
      rethrow;
    }
  }

  Future<bool> uploadEbook({
    required String title,
    required String description,
    required String price,
    required int categoryId,
    File? pdfFile,
    required File coverImage,
  }) async {
    try {
      print('📚 Starting ebook upload (matching backend controller)...');
      print('Backend expects: req.body fields + req.file for PDF');
      print('Title: "$title"');
      print('Description: "$description"');
      print('Price: "$price"');
      print('Category ID: $categoryId');
      print('Has PDF: ${pdfFile != null}');

      final uri = Uri.parse('$baseUrl/ebooks');
      print('Upload URL: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('✅ Authorization header added');
      } else {
        print('⚠️ No valid token provided');
      }

      // Add form fields exactly as backend expects them in req.body
      request.fields['title'] = title.trim();
      request.fields['description'] = description.trim();
      request.fields['price'] = price.trim();
      request.fields['category_id'] = categoryId.toString();

      // For cover_image, the backend expects it in req.body.cover_image
      // Let's try sending the file path or a placeholder
      request.fields['cover_image'] = coverImage.path.split('/').last;

      print('📝 Form fields (req.body):');
      request.fields.forEach((key, value) {
        print('  $key: "$value"');
      });

      // Add PDF file as req.file (optional)
      // Backend uses: req.file?.path, so the field name should be generic
      if (pdfFile != null) {
        try {
          final fileStream = http.ByteStream(pdfFile.openRead());
          final fileSize = await pdfFile.length();

          // Use 'file' as field name since backend checks req.file
          final multipartFile = http.MultipartFile(
            'file', // This creates req.file
            fileStream,
            fileSize,
            filename: pdfFile.path.split('/').last,
          );

          request.files.add(multipartFile);
          print('✅ PDF file added as req.file: ${pdfFile.path.split('/').last} (${fileSize} bytes)');
        } catch (e) {
          print('❌ Error adding PDF file: $e');
          throw Exception('Failed to process PDF file: $e');
        }
      } else {
        print('ℹ️ No PDF file provided (backend allows null)');
      }

      // Add cover image as a separate file too, in case backend needs it
      try {
        final coverStream = http.ByteStream(coverImage.openRead());
        final coverSize = await coverImage.length();

        final coverFile = http.MultipartFile(
          'cover_image_file', // Different field name to avoid conflict
          coverStream,
          coverSize,
          filename: coverImage.path.split('/').last,
        );

        request.files.add(coverFile);
        print('✅ Cover image file added: ${coverImage.path.split('/').last} (${coverSize} bytes)');
      } catch (e) {
        print('❌ Error adding cover image file: $e');
        // Don't throw here since cover_image is in fields
      }

      print('📤 Final request summary:');
      print('  Method: ${request.method}');
      print('  URL: ${request.url}');
      print('  Headers: ${request.headers.keys.toList()}');
      print('  Form fields: ${request.fields.keys.toList()}');
      print('  Files: ${request.files.map((f) => '${f.field}:${f.filename}').toList()}');

      print('📤 Sending request to backend...');
      final streamedResponse = await request.send().timeout(Duration(minutes: 8));
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Backend response received!');
      print('📊 Status: ${response.statusCode}');
      print('📝 Body: ${response.body}');

      // Backend returns 201 for success
      if (response.statusCode == 201) {
        print('🎉 Ebook upload successful!');
        return true;
      } else {
        print('❌ Upload failed');

        // Parse backend error message
        String errorMessage = 'Upload failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? response.body;
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        print('❌ Error details: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('💥 Exception during ebook upload: $e');
      rethrow;
    }
  }

  Future<bool> uploadVideo({
    required String title,
    required String description,
    required int categoryId,
    required File videoFile,
    // Removed thumbnailImage parameter - backend generates it automatically
  }) async {
    try {
      print('🎥 Starting video upload...');
      print('Title: $title');
      print('Category ID: $categoryId');
      print('Video file size: ${await videoFile.length()} bytes');

      final uri = Uri.parse('$baseUrl/videos');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('Authorization header added');
      }

      // Add fields
      request.fields['title'] = title.trim();
      request.fields['description'] = description.trim();
      request.fields['category_id'] = categoryId.toString();

      print('Form fields added: ${request.fields}');

      // Add video file only - no thumbnail required
      final videoStream = http.ByteStream(videoFile.openRead());
      final videoSize = await videoFile.length();
      final videoMultipartFile = http.MultipartFile(
        'video_url',
        videoStream,
        videoSize,
        filename: videoFile.path.split('/').last,
      );
      request.files.add(videoMultipartFile);
      print('Video file added: ${videoFile.path.split('/').last}, Size: $videoSize bytes');

      print('Sending request to: $uri');
      final streamedResponse = await request.send().timeout(Duration(minutes: 10)); // Longer timeout for videos
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Video upload successful!');
        return true;
      } else {
        print('❌ Video upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Error uploading video: $e');
      rethrow;
    }
  }

  // Utility method to get full URL
  static String getFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '$baseUrl/$relativePath';
  }
}