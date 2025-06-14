import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/ebook_model.dart';
import '../payment_checkout_screen.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../utils/constants.dart';

class EbookViewerDialog extends StatefulWidget {
  final Ebook ebook;
  final String baseUrl;
  final VoidCallback? onPurchase;
  final VoidCallback? onPreview;
  final VoidCallback? onCartUpdate;

  const EbookViewerDialog({
    Key? key,
    required this.ebook,
    required this.baseUrl,
    this.onPurchase,
    this.onPreview,
    this.onCartUpdate,
  }) : super(key: key);

  @override
  State<EbookViewerDialog> createState() => _EbookViewerDialogState();
}

class _EbookViewerDialogState extends State<EbookViewerDialog> {
  bool _isInCart = false;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
  }

  void _checkCartStatus() {
    setState(() {
      _isInCart = CartService.instance.isInCart(widget.ebook.id.toString());
    });
  }

  Future<void> _toggleCart() async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      bool success;
      String message;
      Color snackBarColor;

      if (_isInCart) {
        // Remove from cart
        success = await CartService.instance.removeFromCart(widget.ebook.id.toString());
        message = success ? 'Removed from cart' : 'Failed to remove from cart';
        snackBarColor = success ? Colors.orange : Colors.red;
      } else {
        // Add to cart
        success = await CartService.instance.addToCart(widget.ebook);
        message = success ? 'Added to cart!' : 'Already in cart';
        snackBarColor = success ? Colors.green : Colors.orange;
      }

      if (success) {
        setState(() {
          _isInCart = !_isInCart;
        });

        // Notify parent about cart update
        if (widget.onCartUpdate != null) {
          widget.onCartUpdate!();
        }
      }

      _showSnackBar(context, message, snackBarColor);
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColorss.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(child: _buildContent()),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book,
            color: Colors.white,
            size: AppDimensions.iconMd,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.ebook.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cart status indicator
          if (_isInCart)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'In Cart',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEbookPreview(),
            const SizedBox(height: 16),
            _buildEbookDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildEbookPreview() {
    final coverImageUrl = widget.ebook.coverImage != null
        ? ApiService.getFullUrl(widget.ebook.coverImage!)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColorss.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: coverImageUrl != null && coverImageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: coverImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildFallbackCover(),
            )
                : _buildFallbackCover(),
          ),
        ),
        const SizedBox(width: 16),

        // Ebook info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.ebook.categoryName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.ebook.categoryName!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    Text(
                      'XAF ${widget.ebook.price}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status badges
              Row(
                children: [
                  if (widget.ebook.isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Approved',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Digital',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            color: Colors.grey[500],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Ebook',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEbookDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColorss.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.ebook.description.isNotEmpty
              ? widget.ebook.description
              : 'No description available.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColorss.textSecondary,
            height: 1.5,
          ),
        ),

        if (widget.ebook.createdAt != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColorss.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Published ${_formatDate(widget.ebook.createdAt!)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColorss.textSecondary,
                ),
              ),
            ],
          ),
        ],

        if (widget.ebook.fileUrl != null && widget.ebook.fileUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 16,
                color: Colors.red[600],
              ),
              const SizedBox(width: 4),
              Text(
                'PDF Available',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First row: Preview and Add to Cart
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onPreview != null) {
                      widget.onPreview!();
                    } else {
                      _showSnackBar(
                        context,
                        'Preview: ${widget.ebook.title}',
                        Colors.blue,
                      );
                    }
                  },
                  icon: const Icon(Icons.preview),
                  label: Text(
                    'Preview',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAddingToCart ? null : _toggleCart,
                  icon: _isAddingToCart
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(_isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart),
                  label: Text(
                    _isInCart ? 'Remove from Cart' : 'Add to Cart',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isInCart ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second row: Buy Now (full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentCheckoutScreen.singleEbook(ebook: widget.ebook),
                  ),
                );

                if (result == true && widget.onPurchase != null) {
                  widget.onPurchase!(); // reload state
                }
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(
                'Buy Now - XAF ${widget.ebook.price}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
      ),
    );
  }
}