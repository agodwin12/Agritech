import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../navigation bar/navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const ProfileScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Color scheme - farm/agriculture themed green colors
  static const Color primaryColor = Color(0xFF2E7D32); // Deep forest green
  static const Color accentColor = Color(0xFF8BC34A);  // Light lime green
  static const Color darkColor = Color(0xFF1B5E20);    // Dark forest green
  static const Color lightColor = Color(0xFFF1F8E9);   // Very light green/cream
  static const Color textDarkColor = Color(0xFF33691E); // Dark green text
  static const Color textLightColor = Color(0xFFDCEDC8); // Light green text
  static const Color cardColor = Color(0xFF1B5E20);    // Dark green for cards in dark mode

  static const String apiUrl = 'http://10.0.2.2:3000/api/myprofile';

  @override
  void initState() {
    super.initState();

    print("🟢 Received user data: ${widget.userData}");
    print("🔐 Received token: ${widget.token}");

    setState(() {
      userData = widget.userData;
      isLoading = false;
    });
  }


  Future<void> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        print('No token found');
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load profile: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? textLightColor : textDarkColor;
    final backgroundColor = isDarkMode ? darkColor : lightColor;
    final cardBackgroundColor = isDarkMode ? cardColor : Colors.white;

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: textColor.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: fetchUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Cover Photo (Same for all users)
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Cover Photo
                  Positioned.fill(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1500382017468-9049fed747ef', // Standard cover photo for all users
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: accentColor,
                        );
                      },
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                'My Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Navigate to edit profile page
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings page
                },
              ),
            ],
          ),

          // Profile Info
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile Image
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: backgroundColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: userData!['profile_image'] != null
                              ? Image.network(
                            userData!['profile_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: accentColor,
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                              : Container(
                            color: accentColor,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // User Full Name
                    Center(
                      child: Text(
                        userData!['full_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // User Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Info
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email',
                            userData!['email'] ?? 'Not specified',
                            textColor,
                          ),
                          const Divider(height: 20),

                          // Phone Info
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone',
                            userData!['phone'] ?? 'Not specified',
                            textColor,
                          ),
                          const Divider(height: 20),

                          // Address Info
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Address',
                            userData!['address'] ?? 'Not specified',
                            textColor,
                          ),
                          const Divider(height: 20),

                          // Date of Birth Info
                          _buildInfoRow(
                            Icons.cake_outlined,
                            'Date of Birth',
                            userData!['date_of_birth'] ?? 'Not specified',
                            textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionButton(
                      'Edit Profile',
                      Icons.edit,
                      primaryColor,
                      textColor,
                          () {
                        // Navigate to edit profile page
                      },
                    ),
                    const Divider(height: 1),
                    _buildActionButton(
                      'Change Password',
                      Icons.lock_outline,
                      primaryColor,
                      textColor,
                          () {
                        // Navigate to change password page
                      },
                    ),
                    const Divider(height: 1),
                    _buildActionButton(
                      'Notification Settings',
                      Icons.notifications_none,
                      primaryColor,
                      textColor,
                          () {
                        // Navigate to notification settings page
                      },
                    ),
                    const Divider(height: 1),
                    _buildActionButton(
                      'Privacy Settings',
                      Icons.privacy_tip_outlined,
                      primaryColor,
                      textColor,
                          () {
                        // Navigate to privacy settings page
                      },
                    ),
                    const Divider(height: 1),
                    _buildActionButton(
                      'Logout',
                      Icons.logout,
                      Colors.redAccent,
                      textColor,
                          () async {
                        // Logout implementation
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('authToken');
                        // Navigate to login screen
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
      // Use the custom navigation bar
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: isDarkMode,
        darkColor: darkColor,
        primaryColor: primaryColor,
        textColor: textColor,
        currentIndex: 3, userData: {}, token: '', // Profile tab
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      Color textColor,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 24,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text,
      IconData icon,
      Color iconColor,
      Color textColor,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}