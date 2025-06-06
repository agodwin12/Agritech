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

import '../advisory/advisory.dart';
import '../navigation bar/navigation_bar.dart';
import '../webinar/user_webinar_screen.dart';
import 'model/category_model.dart';
import 'model/ebook_model.dart';
import 'model/video_model.dart';

enum MenuItem { ebooks, videos, webinars, advisory }

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

class _EducationalLibraryScreenState extends State<EducationalLibraryScreen> {
  // Controllers and Animation
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
  MenuItem _selectedMenuItem = MenuItem.ebooks;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(token: widget.token);
    _initializeData();
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

  String _getSelectedMenuTitle() {
    switch (_selectedMenuItem) {
      case MenuItem.ebooks:
        return 'Ebooks';
      case MenuItem.videos:
        return 'Videos';
      case MenuItem.webinars:
        return 'Webinars';
      case MenuItem.advisory:
        return 'Advisory';
    }
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    switch (_selectedMenuItem) {
      case MenuItem.ebooks:
        return Column(
          children: [
            CategoryDropdown(
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: _onCategoryChanged,
              isLoading: _isCategoriesLoading,
            ),
            Expanded(
              child: EbookGrid(
                ebooks: _ebooks,
                isLoading: _isLoading,
                onRefresh: _onRefresh,
                onEbookTap: _onEbookTap,
                onPurchase: _purchaseEbook,
              ),
            ),
          ],
        );
      case MenuItem.videos:
        return Column(
          children: [
            CategoryDropdown(
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onCategoryChanged: _onCategoryChanged,
              isLoading: _isCategoriesLoading,
            ),
            Expanded(
              child: VideoGrid(
                videos: _videos,
                isLoading: _isLoading,
                onRefresh: _onRefresh,
                onVideoTap: _onVideoTap,
              ),
            ),
          ],
        );
      case MenuItem.webinars:
      case MenuItem.advisory:
      // These are handled by navigation, so return empty content
        return const SizedBox.shrink();
    }
  }

  Widget _buildComingSoonContent(String title, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorss.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColorss.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColorss.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColorss.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re working hard to bring you this feature. Stay tuned for updates!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColorss.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors - you can adjust these based on your app's theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final darkBackgroundColor = Colors.grey[900] ?? Colors.black;
    final primaryColor = AppColorss.primary;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColorss.background,
        body: Row(
          children: [
            // Sidebar
            _buildSidebar(),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildMainAppBar(),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: FarmConnectNavBar(
          isDarkMode: isDarkMode,
          darkColor: darkBackgroundColor,
          primaryColor: primaryColor,
          textColor: textColor,
          currentIndex: 3,
          userData: widget.userData,
          token: widget.token,
        ),
        floatingActionButton: _selectedMenuItem == MenuItem.ebooks || _selectedMenuItem == MenuItem.videos
            ? _buildFloatingActionButton()
            : null,
      ),
    );
  }

  Widget _buildSidebar() {
    final isWideScreen = MediaQuery.of(context).size.width > 768;
    final sidebarWidth = _isSidebarCollapsed ? 46.0 : (isWideScreen ? 200.0 : 160.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColorss.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Header with single toggle
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 3 : 8,
              vertical: _isSidebarCollapsed ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: AppColorss.primary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSidebarCollapsed) ...[
                  // Full header when expanded
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'AgriTech\nLibrary',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                ] else ...[
                  // Collapsed header - just icon
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                // Single toggle button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(
                      _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Menu Items
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 2 : 4),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.book,
                    title: 'Ebooks',
                    menuItem: MenuItem.ebooks,
                    isSelected: _selectedMenuItem == MenuItem.ebooks,
                  ),
                  const SizedBox(height: 2),
                  _buildMenuItem(
                    icon: Icons.play_circle_outline,
                    title: 'Videos',
                    menuItem: MenuItem.videos,
                    isSelected: _selectedMenuItem == MenuItem.videos,
                  ),
                  const SizedBox(height: 2),
                  _buildMenuItem(
                    icon: Icons.meeting_room_sharp,
                    title: 'Webinars',
                    menuItem: MenuItem.webinars,
                    isSelected: false,
                  ),
                  const SizedBox(height: 2),
                  _buildMenuItem(
                    icon: Icons.fact_check,
                    title: 'Advisory',
                    menuItem: MenuItem.advisory,
                    isSelected: false,
                  ),
                ],
              ),
            ),
          ),

          // User Info Section (only when expanded)
          if (!_isSidebarCollapsed)
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColorss.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColorss.primary.withOpacity(0.1),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColorss.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: AppColorss.primary,
                          size: 8,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.userData['name'] ?? 'User',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppColorss.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),

                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required MenuItem menuItem,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        // Handle navigation for webinars and advisory
        if (menuItem == MenuItem.webinars) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserWebinarScreen(
                userData: widget.userData,
                token: widget.token,
              ),
            ),
          );
          return;
        }

        if (menuItem == MenuItem.advisory) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdvisoryScreen(
                userData: widget.userData,
                token: widget.token,
              ),
            ),
          );
          return;
        }

        // Handle local navigation for ebooks and videos
        setState(() {
          _selectedMenuItem = menuItem;
        });

        // Fetch content if switching to ebooks or videos
        if (menuItem == MenuItem.ebooks || menuItem == MenuItem.videos) {
          _fetchContent();
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: _isSidebarCollapsed ? 26 : 22,
        ),
        padding: EdgeInsets.all(_isSidebarCollapsed ? 3 : 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColorss.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: AppColorss.primary.withOpacity(0.3))
              : null,
        ),
        child: _isSidebarCollapsed
            ? Icon(
          icon,
          color: isSelected ? AppColorss.primary : AppColorss.textSecondary,
          size: 10,
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColorss.primary : AppColorss.textSecondary,
                  size: 10,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColorss.primary : AppColorss.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColorss.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColorss.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getSelectedMenuTitle(),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColorss.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Optional: Add search or filter buttons here
        ],
      ),
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