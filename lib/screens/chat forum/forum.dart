import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ForumScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const ForumScreen({Key? key, required this.userData, required this.token}) : super(key: key);

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isSending = false;
  bool _isLoading = true;
  List<dynamic> messages = [];
  final ScrollController _scrollController = ScrollController();

  final String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();

    print("👤 ForumScreen loaded with userData:");
    widget.userData.forEach((key, value) {
      print("➡️ $key: $value");
    });
    print("📌 Extracted user ID: ${widget.userData['id']}");

    fetchMessages();
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();

  }

  Future<void> fetchMessages() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('$baseUrl/api/forum/messages'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() => messages = data['data']);

        // Scroll to bottom after messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().substring(0, 50)}...')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // 🛡️ Check if user ID is valid
    final userId = widget.userData['id'];
    if (userId == null || userId.toString() == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Cannot send message: user ID is missing')),
      );
      return;
    }

    print("🧪 Sending message with user_id: $userId");

    setState(() => _isSending = true);

    try {
      final uri = Uri.parse('$baseUrl/api/forum/messages');
      final request = http.MultipartRequest('POST', uri);

      // Add headers including auth token
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      print("📤 Sending: user_id=${request.fields['user_id']}, text=${request.fields['text']}");

      // ✅ Properly formatted fields
      request.fields['user_id'] = userId.toString();
      request.fields['text'] = text;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _messageController.clear();
        setState(() => _selectedImage = null);
        fetchMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to send message: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💥 Error sending: ${e.toString().substring(0, 50)}...')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }


  Future<void> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: ${e.toString()}')),
      );
    }
  }

  String _getTimeDisplay(String timestamp) {
    final DateTime now = DateTime.now();
    final DateTime messageTime = DateTime.parse(timestamp);
    final Duration difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(messageTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(messageTime);
    } else {
      return DateFormat('MMM d, y').format(messageTime);
    }
  }

  Widget buildMessageCard(dynamic msg, bool isFirstInGroup, bool isLastInGroup) {
    final user = msg['User'];
    final bool isCurrentUser = user['id'] == widget.userData['id'];
    final String? imgUrl = msg['image_url'];
    final String timeDisplay = _getTimeDisplay(msg['createdAt']);

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 12.0 : 2.0,
        bottom: isLastInGroup ? 12.0 : 2.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && isFirstInGroup) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: user['profile_image'] != null
                  ? NetworkImage('$baseUrl${user['profile_image']}')
                  : null,
              child: user['profile_image'] == null
                  ? Icon(Icons.person, size: 20, color: Colors.grey.shade700)
                  : null,
            ),
            SizedBox(width: 8),
          ],
          if (!isCurrentUser && !isFirstInGroup)
            SizedBox(width: 44), // Space for alignment with avatar

          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isFirstInGroup && !isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                    child: Text(
                      user['full_name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg['text'] != null && msg['text'].toString().trim().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              msg['text'],
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        if (imgUrl != null)
                          CachedNetworkImage(
                            imageUrl: '$baseUrl$imgUrl',
                            placeholder: (_, __) => Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                      ],
                    ),
                  ),
                ),

                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                    child: Text(
                      timeDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildMessageBubbles() {
    List<Widget> bubbles = [];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final user = msg['User'];
      final bool isCurrentUser = user['id'] == widget.userData['id'];

      // Determine if this message is part of a group
      bool isFirstInGroup = true;
      bool isLastInGroup = true;

      if (i > 0) {
        // Check if previous message is from the same user
        final prevMsg = messages[i - 1];
        final prevUser = prevMsg['User'];
        if (prevUser['id'] == user['id']) {
          isFirstInGroup = false;
        }
      }

      if (i < messages.length - 1) {
        // Check if next message is from the same user
        final nextMsg = messages[i + 1];
        final nextUser = nextMsg['User'];
        if (nextUser['id'] == user['id']) {
          isLastInGroup = false;
        }
      }

      bubbles.add(buildMessageCard(msg, isFirstInGroup, isLastInGroup));
    }

    return bubbles;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Community ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.background,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: fetchMessages,
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to start a conversation!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 8),
                children: buildMessageBubbles(),
              ),
            ),

            // Image preview
            if (_selectedImage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.0),
                color: Colors.grey.shade100,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Message input area
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.add, color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'gallery',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library, color: colorScheme.primary),
                              SizedBox(width: 8),
                              Text('Gallery'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt, color: colorScheme.primary),
                              SizedBox(width: 8),
                              Text('Camera'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'gallery') {
                          pickImage();
                        } else if (value == 'camera') {
                          takePhoto();
                        }
                      },
                    ),
                  ),

                  SizedBox(width: 8),

                  // Message text field
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: 120, // Limit max height for multi-line messages
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _isSending ? null : sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}