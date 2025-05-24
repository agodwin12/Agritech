// lib/widgets/content_grid.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/ebook_model.dart';
import '../model/video_model.dart';
import '../utils/constants.dart';
import 'content_card.dart';

class ContentGrid extends StatelessWidget {
  final List<dynamic> content; // List of Ebook or Video objects
  final bool isVideo;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(dynamic) onContentTap;
  final Function(dynamic)? onPurchase;
  final String? emptyStateTitle;
  final String? emptyStateSubtitle;

  const ContentGrid({
    Key? key,
    required this.content,
    required this.isVideo,
    required this.isLoading,
    required this.onRefresh,
    required this.onContentTap,
    this.onPurchase,
    this.emptyStateTitle,
    this.emptyStateSubtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    }

    if (content.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColorss.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppConstants.gridCrossAxisCount,
          childAspectRatio: isVideo ? 0.8 : 0.7,
          crossAxisSpacing: AppConstants.gridCrossAxisSpacing,
          mainAxisSpacing: AppConstants.gridMainAxisSpacing,
        ),
        itemCount: content.length,
        itemBuilder: (context, index) {
          final item = content[index];
          return ContentCard(
            content: item,
            isVideo: isVideo,
            onTap: () => onContentTap(item),
            onPurchase: onPurchase != null ? () => onPurchase!(item) : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridCrossAxisCount,
        childAspectRatio: isVideo ? 0.8 : 0.7,
        crossAxisSpacing: AppConstants.gridCrossAxisSpacing,
        mainAxisSpacing: AppConstants.gridMainAxisSpacing,
      ),
      itemCount: 6, // Show 6 skeleton cards while loading
      itemBuilder: (context, index) {
        return ContentCardSkeleton(isVideo: isVideo);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final title = emptyStateTitle ??
        (isVideo ? 'No Videos Found' : 'No Ebooks Found');
    final subtitle = emptyStateSubtitle ??
        (isVideo
            ? 'No videos available in this category'
            : 'No ebooks available in this category');

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColorss.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVideo ? Icons.video_collection : Icons.book,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'Refresh',
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
          ),
        ),
      ),
    );
  }
}

// Enhanced Skeleton loading widget for content cards
class ContentCardSkeleton extends StatefulWidget {
  final bool isVideo;

  const ContentCardSkeleton({
    Key? key,
    this.isVideo = false,
  }) : super(key: key);

  @override
  State<ContentCardSkeleton> createState() => _ContentCardSkeletonState();
}

