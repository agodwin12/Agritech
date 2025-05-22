import 'dart:convert';
import 'dart:io';
import 'package:agritech/screens/ebooks/ebooks.dart';
import 'package:agritech/screens/educational%20library/EducationalLibraryScreen.dart';
import 'package:agritech/screens/video/videoTips.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package
import '../chat forum/forum.dart';
import '../disease detection/CameraCaptureScreen.dart';
import '../my Products/my_products_screen.dart';
import '../my Products/userProductDetailScreen.dart';
import '../navigation bar/navigation_bar.dart';
import '../users orders/my_orders.dart';
import 'edit_profile.dart';

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

  // Modern color scheme
  static const Color primaryColor = Color(0xFF2E7D32); // Deep forest green
  static const Color accentColor = Color(0xFF66BB6A);  // Medium green
  static const Color highlightColor = Color(0xFF81C784); // Light green
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
  static const Color cardColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color lightTextColor = Color(0xFF424242);

  static const String apiUrl = 'http://10.0.2.2:3000/api/myprofile';

  @override
  void initState() {
    super.initState();

    setState(() {
      userData = widget.userData;
      isLoading = false;
    });
  }

  Future<void> fetchUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? widget.token;

      if (token.isEmpty) {
        print('No token found');
        setState(() {
          isLoading = false;
        });
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


  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // ✅ Clears all saved sessions


      print('✅ Session cleared. Redirecting to login.');

      // Navigate to SignIn and remove all history
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      print('❌ Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool hideOld = true;
    bool hideNew = true;
    bool hideConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change Password',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildPasswordField(
                        controller: oldPasswordController,
                        label: 'Current Password',
                        hideText: hideOld,
                        onToggle: () => setState(() => hideOld = !hideOld),
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: newPasswordController,
                        label: 'New Password',
                        hideText: hideNew,
                        onToggle: () => setState(() => hideNew = !hideNew),
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        hideText: hideConfirm,
                        onToggle: () => setState(() => hideConfirm = !hideConfirm),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2E7D32),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : () async {
                              final oldPass = oldPasswordController.text.trim();
                              final newPass = newPasswordController.text.trim();
                              final confirmPass = confirmPasswordController.text.trim();

                              if (newPass.isEmpty || confirmPass.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill all fields'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('New passwords do not match'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                final response = await http.post(
                                  Uri.parse('http://10.0.2.2:3000/api/users/change-password'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer ${widget.token}',
                                  },
                                  body: jsonEncode({
                                    'oldPassword': oldPass,
                                    'newPassword': newPass,
                                    'phone': userData?['phone'],
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Password changed successfully'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } else {
                                  final err = jsonDecode(response.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err['message'] ?? 'Password change failed'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Network error occurred'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                            child: isLoading
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              'Update ',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool hideText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hideText,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Color(0xFF666666)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            hideText ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFF666666),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }


  // Function to launch social media apps
  Future<void> _launchSocialMedia(String platform, String username) async {
    String url = '';

    // Prepare URL based on platform
    switch (platform) {
      case 'facebook':
        url = 'https://www.facebook.com/$username';
        break;
      case 'instagram':
        url = 'https://www.instagram.com/$username';
        break;
      case 'twitter':
        url = 'https://twitter.com/$username';
        break;
      case 'tiktok':
        url = 'https://www.tiktok.com/@$username';
        break;
      default:
        return;
    }

    // Launch URL in external browser/app
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, universalLinksOnly: true);
    } else {
      // If can't launch app directly, try web version
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Could not launch $url');
        // Show a snackbar or dialog to inform user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $platform'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final dialogBackgroundColor = isDarkMode ? darkCardColor : cardColor;
        final textColor = isDarkMode ? darkTextColor : lightTextColor;

        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              color: textColor,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                logout(); // Call the logout function
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? darkTextColor : lightTextColor;
    final bgColor = isDarkMode ? darkBackgroundColor : backgroundColor;
    final cardBackgroundColor = isDarkMode ? darkCardColor : cardColor;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: primaryColor.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: textColor,
            ),
            onPressed: () {
              // Navigate to settings page
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: fetchUserProfile,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: userData!['profile_image'] != null
                          ? Image.network(
                        userData!['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: accentColor.withOpacity(0.8),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                          : Container(
                        color: accentColor.withOpacity(0.8),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    userData!['full_name'] ?? userData!['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  // User Email
                  Text(
                    userData!['email'] ?? 'No email provided',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Edit Profile Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to edit profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            userData: userData!,
                            token: widget.token,
                            onProfileUpdated: (updatedData) {
                              setState(() {
                                userData = updatedData;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Section
            if (userData!['bio'] != null && userData!['bio'].isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        'About Me',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        userData!['bio'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (userData!['bio'] != null && userData!['bio'].isNotEmpty)
              const SizedBox(height: 24),

            // Social Media Links Section - Redesigned with clickable icons
            if (_hasSocialLinks())
              Container(
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            'Connect With Me',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.link,
                            size: 18,
                            color: primaryColor,
                          )
                        ],
                      ),
                    ),
                    const Divider(),
                    // Social Media Icons in a Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Facebook
                          if (userData!['facebook'] != null && userData!['facebook'].isNotEmpty)
                            _buildSocialMediaIcon(
                              icon: Icons.facebook,
                              backgroundColor: const Color(0xFF1877F2), // Facebook blue
                              platformName: 'facebook',
                              username: userData!['facebook'] ?? '',
                              tooltip: 'Facebook: ${userData!['facebook']}',
                            ),

                          // Instagram
                          if (userData!['instagram'] != null && userData!['instagram'].isNotEmpty)
                            _buildSocialMediaIcon(
                              icon: Icons.camera_alt_rounded,
                              backgroundColor: const Color(0xFFE1306C), // Instagram pink/purple
                              platformName: 'instagram',
                              username: userData!['instagram'] ?? '',
                              tooltip: 'Instagram: ${userData!['instagram']}',
                            ),

                          // Twitter
                          if (userData!['twitter'] != null && userData!['twitter'].isNotEmpty)
                            _buildSocialMediaIcon(
                              icon: Icons.travel_explore, // Twitter/X icon
                              backgroundColor: const Color(0xFF000000), // X Black
                              platformName: 'twitter',
                              username: userData!['twitter'] ?? '',
                              tooltip: 'Twitter: ${userData!['twitter']}',
                            ),

                          // TikTok
                          if (userData!['tiktok'] != null && userData!['tiktok'].isNotEmpty)
                            _buildSocialMediaIcon(
                              icon: Icons.music_note_rounded,
                              backgroundColor: const Color(0xFF000000), // TikTok black
                              platformName: 'tiktok',
                              username: userData!['tiktok'] ?? '',
                              tooltip: 'TikTok: ${userData!['tiktok']}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_hasSocialLinks())
              const SizedBox(height: 24),

            // Profile Information Section
            Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Profile Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Phone Info
                  _buildProfileInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: userData!['phone'] ?? 'Not specified',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                  ),

                  // Address Info
                  _buildProfileInfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    subtitle: userData!['address'] ?? 'Not specified',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account & Settings Section
            Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Account & Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Change Password
                  _buildSettingsTile(
                    icon: Icons.lock_outlined,
                    iconColor: primaryColor,
                    title: 'Change Password',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),

                  // My Products
                  _buildSettingsTile(
                    icon: Icons.shopping_basket_outlined,
                    iconColor: primaryColor,
                    title: 'My Products',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyProductsScreen(
                            userData: widget.userData,
                            token: widget.token,
                          ),

                        ),
                      );
                    },
                  ),
                  // My Orders
                  _buildSettingsTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: primaryColor,
                    title: 'My Orders',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyOrdersScreen(
                            userData: widget.userData,
                            token: widget.token,
                          ),
                        ),
                      );
                    },
                  ),


                  // Forum Menu
                  _buildSettingsTile(
                    icon: Icons.forum_outlined,
                    iconColor: primaryColor,
                    title: 'Forums',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForumScreen(
                            userData: userData!,
                            token: widget.token,
                          ),
                        ),
                      );
                    },
                  ),



                  // Privacy Policy
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: primaryColor,
                    title: 'Privacy Policy',
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    onTap: () {
                      // Navigate to privacy policy
                    },
                  ),



                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _showLogoutConfirmation,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Version Info
            Center(
              child: Text(
                'AgroMarket v1.0.2',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textColor.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: isDarkMode,
        darkColor: darkBackgroundColor,
        primaryColor: primaryColor,
        textColor: textColor,
        currentIndex: 3,
        userData: userData ?? {},
        token: widget.token,
      ),
    );
  }

  // New method for building social media icons
  Widget _buildSocialMediaIcon({
    required IconData icon,
    required Color backgroundColor,
    required String platformName,
    required String username,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _launchSocialMedia(platformName, username),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  bool _hasSocialLinks() {
    return (userData!['facebook'] != null && userData!['facebook'].isNotEmpty) ||
        (userData!['instagram'] != null && userData!['instagram'].isNotEmpty) ||
        (userData!['twitter'] != null && userData!['twitter'].isNotEmpty) ||
        (userData!['tiktok'] != null && userData!['tiktok'].isNotEmpty);
  }

  Widget _buildProfileInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required Color textColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? primaryColor.withOpacity(0.2)
                  : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            indent: 70,
            height: 1,
          ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDarkMode,
    required Color textColor,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? iconColor.withOpacity(0.2)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: textColor.withOpacity(0.4),
                size: 16,
              ),
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            indent: 70,
            height: 1,
          ),
      ],
    );
  }
}