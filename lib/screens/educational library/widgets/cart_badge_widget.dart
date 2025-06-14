// lib/widgets/cart_badge_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../market place/cart_screen.dart';
import '../services/cart_service.dart';


class CartBadgeWidget extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;

  const CartBadgeWidget({
    Key? key,
    this.iconColor,
    this.iconSize = 24,
  }) : super(key: key);

  @override
  State<CartBadgeWidget> createState() => _CartBadgeWidgetState();
}

class _CartBadgeWidgetState extends State<CartBadgeWidget> {
  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _onCartUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = CartService.instance.itemCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(userData: {}, token: '',),
              ),
            );
          },
          icon: Icon(
            Icons.shopping_cart,
            color: widget.iconColor ?? Theme.of(context).iconTheme.color,
            size: widget.iconSize,
          ),
          tooltip: 'Shopping Cart',
        ),
        if (itemCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                itemCount > 99 ? '99+' : itemCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Alternative version without navigation - just shows count
class CartCountBadge extends StatefulWidget {
  final Widget child;

  const CartCountBadge({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<CartCountBadge> createState() => _CartCountBadgeState();
}

class _CartCountBadgeState extends State<CartCountBadge> {
  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _onCartUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = CartService.instance.itemCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (itemCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                itemCount > 99 ? '99+' : itemCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}