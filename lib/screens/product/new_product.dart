import 'dart:io';
import 'package:agritech/models/category.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const AddProductScreen({
    super.key,
    required this.userData,
    required this.token, required List<Category> categories, required Null Function() onProductAdded,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || _image == null) return;

    setState(() => _isUploading = true);

    final uri = Uri.parse("http://10.0.2.2:3000/api/products");
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${widget.token}'
      ..fields['name'] = _nameController.text
      ..fields['price'] = _priceController.text
      ..fields['quantity'] = _quantityController.text
      ..fields['description'] = _descriptionController.text
      ..fields['user_id'] = widget.userData['id'].toString();

    final mimeType = lookupMimeType(_image!.path)!.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image!.path,
      contentType: MediaType(mimeType[0], mimeType[1]),
    ));

    final response = await request.send();
    setState(() => _isUploading = false);

    if (response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value!.isEmpty ? 'Enter product name' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Enter price' : null,
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),
                Center(
                  child: _image == null
                      ? TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Choose Image'),
                    onPressed: _pickImage,
                  )
                      : Image.file(_image!, height: 150),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitProduct,
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Product'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
