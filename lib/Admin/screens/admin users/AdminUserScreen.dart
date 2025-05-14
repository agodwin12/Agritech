import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> with SingleTickerProviderStateMixin {
  List<dynamic> users = [];
  bool showBlocked = false;
  bool isLoading = true;
  String? errorMessage;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchUsers();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        showBlocked = _tabController.index == 1;
      });
      fetchUsers();
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      _setError("Failed to access authentication token: ${e.toString()}");
      return null;
    }
  }

  void _setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = showBlocked
          ? '$baseUrl/api/admin/users/blocked'
          : '$baseUrl/api/admin/users';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = showBlocked ? data['blocked_users'] : data['users'];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _setError("Authentication failed. Please log in again.");
      } else {
        _setError("Server error (${response.statusCode}): ${response.reasonPhrase}");
        _showErrorSnackBar("Failed to load users");
      }
    } catch (e) {
      _setError("Network error: ${e.toString()}");
      _showErrorSnackBar("Failed to connect to server");
    }
  }

  Future<void> blockUser(dynamic user) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');

      final userName = user['full_name'] ?? user['email'] ?? 'this user';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 12),
              Text("Block User"),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(text: "Are you sure you want to block "),
                TextSpan(
                  text: userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: "? They will no longer be able to access the platform."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              icon: const Icon(Icons.block),
              label: const Text("BLOCK"),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        ),
      );

      if (confirmed != true) return;

      // Show loading indicator
      final loadingSnackBar = SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text('Blocking ${user['full_name'] ?? 'user'}...'),
          ],
        ),
        duration: const Duration(seconds: 60),
        backgroundColor: Colors.blue.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      );

      final snackBarController = ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/users/${user['id']}/block'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      // Hide the loading snackbar
      snackBarController.close();

      if (response.statusCode == 200) {
        _showSuccessSnackBar("User blocked successfully");
        fetchUsers();
      } else {
        _showErrorSnackBar("Failed to block user: ${response.reasonPhrase}");
      }
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  Future<void> unblockUser(dynamic user) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication token not found');

      final userName = user['full_name'] ?? user['email'] ?? 'this user';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.lock_open, color: Colors.green),
              SizedBox(width: 12),
              Text("Unblock User"),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(text: "Are you sure you want to unblock "),
                TextSpan(
                  text: userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: "? They will regain access to the platform."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              icon: const Icon(Icons.lock_open),
              label: const Text("UNBLOCK"),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        ),
      );

      if (confirmed != true) return;

      // Show loading indicator
      final loadingSnackBar = SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text('Unblocking ${user['full_name'] ?? 'user'}...'),
          ],
        ),
        duration: const Duration(seconds: 60),
        backgroundColor: Colors.blue.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      );

      final snackBarController = ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/${user['id']}/unblock'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      // Hide the loading snackbar
      snackBarController.close();

      if (response.statusCode == 200) {
        _showSuccessSnackBar("User unblocked successfully");
        fetchUsers();
      } else {
        _showErrorSnackBar("Failed to unblock user: ${response.reasonPhrase}");
      }
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  String _getInitials(dynamic user) {
    final name = user['full_name'] ?? '';
    if (name.isEmpty) return '?';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }

    return '?';
  }

  Color _getAvatarColor(dynamic user) {
    // Generate a consistent color based on the user ID
    final id = user['id'] ?? 0;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.orange,
    ];

    return colors[id % colors.length];
  }

  Widget _buildAvatar(dynamic user) {
    final hasProfileImage = user['profile_image'] != null && user['profile_image'].toString().isNotEmpty;
    final profileUrl = hasProfileImage
        ? (user['profile_image'].toString().startsWith('http')
        ? user['profile_image']
        : '$baseUrl${user['profile_image']}')
        : null;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: hasProfileImage ? Colors.grey.shade200 : _getAvatarColor(user),
        child: hasProfileImage
            ? ClipOval(
          child: CachedNetworkImage(
            imageUrl: profileUrl!,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                color: Colors.white,
              ),
            ),
            errorWidget: (context, url, error) => Text(
              _getInitials(user),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        )
            : Text(
          _getInitials(user),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final isVerified = user['is_verified'] ?? false;
    final userRole = user['role'] ?? 'User';
    final joinDate = user['created_at'] != null
        ? DateTime.tryParse(user['created_at'])
        : null;
    final formattedJoinDate = joinDate != null
        ? '${joinDate.day}/${joinDate.month}/${joinDate.year}'
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Could navigate to user details if needed
          // Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailsScreen(user: user)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['full_name'] ?? 'No name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: userRole.toLowerCase() == 'admin'
                                ? Colors.purple.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userRole,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: userRole.toLowerCase() == 'admin'
                                  ? Colors.purple.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Joined $formattedJoinDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!showBlocked)
                IconButton(
                  icon: const Icon(Icons.block),
                  color: Colors.red.shade400,
                  tooltip: 'Block user',
                  onPressed: () => blockUser(user),
                )
              else
                IconButton(
                  icon: const Icon(Icons.lock_open),
                  color: Colors.green.shade400,
                  tooltip: 'Unblock user',
                  onPressed: () => unblockUser(user),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showBlocked ? Icons.lock_open : Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              showBlocked
                  ? 'No blocked users found'
                  : 'No users found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              showBlocked
                  ? 'When you block users, they will appear here'
                  : 'Add users to your platform to manage them here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get filteredUsers {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final name = (user['full_name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: (_) {
            setState(() {
              _isSearching = false;
            });
          },
        )
            : const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search users',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh users',
            onPressed: fetchUsers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Active Users',
            ),
            Tab(
              icon: Icon(Icons.block),
              text: 'Blocked Users',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null
            ? _buildErrorState()
            : filteredUsers.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            return _buildUserCard(filteredUsers[index]);
          },
        ),
      ),
    );
  }
}