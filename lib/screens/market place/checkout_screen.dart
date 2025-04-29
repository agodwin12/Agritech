// lib/screens/market_place/checkout_screen.dart
import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/api_service.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.userData,
    required this.token,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  // Shipping information
  final TextEditingController _addressController = TextEditingController();
  String _shippingMethod = 'standard';
  String _paymentMethod = 'cash_on_delivery';
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000', // Replace with your actual API URL
      token: widget.token,
    );

    // Pre-fill with user data if available
    if (widget.userData['address'] != null) {
      _addressController.text = widget.userData['address'];
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, simulate API call with delay
      // You need to implement the createOrder method in ApiService
      // await _apiService.createOrder(
      //   _addressController.text,
      //   _shippingMethod,
      //   _paymentMethod,
      //   _notesController.text.isEmpty ? null : _notesController.text,
      // );

      // Simulate API call with delay
      await Future.delayed(const Duration(seconds: 2));

      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}';

      setState(() {
        _isLoading = false;
      });

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              userData: widget.userData,
              token: widget.token,
              orderNumber: orderNumber,
            ),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity} x ${item.product.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )).toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${widget.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Shipping Information
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your shipping address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Shipping Method
              const Text(
                'Shipping Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              RadioListTile<String>(
                title: const Text('Standard Shipping (3-5 days)'),
                subtitle: const Text('\$5.00'),
                value: 'standard',
                groupValue: _shippingMethod,
                onChanged: (value) {
                  setState(() {
                    _shippingMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Express Shipping (1-2 days)'),
                subtitle: const Text('\$15.00'),
                value: 'express',
                groupValue: _shippingMethod,
                onChanged: (value) {
                  setState(() {
                    _shippingMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              RadioListTile<String>(
                title: const Text('Cash on Delivery'),
                value: 'cash_on_delivery',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Mobile Money'),
                value: 'mobile_money',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Order Notes
              const Text(
                'Order Notes (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Special instructions for delivery',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}