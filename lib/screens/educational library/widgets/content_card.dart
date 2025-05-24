// lib/widgets/content_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../model/ebook_model.dart';
import '../model/video_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ContentCard extends StatelessWidget {
  final dynamic content; // Can be Ebook or Video
  final bool isVideo;
  final VoidCallback onTap;
  final VoidCallback? onPurchase;

  const ContentCard({
    Key? key,
    required this.content,
    required this.isVideo,
    required this.onTap,
    this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColorss.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: AppColorss.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              _buildContentSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = isVideo
        ? (content as Video).thumbnailUrl
        : (content as Ebook).coverImage;

    return Expanded(
      flex: 3,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.borderRadius),
          ),
          child: Stack(
            children: [
              _buildMainImage(imageUrl),
              _buildImageOverlay(),
              _buildCategoryBadge(),
              if (!isVideo) _buildNewBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImage(String? imageUrl) {
    final fullImageUrl = imageUrl != null
        ? ApiService.getFullUrl(imageUrl)
        : null;

    if (fullImageUrl != null && fullImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: fullImageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColorss.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVideo
              ? [Colors.red.withOpacity(0.2), Colors.orange.withOpacity(0.2)]
              : [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideo ? Icons.ondemand_video : Icons.menu_book,
            size: 32,
            color: isVideo ? Colors.red[300] : Colors.blue[300],
          ),
          const SizedBox(height: 8),
          Text(
            isVideo ? 'Video' : 'Ebook',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOverlay() {
    if (!isVideo) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.center,
          end: Alignment.center,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColorss.primary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isVideo ? 'VIDEO' : 'EBOOK',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'NEW',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    final title = isVideo
        ? (content as Video).title
        : (content as Ebook).title;
    final description = isVideo
        ? (content as Video).description
        : (content as Ebook).description;

    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(title),
            const SizedBox(height: 6),
            _buildDescription(description),
            const SizedBox(height: 8),
            _buildBottomRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title.isNotEmpty ? title : 'Untitled',
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(String description) {
    return Expanded(
      child: Text(
        description.isNotEmpty ? description : 'No description available',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
          height: 1.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPriceTag(),
        _buildActionButton(context),
      ],
    );
  }

  Widget _buildPriceTag() {
    if (isVideo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Free',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
      );
    }

    final ebook = content as Ebook;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'XAF ${ebook.price}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.orange[700],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isVideo ? onTap : onPurchase,
      style: ElevatedButton.styleFrom(
        backgroundColor: isVideo ? AppColorss.primary : Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(60, 30),
        elevation: 1,
      ),
      child: Text(
        isVideo ? 'Watch' : 'Buy',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Skeleton loading card for when content is loading
class ContentCardSkeleton extends StatelessWidget {
  const ContentCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  Icons.image,
                  size: 40,
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
    );
  }
}

// Enhanced Content Card with additional features
class EnhancedContentCard extends StatefulWidget {
  final dynamic content;
  final bool isVideo;
  final VoidCallback onTap;
  final VoidCallback? onPurchase;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showRating;

  const EnhancedContentCard({
    Key? key,
    required this.content,
    required this.isVideo,
    required this.onTap,
    this.onPurchase,
    this.onFavorite,
    this.isFavorite = false,
    this.showRating = false,
  }) : super(key: key);

  @override
  State<EnhancedContentCard> createState() => _EnhancedContentCardState();
}

class _EnhancedContentCardState extends State<EnhancedContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            child: ContentCard(
              content: widget.content,
              isVideo: widget.isVideo,
              onTap: widget.onTap,
              onPurchase: widget.onPurchase,
            ),
          ),
        );
      },
    );
  }
}

// Compact Content Card for list view
class CompactContentCard extends StatelessWidget {
  final dynamic content;
  final bool isVideo;
  final VoidCallback onTap;
  final VoidCallback? onPurchase;

  const CompactContentCard({
    Key? key,
    required this.content,
    required this.isVideo,
    required this.onTap,
    this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = isVideo
        ? (content as Video).title
        : (content as Ebook).title;
    final description = isVideo
        ? (content as Video).description
        : (content as Ebook).description;
    final imageUrl = isVideo
        ? (content as Video).thumbnailUrl
        : (content as Ebook).coverImage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? CachedNetworkImage(
              imageUrl: ApiService.getFullUrl(imageUrl),
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(
                isVideo ? Icons.video_library : Icons.book,
                color: Colors.grey[400],
              ),
            )
                : Icon(
              isVideo ? Icons.video_library : Icons.book,
              color: Colors.grey[400],
            ),
          ),
        ),
        title: Text(
          title.isNotEmpty ? title : 'Untitled',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          description.isNotEmpty ? description : 'No description',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isVideo
            ? IconButton(
          icon: const Icon(Icons.play_circle_fill),
          color: AppColorss.primary,
          onPressed: onTap,
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'XAF ${(content as Ebook).price}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            TextButton(
              onPressed: onPurchase,
              child: const Text('Buy'),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}