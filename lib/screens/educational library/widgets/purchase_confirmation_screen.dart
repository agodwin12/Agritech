import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../model/ebook_model.dart';

class PurchaseConfirmationScreen extends StatefulWidget {
  final Ebook ebook;

  const PurchaseConfirmationScreen({Key? key, required this.ebook}) : super(key: key);

  @override
  State<PurchaseConfirmationScreen> createState() => _PurchaseConfirmationScreenState();
}

class _PurchaseConfirmationScreenState extends State<PurchaseConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  bool isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found. Please log in again.')),
        );
        setState(() => isLoading = false);
        return;
      }

      final api = ApiService(token: token);
      final success = await api.submitPurchaseForm(
        ebookId: widget.ebook.id.toString(),
        address: _addressController.text,
        phone: _phoneController.text,
        note: _noteController.text,
      );

      setState(() => isLoading = false);

      if (success) {
        Navigator.pop(context, true); // signal success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Confirmation', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                widget.ebook.title,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Icon(Icons.payment),
                label: Text(
                  isLoading ? 'Processing...' : 'Pay Now',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
