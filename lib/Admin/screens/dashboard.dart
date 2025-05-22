import 'package:agritech/Admin/screens/admin%20Forum/AdminForum.dart';
import 'package:agritech/Admin/screens/admin%20product/AdminProductScreen.dart';
import 'package:agritech/Admin/screens/admin%20users/AdminUserScreen.dart';
import 'package:agritech/Admin/screens/categories%20management/categoryManagement.dart';
import 'package:agritech/Admin/screens/process%20orders/AdminOrderEditScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for session management
import 'admin ebooks/educational_section_management.dart';
import 'admin management/AdminManagementScreen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String token;

  const AdminDashboardScreen({Key? key, required this.userData, required this.token}) : super(key: key);

  // Method to handle logout
  Future<void> _logout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        );
      },
    );

    try {
      // Clear shared preferences (session data)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pop(context);

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/signin',
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardItems = [
      {
        'title': 'Admins',
        'icon': Icons.admin_panel_settings,
        'description': 'Manage admin accounts and permissions',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
        ),
      },
      {
        'title': 'Products',
        'icon': Icons.shopping_cart,
        'description': 'Manage inventory and product listings',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminProductScreen()));
        }
      },
      {
        'title': 'Users',
        'icon': Icons.people,
        'description': 'View and manage user accounts',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserScreen()));
        }
      },
      {
        'title': 'Forum Chats',
        'icon': Icons.forum,
        'description': 'Monitor and moderate forum discussions',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminForumScreen()));
        }
      },
      {
        'title': 'Categories',
        'icon': Icons.widgets_outlined,
        'description': 'Manage products categories and Sub categories',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryManagementScreen(token: token),
            ),
          );
        }
      },

      {
        'title': 'Orders',
        'icon': Icons.business,
        'description': 'Manage and process in  real-time',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOrdersScreen(token: token),
            ),
          );
        }
      },
      {
        'title': 'Educational Section',
        'icon': Icons.business,
        'description': 'Manage your educational blog',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminEbookModerationScreen(token: token),
            ),
          );
        }
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 0, // No visible app bar, just for status bar
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            actions: [
              // Logout button in the app bar
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                tooltip: 'Logout',
                onPressed: () => _showLogoutConfirmDialog(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Admin Dashboard",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade800,
                      Colors.green.shade600,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -20,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "Welcome back, Admin",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    );
                  }

                  final item = dashboardItems[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: item['onTap'] as VoidCallback,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 32,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item['title'].toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['description'].toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.green.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: dashboardItems.length + 1,
              ),
            ),
          ),
          // Added a logout button at the bottom for additional accessibility
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog before logout
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}