import 'dart:convert';
import 'package:agritech/screens/my%20Products/userProductDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MyProductsScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const MyProductsScreen({
    Key? key,
    required this.token,
    required this.userData,
  }) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> products = [];
  bool isLoading = true;

  Future<void> fetchMyProducts() async {
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/my-products'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        products = data['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Failed to load products: ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Products")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchMyProducts,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            // Safely parse images field
            List<dynamic> imageList = [];
            final imagesField = product['images'];

            if (imagesField is String) {
              try {
                imageList = jsonDecode(imagesField);
              } catch (e) {
                print('Error decoding images for product $index: $e');
                imageList = [];
              }
            } else if (imagesField is List) {
              imageList = imagesField;
            }

            String? imageUrl = imageList.isNotEmpty
                ? 'http://10.0.2.2:3000${imageList[0]}'
                : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, size: 50),
                )
                    : Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, size: 30),
                ),
                title: Text(
                  product['name'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("XAF ${product['price']}"),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProductDetailsScreen(
                        product: product,
                        userData: widget.userData,
                        token: widget.token,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
