// lib/widgets/upload_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/category_model.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../utils/constants.dart';
import 'category_dropdown.dart';

class UploadDialog extends StatefulWidget {
  final List<Category> categories;
  final ApiService apiService;
  final VoidCallback onUploadSuccess;
  final Function(String) onUploadError;

  const UploadDialog({
    Key? key,
    required this.categories,
    required this.apiService,
    required this.onUploadSuccess,
    required this.onUploadError,
  }) : super(key: key);

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Form State
  final _formKey = GlobalKey<FormState>();
  int _selectedCategoryId = 0;
  File? _selectedFile;
  File? _selectedCover;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      print('📄 Attempting to pick PDF file...');
      final file = await FileService.pickPdfFile(context);
      if (file != null) {
        print('✅ PDF file selected: ${file.path}');
        print('📊 File size: ${await file.length()} bytes');
        setState(() {
          _selectedFile = file;
        });
        _showSnackBar('PDF file selected: ${file.path.split('/').last}');
      } else {
        print('❌ No PDF file selected');
        _showSnackBar('No PDF file selected', isError: true);
      }
    } catch (e) {
      print('💥 Error picking PDF: $e');
      _showSnackBar('Error selecting PDF: $e', isError: true);
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      print('🖼️ Attempting to pick cover image...');

      // Show action sheet to choose source
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        File? file;
        if (result == 'camera') {
          print('📷 Picking from camera...');
          file = await FileService.pickImage(context, fromCamera: true);
        } else {
          print('🖼️ Picking from gallery...');
          file = await FileService.pickImage(context, fromCamera: false);
        }

        if (file != null) {
          print('✅ Cover image selected: ${file.path}');
          print('📊 File size: ${await file.length()} bytes');
          setState(() {
            _selectedCover = file;
          });
          _showSnackBar('Cover image selected: ${file.path.split('/').last}');
        } else {
          print('❌ No cover image selected');
          _showSnackBar('No cover image selected', isError: true);
        }
      }
    } catch (e) {
      print('💥 Error picking cover image: $e');
      _showSnackBar('Error selecting cover image: $e', isError: true);
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      print('🎥 Attempting to pick video file...');

      // Show action sheet to choose source
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Video Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Record Video'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.video_library),
                title: Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        File? file;
        if (result == 'camera') {
          print('📹 Recording video...');
          file = await FileService.pickVideo(context, fromCamera: true);
        } else {
          print('📱 Picking from gallery...');
          file = await FileService.pickVideo(context, fromCamera: false);
        }

        if (file != null) {
          print('✅ Video file selected: ${file.path}');
          print('📊 File size: ${await file.length()} bytes');
          setState(() {
            _selectedFile = file;
          });
          _showSnackBar('Video file selected: ${file.path.split('/').last}');
        } else {
          print('❌ No video file selected');
          _showSnackBar('No video file selected', isError: true);
        }
      }
    } catch (e) {
      print('💥 Error picking video: $e');
      _showSnackBar('Error selecting video: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _uploadContent(String type) async {
    if (!_validateForm(type)) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      bool success;

      // Simulate initial progress
      setState(() {
        _uploadProgress = 0.1;
        _uploadStatus = 'Validating files...';
      });

      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _uploadProgress = 0.2;
        _uploadStatus = type == AppConstants.contentTypeEbook
            ? 'Uploading ebook...'
            : 'Uploading video...';
      });

      if (type == AppConstants.contentTypeEbook) {
        success = await _uploadEbookWithProgress();
      } else {
        success = await _uploadVideoWithProgress();
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = success ? 1.0 : 0.0;
          _uploadStatus = success ? 'Upload completed!' : 'Upload failed';
        });

        // Close dialog after short delay if successful
        if (success) {
          await Future.delayed(Duration(milliseconds: 1000));
          if (mounted) {
            Navigator.of(context).pop();
            widget.onUploadSuccess();
            _resetForm();
          }
        } else {
          // Reset after showing error
          await Future.delayed(Duration(milliseconds: 2000));
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _uploadStatus = '';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = 'Upload failed: ${e.toString()}';
        });

        widget.onUploadError(e.toString());

        // Reset error message after delay
        Future.delayed(Duration(milliseconds: 3000), () {
          if (mounted) {
            setState(() {
              _uploadStatus = '';
            });
          }
        });
      }
    }
  }

  Future<bool> _uploadEbookWithProgress() async {
    try {
      // Enhanced validation with detailed logging
      print('🔍 Detailed ebook upload validation...');

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final price = _priceController.text.trim();

      print('📝 Form field validation:');
      print('  Title: "${title}" (length: ${title.length}, empty: ${title.isEmpty})');
      print('  Description: "${description}" (length: ${description.length}, empty: ${description.isEmpty})');
      print('  Price: "${price}" (length: ${price.length}, empty: ${price.isEmpty})');
      print('  Category ID: $_selectedCategoryId (zero: ${_selectedCategoryId == 0})');
      print('  Cover image: ${_selectedCover != null ? "✅ Selected" : "❌ Missing"}');
      print('  PDF file: ${_selectedFile != null ? "✅ Selected" : "ℹ️ Optional"}');

      // Detailed field validation
      if (title.isEmpty) {
        throw Exception('Title field is empty');
      }
      if (description.isEmpty) {
        throw Exception('Description field is empty');
      }
      if (price.isEmpty) {
        throw Exception('Price field is empty');
      }
      if (_selectedCategoryId == 0) {
        throw Exception('No category selected');
      }
      if (_selectedCover == null) {
        throw Exception('Cover image not selected');
      }

      // Validate price format
      final priceValue = double.tryParse(price);
      if (priceValue == null || priceValue <= 0) {
        throw Exception('Invalid price format: "$price"');
      }

      print('✅ All validations passed');

      // Update progress through upload stages
      setState(() {
        _uploadProgress = 0.3;
        _uploadStatus = 'Processing cover image...';
      });
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _uploadProgress = 0.5;
        _uploadStatus = 'Uploading to server...';
      });

      print('🚀 Starting API call with validated data...');
      final success = await widget.apiService.uploadEbook(
        title: title,
        description: description,
        price: price,
        categoryId: _selectedCategoryId,
        pdfFile: _selectedFile,
        coverImage: _selectedCover!,
      );

      print('📊 API call completed - Result: $success');

      if (success) {
        setState(() {
          _uploadProgress = 0.9;
          _uploadStatus = 'Upload completed successfully!';
        });
        await Future.delayed(Duration(milliseconds: 500));
      }

      return success;
    } catch (e) {
      print('💥 Error in _uploadEbookWithProgress: $e');
      setState(() {
        _uploadStatus = 'Upload failed: ${e.toString()}';
        _uploadProgress = 0.0;
      });
      rethrow;
    }
  }

  Future<bool> _uploadVideoWithProgress() async {
    try {
      // Update progress through upload stages
      setState(() {
        _uploadProgress = 0.3;
        _uploadStatus = 'Processing video file...';
      });
      await Future.delayed(Duration(milliseconds: 1000));

      setState(() {
        _uploadProgress = 0.6;
        _uploadStatus = 'Uploading video...';
      });

      final success = await widget.apiService.uploadVideo(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
        videoFile: _selectedFile!,
      );

      if (success) {
        setState(() {
          _uploadProgress = 0.8;
          _uploadStatus = 'Generating thumbnail...';
        });
        await Future.delayed(Duration(milliseconds: 1500)); // FFmpeg processing time

        setState(() {
          _uploadProgress = 0.95;
          _uploadStatus = 'Finalizing...';
        });
        await Future.delayed(Duration(milliseconds: 500));
      }

      return success;
    } catch (e) {
      setState(() {
        _uploadStatus = 'Video upload failed: ${e.toString()}';
      });
      rethrow;
    }
  }

  Future<void> _pickImageDirectFromGallery() async {
    try {
      print('🖼️ Direct gallery pick for image...');
      final file = await FileService.pickImage(context, fromCamera: false);
      if (file != null) {
        print('✅ Direct image selected: ${file.path}');
        setState(() {
          _selectedCover = file;
        });
        _showSnackBar('Image selected from gallery: ${file.path.split('/').last}');
      } else {
        print('❌ No image selected from gallery');
        _showSnackBar('No image selected', isError: true);
      }
    } catch (e) {
      print('💥 Error in direct image pick: $e');
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _pickVideoDirectFromGallery() async {
    try {
      print('🎥 Direct gallery pick for video...');
      final file = await FileService.pickVideo(context, fromCamera: false);
      if (file != null) {
        print('✅ Direct video selected: ${file.path}');
        setState(() {
          _selectedFile = file;
        });
        _showSnackBar('Video selected from gallery: ${file.path.split('/').last}');
      } else {
        print('❌ No video selected from gallery');
        _showSnackBar('No video selected', isError: true);
      }
    } catch (e) {
      print('💥 Error in direct video pick: $e');
      _showSnackBar('Error: $e', isError: true);
    }
  }

  bool _validateForm(String type) {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedCategoryId == 0) {
      _showValidationError(AppConstants.categoryRequired);
      return false;
    }

    // Only require cover image for ebooks
    if (type == AppConstants.contentTypeEbook && _selectedCover == null) {
      _showValidationError(AppConstants.coverImageRequired);
      return false;
    }

    if (type == AppConstants.contentTypeVideo && _selectedFile == null) {
      _showValidationError(AppConstants.videoFileRequired);
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColorss.error,
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _selectedCategoryId = 0;
      _selectedFile = null;
      _selectedCover = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isUploading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Upload Content',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabBar(),
              const SizedBox(height: 16),
              SizedBox(
                height: 500,
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColorss.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Ebook'),
          Tab(text: 'Video'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUploadForm(AppConstants.contentTypeEbook),
        _buildUploadForm(AppConstants.contentTypeVideo),
      ],
    );
  }

  Widget _buildUploadForm(String type) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppConstants.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppConstants.descriptionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (type == AppConstants.contentTypeEbook) ...[
              _buildTextField(
                controller: _priceController,
                label: 'Price (XAF)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.priceRequired;
                  }
                  if (double.tryParse(value) == null) {
                    return AppConstants.invalidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            CategoryDropdownForUpload(
              categories: widget.categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: (categoryId) {
                setState(() {
                  _selectedCategoryId = categoryId;
                });
              },
              contentType: type,
              key: ValueKey('${type}_${widget.categories.length}'), // Force rebuild when categories change
            ),
            const SizedBox(height: 12),

            // Only show cover/thumbnail selection for ebooks
            if (type == AppConstants.contentTypeEbook) ...[
              _buildFilePickerButton(
                label: _selectedCover != null
                    ? 'Cover Selected ✓'
                    : 'Select Cover Image *',
                icon: Icons.image,
                onTap: _pickCoverImage,
                isSelected: _selectedCover != null,
                isRequired: true,
              ),
              const SizedBox(height: 8),
            ] else ...[
              // Info message for video thumbnails
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thumbnail will be automatically generated from your video',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (type == AppConstants.contentTypeEbook)
              _buildFilePickerButton(
                label: _selectedFile != null
                    ? 'PDF Selected ✓'
                    : 'Select PDF File (Optional)',
                icon: Icons.picture_as_pdf,
                onTap: _pickPdfFile,
                isSelected: _selectedFile != null,
                isRequired: false,
              )
            else
              _buildFilePickerButton(
                label: _selectedFile != null
                    ? 'Video Selected ✓'
                    : 'Select Video File *',
                icon: Icons.video_file,
                onTap: _pickVideoFile,
                isSelected: _selectedFile != null,
                isRequired: true,
              ),
            const SizedBox(height: 16),
            _buildUploadButton(type),

            // Debug section (remove in production)
            if (!_isUploading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔍 Debug Info:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Title: ${_titleController.text.isEmpty ? "Not set" : "✓ Set"}',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    Text(
                      'Description: ${_descriptionController.text.isEmpty ? "Not set" : "✓ Set"}',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    if (type == AppConstants.contentTypeEbook)
                      Text(
                        'Price: ${_priceController.text.isEmpty ? "Not set" : "✓ Set"}',
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                    Text(
                      'Category: ${_selectedCategoryId == 0 ? "Not selected" : "✓ Selected (ID: $_selectedCategoryId)"}',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    if (type == AppConstants.contentTypeEbook)
                      Text(
                        'Cover Image: ${_selectedCover == null ? "❌ Not selected" : "✅ Selected"}',
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                    Text(
                      '${type == AppConstants.contentTypeEbook ? "PDF File" : "Video File"}: ${_selectedFile == null ? "❌ Not selected" : "✅ Selected"}',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: AppColorss.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorss.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorss.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorss.borderLight),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildFilePickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
    bool isRequired = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : onTap,
        icon: Icon(icon),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            // Show file info if selected
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                _getSelectedFileInfo(label),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColorss.primary.withOpacity(0.1)
              : Colors.grey[100],
          foregroundColor: isSelected
              ? AppColorss.primary
              : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColorss.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  String _getSelectedFileInfo(String label) {
    if (label.contains('Cover') || label.contains('Thumbnail')) {
      if (_selectedCover != null) {
        final fileName = _selectedCover!.path.split('/').last;
        return 'Selected: $fileName';
      }
    } else if (label.contains('PDF')) {
      if (_selectedFile != null) {
        final fileName = _selectedFile!.path.split('/').last;
        return 'Selected: $fileName';
      }
    } else if (label.contains('Video')) {
      if (_selectedFile != null) {
        final fileName = _selectedFile!.path.split('/').last;
        return 'Selected: $fileName';
      }
    }
    return '';
  }

  Widget _buildUploadButton(String type) {
    return Column(
      children: [
        // Progress indicator and status
        if (_isUploading) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                ),
                const SizedBox(height: 12),

                // Progress text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _uploadStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload button
        ElevatedButton(
          onPressed: _isUploading ? null : () => _uploadContent(type),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isUploading ? Colors.grey[400] : AppColorss.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _isUploading ? 0 : 2,
          ),
          child: _isUploading
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Uploading...',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == AppConstants.contentTypeEbook
                    ? Icons.upload_file
                    : Icons.video_call,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Upload ${type == AppConstants.contentTypeEbook ? 'Ebook' : 'Video'}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Cancel button during upload
        if (_isUploading) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isUploading = false;
                _uploadProgress = 0.0;
                _uploadStatus = '';
              });
            },
            child: Text(
              'Cancel Upload',
              style: GoogleFonts.poppins(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}