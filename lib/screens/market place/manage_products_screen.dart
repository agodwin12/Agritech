// lib/screens/market_place/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final List<Category> categories;
  final VoidCallback onProductAdded;

  const AddProductScreen({
    Key? key,
    required this.userData,
    required this.token,
    required this.categories,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  List<File> _selectedImages = [];
  bool _isFeatured = false;
  bool _isSubmitting = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000', // Replace with your actual API URL
      token: widget.token,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Create product data
        final productData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': _priceController.text, // Pass as string, will be parsed in API
          'stock': _stockController.text, // Pass as string, will be parsed in API
          'unit': _unitController.text,
          'categoryId': _selectedCategoryId,
          'subCategoryId': _selectedSubCategoryId,
          'isFeatured': _isFeatured,
          'sellerId': widget.userData['id'], // Assuming user ID is available in userData
        };

        // Submit product with images
        await _apiService.createProduct(productData, _selectedImages);

        // Call the callback to refresh the marketplace
        widget.onProductAdded();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );

        // Navigate back to marketplace
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Image Preview
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 13,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Image Selection Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product Information
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price and Stock (Row)
              Row(
                children: [
                  // Price
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Stock
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid stock';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit (e.g., kg, piece, bundle)
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g., kg, piece, bundle)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selection
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Category Dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategoryId,
                items: widget.categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedSubCategoryId = null; // Reset subcategory when category changes
                  });
                },
              ),
              const SizedBox(height: 16),

              // Subcategory Dropdown (only shown when category is selected)
              if (_selectedCategoryId != null)
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Subcategory',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubCategoryId,
                  items: widget.categories
                      .firstWhere((cat) => cat.id == _selectedCategoryId,
                      orElse: () => Category(id: -1, name: '', subCategories: []))
                      .subCategories
                      ?.map((subCategory) {
                    return DropdownMenuItem<int>(
                      value: subCategory.id,
                      child: Text(subCategory.name),
                    );
                  })
                      .toList() ?? [],
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCategoryId = value;
                    });
                  },
                ),
              const SizedBox(height: 24),

              // Featured Toggle
              Row(
                children: [
                  const Text('Mark as Featured:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}