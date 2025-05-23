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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingEbooks();
  }

  Future<void> fetchPendingEbooks() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/ebooks?approved=false'));
      if (response.statusCode == 200) {
        setState(() {
          pendingEbooks = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ebooks')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> approveEbook(int id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/ebooks/$id/approve'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      fetchPendingEbooks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ebook approved')),
      );
    }
  }

  Future<void> rejectEbook(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/ebooks/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      fetchPendingEbooks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ebook rejected')),
      );
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Pending Ebook Moderation'),
        ),
        elevation: 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pendingEbooks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending ebooks found.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout based on screen width
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 900;

          // Calculate number of columns for grid
          int crossAxisCount = 1;
          if (isDesktop) {
            crossAxisCount = 3;
          } else if (isTablet) {
            crossAxisCount = 2;
          }

          // Use GridView for larger screens, ListView for mobile
          if (isTablet || isDesktop) {
            return GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: pendingEbooks.length,
              itemBuilder: (context, index) => _buildEbookCard(
                pendingEbooks[index],
                constraints,
              ),
            );
          }

          // ListView for mobile
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 400 ? 16 : 12,
              vertical: 12,
            ),
            itemCount: pendingEbooks.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildEbookCard(pendingEbooks[index], constraints),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEbookCard(dynamic ebook, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              if (ebook['cover_image'] != null)
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: isSmallScreen ? 120 : 150,
                      maxWidth: isSmallScreen ? 120 : 150,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ebook['cover_image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: isSmallScreen ? 40 : 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Title
              Text(
                ebook['title'] ?? 'Untitled',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),

              // Description
              Text(
                ebook['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),

              // Info Grid
              _buildInfoSection(ebook, isSmallScreen),

              SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(ebook, isSmallScreen, constraints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(dynamic ebook, bool isSmallScreen) {
    final infoStyle = TextStyle(
      fontSize: isSmallScreen ? 13 : 14,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('💰', 'Price', '${ebook['price']}', infoStyle),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            // Handle file URL tap
          },
          child: Row(
            children: [
              Text('📎 ', style: infoStyle),
              Expanded(
                child: Text(
                  'File: ${ebook['file_url']}',
                  style: infoStyle.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        _buildInfoRow('👤', 'Author', ebook['User']?['full_name'] ?? 'N/A', infoStyle),
        SizedBox(height: 4),
        _buildInfoRow('📞', 'Phone', ebook['User']?['phone'] ?? 'N/A', infoStyle),
        SizedBox(height: 4),
        _buildInfoRow('📚', 'Category', ebook['EbookCategory']?['name'] ?? 'N/A', infoStyle),
        SizedBox(height: 4),
        _buildInfoRow('🗓️', 'Submitted', formatDate(ebook['createdAt']), infoStyle),
      ],
    );
  }

  Widget _buildInfoRow(String icon, String label, String value, TextStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon + ' ', style: style),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: style.copyWith(color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic ebook, bool isSmallScreen, BoxConstraints constraints) {
    final buttonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    // Stack buttons vertically on very small screens
    if (constraints.maxWidth < 350) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.check, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Approve',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.green),
            ),
            onPressed: () => approveEbook(ebook['id']),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            icon: Icon(Icons.close, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Reject',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () => rejectEbook(ebook['id']),
          ),
        ],
      );
    }

    // Side by side buttons for larger screens
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: ElevatedButton.icon(
            icon: Icon(Icons.check, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Approve',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.green),
            ),
            onPressed: () => approveEbook(ebook['id']),
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: ElevatedButton.icon(
            icon: Icon(Icons.close, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Reject',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () => rejectEbook(ebook['id']),
          ),
        ),
      ],
    );
  }
}