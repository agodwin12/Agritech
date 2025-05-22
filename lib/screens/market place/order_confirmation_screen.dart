// lib/screens/market_place/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import '../market 2/market.dart';
import '../navigation bar/navigation_bar.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String token;
  final String orderNumber;

  const OrderConfirmationScreen({
    Key? key,
    required this.userData,
    required this.token,
    required this.orderNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final darkColor = Colors.grey[900]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Thank You!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your order has been placed successfully.',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Order #: $orderNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/feature');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Go to Home'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketplaceScreen(
                          userData: userData,
                          token: token, categoryId: 1,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: isDarkMode,
        darkColor: darkColor,
        primaryColor: primaryColor,
        textColor: textColor,
        currentIndex: 1, // Market tab
        userData: userData,
        token: token,
      ),
    );
  }
}