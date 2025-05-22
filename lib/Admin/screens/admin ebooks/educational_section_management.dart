import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminEbookModerationScreen extends StatefulWidget {
  final String token;
  const AdminEbookModerationScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AdminEbookModerationScreen> createState() => _AdminEbookModerationScreenState();
}

class _AdminEbookModerationScreenState extends State<AdminEbookModerationScreen> {
  final String baseUrl = 'http://10.0.2.2:3000/api';
  List<dynamic> pendingEbooks = [];

  @override
  void initState() {
    super.initState();
    fetchPendingEbooks();
  }

  Future<void> fetchPendingEbooks() async {
    final response = await http.get(Uri.parse('$baseUrl/ebooks?approved=false'));
    if (response.statusCode == 200) {
      setState(() => pendingEbooks = jsonDecode(response.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load ebooks')));
    }
  }

  Future<void> approveEbook(int id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/ebooks/$id/approve'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      fetchPendingEbooks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ebook approved')));
    }
  }

  Future<void> rejectEbook(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/ebooks/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      fetchPendingEbooks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ebook rejected')));
    }
  }

  String formatDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('dd MMM yyyy • HH:mm').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Ebook Moderation'),
      ),
      body: pendingEbooks.isEmpty
          ? Center(child: Text('No pending ebooks found.'))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: pendingEbooks.length,
        itemBuilder: (context, index) {
          final ebook = pendingEbooks[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ebook['cover_image'] != null)
                    Center(
                      child: Image.network(
                        ebook['cover_image'],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(ebook['title'] ?? 'Untitled',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(ebook['description'] ?? 'No description'),
                  SizedBox(height: 6),
                  Text('💰 Price: ${ebook['price']}'),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      // Handle link tap
                    },
                    child: Text('📎 File: ${ebook['file_url']}', style: TextStyle(color: Colors.blue)),
                  ),
                  SizedBox(height: 4),
                  Text('👤 Author: ${ebook['User']?['full_name'] ?? "N/A"}'),
                  Text('📞 Phone: ${ebook['User']?['phone'] ?? "N/A"}'),
                  Text('📚 Category: ${ebook['EbookCategory']?['name'] ?? "N/A"}'),

                  Text('🗓️ Submitted: ${formatDate(ebook['createdAt'])}'),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        label: Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => approveEbook(ebook['id']),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text('Reject'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => rejectEbook(ebook['id']),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
