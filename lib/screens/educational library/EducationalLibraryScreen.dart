// lib/screens/educational_library_screen.dart
import 'package:agritech/screens/educational%20library/services/api_service.dart';
import 'package:agritech/screens/educational%20library/utils/constants.dart';
import 'package:agritech/screens/educational%20library/widgets/category_dropdown.dart';
import 'package:agritech/screens/educational%20library/widgets/content_grid.dart';
import 'package:agritech/screens/educational%20library/widgets/ebook_viewer_dialog.dart';
import 'package:agritech/screens/educational%20library/widgets/upload_dialog.dart';
import 'package:agritech/screens/educational%20library/widgets/video_player_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'model/category_model.dart';
import 'model/ebook_model.dart';
import 'model/video_model.dart';


class EducationalLibraryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const EducationalLibraryScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<EducationalLibraryScreen> createState() => _EducationalLibraryScreenState();
}

class _EducationalLibraryScreenState extends State<EducationalLibraryScreen>
    with TickerProviderStateMixin {

  // Controllers and Animation
  late TabController _tabController;
  late ApiService _apiService;

  // Data Lists
  List<Ebook> _ebooks = [];
  List<Video> _videos = [];
  List<Category> _categories = [];

  // State Management
  int _selectedCategoryId = 0;
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = ApiService(token: widget.token);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchCategories(),
      _fetchContent(),
    ]);
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
          _errorMessage = 'Failed to load categories: ${e.toString()}';
        });
        _showErrorSnackBar('Failed to load categories');
      }
    }
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine category ID for API calls
      final categoryId = _selectedCategoryId == 0 ? null : _selectedCategoryId;

      final futures = await Future.wait([
        _apiService.getEbooks(categoryId: categoryId, approved: true),
        _apiService.getVideos(categoryId: categoryId),
      ]);

      if (mounted) {
        setState(() {
          _ebooks = futures[0] as List<Ebook>;
          _videos = futures[1] as List<Video>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content: ${e.toString()}';
        });
        _showErrorSnackBar('Failed to load content');
      }
    }
  }

  Future<void> _onCategoryChanged(int categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    await _fetchContent();
  }

  Future<void> _onRefresh() async {
    await _fetchContent();
  }

  void _onEbookTap(Ebook ebook) {
    showDialog(
      context: context,
      builder: (context) => EbookViewerDialog(
        ebook: ebook,
        baseUrl: ApiService.baseUrl,
        onPurchase: () => _purchaseEbook(ebook),
      ),
    );
  }

  void _onVideoTap(Video video) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(
        video: video,
        baseUrl: ApiService.baseUrl,
      ),
    );
  }

  Future<void> _purchaseEbook(Ebook ebook) async {
    try {
      _showLoadingDialog('Processing purchase...');

      final success = await _apiService.purchaseEbook(ebook.id);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          _showSuccessSnackBar(AppConstants.purchaseSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('Purchase failed: ${e.toString()}');
      }
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => UploadDialog(
        categories: _categories,
        apiService: _apiService,
        onUploadSuccess: () {
          _showSuccessSnackBar(AppConstants.uploadSuccess);
          _fetchContent();
        },
        onUploadError: (error) {
          _showErrorSnackBar('Upload failed: $error');
        },
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColorss.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColorss.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorss.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColorss.surface,
      title: Text(
        'Educational Library',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColorss.textPrimary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColorss.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColorss.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            labelColor: AppColorss.primary,
            unselectedLabelColor: AppColorss.textSecondary,
            tabs: const [
              Tab(text: 'Ebooks'),
              Tab(text: 'Videos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        CategoryDropdown(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          onCategoryChanged: _onCategoryChanged,
          isLoading: _isCategoriesLoading,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              EbookGrid(
                ebooks: _ebooks,
                isLoading: _isLoading,
                onRefresh: _onRefresh,
                onEbookTap: _onEbookTap,
                onPurchase: _purchaseEbook,
              ),
              VideoGrid(
                videos: _videos,
                isLoading: _isLoading,
                onRefresh: _onRefresh,
                onVideoTap: _onVideoTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColorss.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColorss.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColorss.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorss.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showUploadDialog,
      backgroundColor: AppColorss.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: Text(
        'Upload',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}