class _ContentCardSkeletonState extends State<ContentCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              color: AppColorss.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColorss.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.isVideo ? Icons.play_circle_outline : Icons.book,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                // Content skeleton
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title skeleton
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description skeleton
                        Container(
                          height: 12,
                          width: double.infinity * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: double.infinity * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        // Bottom row skeleton
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 20,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Container(
                              height: 30,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Specialized grid for different content types
class EbookGrid extends StatelessWidget {
  final List<Ebook> ebooks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(Ebook) onEbookTap;
  final Function(Ebook) onPurchase;

  const EbookGrid({
    Key? key,
    required this.ebooks,
    required this.isLoading,
    required this.onRefresh,
    required this.onEbookTap,
    required this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContentGrid(
      content: ebooks,
      isVideo: false,
      isLoading: isLoading,
      onRefresh: onRefresh,
      onContentTap: (content) => onEbookTap(content as Ebook),
      onPurchase: (content) => onPurchase(content as Ebook),
      emptyStateTitle: 'No Ebooks Available',
      emptyStateSubtitle: 'There are no ebooks in this category yet. Check back later or try a different category.',
    );
  }
}

class VideoGrid extends StatelessWidget {
  final List<Video> videos;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(Video) onVideoTap;

  const VideoGrid({
    Key? key,
    required this.videos,
    required this.isLoading,
    required this.onRefresh,
    required this.onVideoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContentGrid(
      content: videos,
      isVideo: true,
      isLoading: isLoading,
      onRefresh: onRefresh,
      onContentTap: (content) => onVideoTap(content as Video),
      emptyStateTitle: 'No Videos Available',
      emptyStateSubtitle: 'There are no videos in this category yet. Check back later or try a different category.',
    );
  }
}

// Grid with search functionality
class SearchableContentGrid extends StatefulWidget {
  final List<dynamic> allContent;
  final bool isVideo;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(dynamic) onContentTap;
  final Function(dynamic)? onPurchase;

  const SearchableContentGrid({
    Key? key,
    required this.allContent,
    required this.isVideo,
    required this.isLoading,
    required this.onRefresh,
    required this.onContentTap,
    this.onPurchase,
  }) : super(key: key);

  @override
  State<SearchableContentGrid> createState() => _SearchableContentGridState();
}

class _SearchableContentGridState extends State<SearchableContentGrid> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredContent = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredContent = widget.allContent;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(SearchableContentGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allContent != oldWidget.allContent) {
      _filterContent(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterContent(_searchController.text);
  }

  void _filterContent(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredContent = widget.allContent;
      } else {
        _filteredContent = widget.allContent.where((item) {
          final title = widget.isVideo
              ? (item as Video).title.toLowerCase()
              : (item as Ebook).title.toLowerCase();
          final description = widget.isVideo
              ? (item as Video).description.toLowerCase()
              : (item as Ebook).description.toLowerCase();
          final searchQuery = query.toLowerCase();

          return title.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ContentGrid(
            content: _filteredContent,
            isVideo: widget.isVideo,
            isLoading: widget.isLoading,
            onRefresh: widget.onRefresh,
            onContentTap: widget.onContentTap,
            onPurchase: widget.onPurchase,
            emptyStateTitle: _isSearching
                ? 'No Results Found'
                : (widget.isVideo ? 'No Videos Found' : 'No Ebooks Found'),
            emptyStateSubtitle: _isSearching
                ? 'Try adjusting your search terms'
                : (widget.isVideo
                ? 'No videos available in this category'
                : 'No ebooks available in this category'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Search ${widget.isVideo ? 'videos' : 'ebooks'}...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: AppColorss.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600]),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppColorss.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppColorss.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(color: AppColorss.borderLight),
          ),
          filled: true,
          fillColor: AppColorss.surface,
        ),
      ),
    );
  }
}

// Advanced Content Grid with filtering and sorting
class AdvancedContentGrid extends StatefulWidget {
  final List<dynamic> allContent;
  final bool isVideo;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(dynamic) onContentTap;
  final Function(dynamic)? onPurchase;

  const AdvancedContentGrid({
    Key? key,
    required this.allContent,
    required this.isVideo,
    required this.isLoading,
    required this.onRefresh,
    required this.onContentTap,
    this.onPurchase,
  }) : super(key: key);

  @override
  State<AdvancedContentGrid> createState() => _AdvancedContentGridState();
}

class _AdvancedContentGridState extends State<AdvancedContentGrid> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredContent = [];
  String _sortBy = 'title'; // title, date, price
  bool _ascending = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredContent = widget.allContent;
    _searchController.addListener(_onSearchChanged);
    _sortContent();
  }

  @override
  void didUpdateWidget(AdvancedContentGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allContent != oldWidget.allContent) {
      _filterAndSortContent(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterAndSortContent(_searchController.text);
  }

  void _filterAndSortContent(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;

      // Filter content
      if (query.isEmpty) {
        _filteredContent = List.from(widget.allContent);
      } else {
        _filteredContent = widget.allContent.where((item) {
          final title = widget.isVideo
              ? (item as Video).title.toLowerCase()
              : (item as Ebook).title.toLowerCase();
          final description = widget.isVideo
              ? (item as Video).description.toLowerCase()
              : (item as Ebook).description.toLowerCase();
          final searchQuery = query.toLowerCase();

          return title.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
      }

      // Sort content
      _sortContent();
    });
  }

  void _sortContent() {
    _filteredContent.sort((a, b) {
      int result = 0;

      switch (_sortBy) {
        case 'title':
          final titleA = widget.isVideo ? (a as Video).title : (a as Ebook).title;
          final titleB = widget.isVideo ? (b as Video).title : (b as Ebook).title;
          result = titleA.compareTo(titleB);
          break;
        case 'date':
          final dateA = widget.isVideo ? (a as Video).createdAt : (a as Ebook).createdAt;
          final dateB = widget.isVideo ? (b as Video).createdAt : (b as Ebook).createdAt;
          if (dateA != null && dateB != null) {
            result = dateA.compareTo(dateB);
          }
          break;
        case 'price':
          if (!widget.isVideo) {
            final priceA = double.tryParse((a as Ebook).price) ?? 0;
            final priceB = double.tryParse((b as Ebook).price) ?? 0;
            result = priceA.compareTo(priceB);
          }
          break;
      }

      return _ascending ? result : -result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child: ContentGrid(
            content: _filteredContent,
            isVideo: widget.isVideo,
            isLoading: widget.isLoading,
            onRefresh: widget.onRefresh,
            onContentTap: widget.onContentTap,
            onPurchase: widget.onPurchase,
            emptyStateTitle: _isSearching
                ? 'No Results Found'
                : (widget.isVideo ? 'No Videos Found' : 'No Ebooks Found'),
            emptyStateSubtitle: _isSearching
                ? 'Try adjusting your search terms or filters'
                : (widget.isVideo
                ? 'No videos available in this category'
                : 'No ebooks available in this category'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'Search ${widget.isVideo ? 'videos' : 'ebooks'}...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: AppColorss.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: AppColorss.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: AppColorss.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(color: AppColorss.borderLight),
              ),
              filled: true,
              fillColor: AppColorss.surface,
            ),
          ),
          const SizedBox(height: 12),
          // Sort Options
          Row(
            children: [
              Text(
                'Sort by:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: AppColorss.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildSortChip('Title', 'title'),
                    _buildSortChip('Date', 'date'),
                    if (!widget.isVideo) _buildSortChip('Price', 'price'),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColorss.primary,
                ),
                onPressed: () {
                  setState(() {
                    _ascending = !_ascending;
                    _sortContent();
                  });
                },
                tooltip: _ascending ? 'Ascending' : 'Descending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColorss.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
            _sortContent();
          });
        }
      },
      selectedColor: AppColorss.primary,
      backgroundColor: Colors.grey[200],
    );
  }
}