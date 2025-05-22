import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_tip.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoTip video;

  const VideoPlayerScreen({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _showControls = true;
  double _currentPosition = 0;
  double _videoDuration = 0;
  Timer? _hideControlsTimer;
  bool _isFullScreen = false;
  List<VideoTip> _relatedVideos = [];

  final String baseUrl = 'https://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _fetchRelatedVideos();

    // Enter portrait mode when screen opens
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();

    // Reset orientation settings when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Reset status bar visibility
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = '$baseUrl/${widget.video.videoUrl}';
      _controller = VideoPlayerController.network(videoUrl);

      // Add listener for player events
      _controller.addListener(_videoPlayerListener);

      // Initialize player
      await _controller.initialize();
      await _controller.play();

      setState(() {
        _isInitialized = true;
        _videoDuration = _controller.value.duration.inMilliseconds.toDouble();
      });

      // Auto-hide controls after 3 seconds
      _resetHideControlsTimer();
    } catch (e) {
      print('Error initializing video player: $e');
      // Show error state
    }
  }

  void _videoPlayerListener() {
    // Update current position
    if (_controller.value.isPlaying &&
        _controller.value.position.inMilliseconds > 0) {
      setState(() {
        _currentPosition = _controller.value.position.inMilliseconds.toDouble();
      });
    }

    // Track buffering state
    final bool isBuffering = _controller.value.isBuffering;
    if (isBuffering != _isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    // Auto-replay when video ends
    if (_controller.value.position >= _controller.value.duration) {
      _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();

    // Only start timer if controls are showing
    if (_showControls) {
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
      _resetHideControlsTimer();
    }
  }

  Future<void> _fetchRelatedVideos() async {
    // In a real app, you would fetch related videos from your backend
    // Here we're just simulating with some dummy data
    await Future.delayed(Duration(milliseconds: 800));

    setState(() {
      _relatedVideos = [
        VideoTip(
          id: 2,
          title: 'Crop Rotation Techniques',
          description: 'Learn effective crop rotation strategies for soil health',
          thumbnailUrl: 'assets/images/crop_rotation_thumb.jpg',
          videoUrl: 'videos/crop_rotation.mp4', category: '',
        ),
        VideoTip(
          id: 3,
          title: 'Natural Pest Control',
          description: 'Organic methods to protect your crops from pests',
          thumbnailUrl: 'assets/images/pest_control_thumb.jpg',
          videoUrl: 'videos/pest_control.mp4', category: '',
        ),
        VideoTip(
          id:4,
          title: 'Water Conservation',
          description: 'Efficient irrigation methods to save water',
          thumbnailUrl: 'assets/images/water_conservation_thumb.jpg',
          videoUrl: 'videos/water_conservation.mp4', category: '',
        ),
      ];
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Enter landscape mode and hide status bar
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Return to portrait mode and show status bar
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Video Player',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ],
      ),
      body: _isInitialized
          ? Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: _isFullScreen
                ? MediaQuery.of(context).size.width / MediaQuery.of(context).size.height
                : _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video
                GestureDetector(
                  onTap: _toggleControls,
                  child: VideoPlayer(_controller),
                ),

                // Buffering Indicator
                if (_isBuffering)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),

                // Video Controls Overlay
                if (_showControls)
                  GestureDetector(
                    onTap: () {
                      // Prevent the tap from toggling controls again
                      _resetHideControlsTimer();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top controls (if needed)
                          SizedBox(height: 1),

                          // Center play/pause button
                          IconButton(
                            iconSize: 60,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),

                          // Bottom controls with seekbar
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                // Progress bar
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.0,
                                    trackShape: RoundedRectSliderTrackShape(),
                                    activeTrackColor: Colors.green[700],
                                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                                    thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 8.0,
                                    ),
                                    thumbColor: Colors.green[700],
                                    overlayColor: Colors.green.withOpacity(0.2),
                                    overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 16.0,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _currentPosition,
                                    min: 0.0,
                                    max: _videoDuration,
                                    onChanged: (value) {
                                      setState(() {
                                        _currentPosition = value;
                                      });
                                      _controller.seekTo(Duration(
                                        milliseconds: value.toInt(),
                                      ));
                                      _resetHideControlsTimer();
                                    },
                                  ),
                                ),

                                // Time and fullscreen
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Current time / Total time
                                    Text(
                                      '${_formatDuration(Duration(milliseconds: _currentPosition.toInt()))} / ${_formatDuration(_controller.value.duration)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),

                                    // Fullscreen button
                                    IconButton(
                                      icon: Icon(
                                        _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                        color: Colors.white,
                                      ),
                                      onPressed: _toggleFullScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Info and Related Videos (only in portrait mode)
          if (!_isFullScreen)
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Title
                      Text(
                        widget.video.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Video Description
                      if (widget.video.description != null)
                        Text(
                          widget.video.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(Icons.thumb_up, 'Like'),
                          _buildActionButton(Icons.bookmark, 'Save'),
                          _buildActionButton(Icons.download, 'Download'),
                          _buildActionButton(Icons.share, 'Share'),
                        ],
                      ),

                      Divider(height: 32),

                      // Related Videos
                      Text(
                        'Related Videos',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Related Videos List
                      _relatedVideos.isEmpty
                          ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green[700]!,
                          ),
                        ),
                      )
                          : Column(
                        children: _relatedVideos.map((video) {
                          return _buildRelatedVideoCard(video);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      )
          : Center(
        child: CircularProgressIndicator(
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green[700]),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedVideoCard(VideoTip video) {
    return GestureDetector(
      onTap: () {
        // Navigate to the selected video
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(video: video),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                width: 120,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail
                    video.thumbnailUrl != null
                        ? Image.network(
                      '$baseUrl/${video.thumbnailUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.video_library, color: Colors.grey[600]),
                      ),
                    )
                        : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.video_library, color: Colors.grey[600]),
                    ),

                    // Play icon
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Title and description
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.description != null)
                      Text(
                        video.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}