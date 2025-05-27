import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraCaptureScreen extends StatefulWidget {
  final Function(File image) onImageCaptured;

  const CameraCaptureScreen({Key? key, required this.onImageCaptured}) : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _currentCameraIndex = 0;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    // Restore orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      final camera = cameras.length > _currentCameraIndex
          ? cameras[_currentCameraIndex]
          : cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      });
      print("Error initializing camera: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      // Add haptic feedback
      HapticFeedback.mediumImpact();

      widget.onImageCaptured(File(image.path));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        _showErrorSnackBar('Failed to take picture: ${e.toString()}');
      }
      print("Error taking picture: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;

    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
      _isInitialized = false;
    });

    await _controller?.dispose();
    await _initializeCamera();
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(_getResponsiveSize(context, 16)),
      ),
    );
  }

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortestSide = min(screenWidth, screenHeight);

    // Scale based on device size (375 is iPhone 6/7/8 width as baseline)
    final scaleFactor = shortestSide / 375;
    return baseSize * scaleFactor.clamp(0.8, 1.3);
  }

  // Get responsive padding
  EdgeInsets _getResponsivePadding(BuildContext context, {
    double horizontal = 16,
    double vertical = 16,
  }) {
    return EdgeInsets.symmetric(
      horizontal: _getResponsiveSize(context, horizontal),
      vertical: _getResponsiveSize(context, vertical),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: _getResponsiveSize(context, 3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final deviceRatio = size.width / size.height;
        final cameraRatio = _controller!.value.aspectRatio;

        double scale;
        if (deviceRatio > cameraRatio) {
          // Screen is wider than camera aspect ratio
          scale = size.width / (size.height * cameraRatio);
        } else {
          // Screen is taller than camera aspect ratio
          scale = size.height / (size.width / cameraRatio);
        }

        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: AspectRatio(
                aspectRatio: cameraRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: _getResponsivePadding(context, horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: _getResponsiveSize(context, 80),
                color: Colors.white54,
              ),
              SizedBox(height: _getResponsiveSize(context, 24)),
              Text(
                'Camera Error',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: _getResponsiveSize(context, 24),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 12)),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: _getResponsiveSize(context, 16),
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 24)),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: Icon(
                  Icons.refresh,
                  size: _getResponsiveSize(context, 20),
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: _getResponsiveSize(context, 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 24),
                    vertical: _getResponsiveSize(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final controlBarHeight = isSmallScreen ? 100.0 : 120.0;

    return Container(
      height: controlBarHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: _getResponsivePadding(context, horizontal: 24, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildControlButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.photo_library,
                size: _getResponsiveSize(context, 50),
                iconSize: _getResponsiveSize(context, 24),
              ),

              GestureDetector(
                onTap: _isCapturing ? null : _takePicture,
                child: Container(
                  width: _getResponsiveSize(context, 80),
                  height: _getResponsiveSize(context, 80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isCapturing
                      ? Center(
                    child: SizedBox(
                      width: _getResponsiveSize(context, 30),
                      height: _getResponsiveSize(context, 30),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  )
                      : Container(
                    margin: EdgeInsets.all(_getResponsiveSize(context, 8)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[600],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: _getResponsiveSize(context, 32),
                    ),
                  ),
                ),
              ),

              // Switch Camera Button
              _buildControlButton(
                onPressed: cameras.length > 1 ? _switchCamera : null,
                icon: Icons.flip_camera_ios,
                size: _getResponsiveSize(context, 50),
                iconSize: _getResponsiveSize(context, 24),
                isEnabled: cameras.length > 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required double size,
    required double iconSize,
    bool isEnabled = true,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isEnabled
              ? Colors.white
              : Colors.white.withOpacity(0.5),
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final topBarHeight = isSmallScreen ? 80.0 : 100.0;

    return Container(
      height: topBarHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: _getResponsivePadding(context, horizontal: 16, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              _buildTopBarButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.arrow_back_ios,
              ),

              // Title
              Text(
                'Take Photo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: _getResponsiveSize(context, 20),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              // Grid Toggle Button
              _buildTopBarButton(
                onPressed: _toggleGrid,
                icon: _showGrid ? Icons.grid_on : Icons.grid_off,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    final buttonSize = _getResponsiveSize(context, 44);
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: _getResponsiveSize(context, 20),
        ),
      ),
    );
  }

  Widget _buildCameraGrid() {
    if (!_showGrid) return const SizedBox.shrink();

    return CustomPaint(
      painter: ResponsiveGridPainter(context),
      child: Container(),
    );
  }

  Widget _buildFocusIndicator() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          return _hasError
              ? _buildErrorState()
              : Stack(
            children: [
              Positioned.fill(
                child: _buildCameraPreview(),
              ),

              // Camera Grid Overlay
              if (_showGrid)
                Positioned.fill(
                  child: _buildCameraGrid(),
                ),

              // Focus Indicator
              Positioned.fill(
                child: _buildFocusIndicator(),
              ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControlBar(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ResponsiveGridPainter extends CustomPainter {
  final BuildContext context;

  ResponsiveGridPainter(this.context);

  double _getResponsiveStrokeWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base width
    return (1.0 * scaleFactor).clamp(0.5, 2.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = _getResponsiveStrokeWidth();

    final double horizontalSpacing = size.height / 3;
    final double verticalSpacing = size.width / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, i * horizontalSpacing),
        Offset(size.width, i * horizontalSpacing),
        paint,
      );
    }

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(i * verticalSpacing, 0),
        Offset(i * verticalSpacing, size.height),
        paint,
      );
    }

    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = _getResponsiveStrokeWidth() * 2;

    const double centerMarkSize = 10;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(centerX - centerMarkSize, centerY),
      Offset(centerX + centerMarkSize, centerY),
      centerPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - centerMarkSize),
      Offset(centerX, centerY + centerMarkSize),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}