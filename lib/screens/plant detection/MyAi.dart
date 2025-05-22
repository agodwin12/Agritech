import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class MyAi extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const MyAi({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<MyAi> createState() => _MyAiState();
}

class _MyAiState extends State<MyAi> with TickerProviderStateMixin {
  File? selectedImage;
  bool isAnalyzing = false;
  Map<String, dynamic>? analysisResult;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  final ImagePicker _picker = ImagePicker();

  // Static disease detection results
  final List<Map<String, dynamic>> staticDiseases = [
    {
      'name': 'Leaf Blight',
      'confidence': 0.92,
      'severity': 'Moderate',
      'description': 'A fungal disease that causes brown spots and yellowing of leaves.',
      'treatment': 'Apply copper-based fungicide every 7-10 days. Remove affected leaves.',
      'prevention': 'Ensure proper air circulation and avoid overhead watering.',
      'color': Colors.orange,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'name': 'Powdery Mildew',
      'confidence': 0.88,
      'severity': 'Mild',
      'description': 'White powdery coating on leaves caused by fungal infection.',
      'treatment': 'Spray with neem oil solution or baking soda mixture.',
      'prevention': 'Maintain good ventilation and avoid overcrowding plants.',
      'color': Colors.yellow,
      'icon': Icons.cloud_outlined,
    },
    {
      'name': 'Root Rot',
      'confidence': 0.95,
      'severity': 'Severe',
      'description': 'Fungal infection affecting the root system, causing wilting.',
      'treatment': 'Remove affected roots, repot in fresh soil, reduce watering.',
      'prevention': 'Ensure proper drainage and avoid overwatering.',
      'color': Colors.red,
      'icon': Icons.dangerous_outlined,
    },
  ];

  final List<Map<String, dynamic>> recentAnalyses = [
    {
      'date': '2 hours ago',
      'plant': 'Tomato Plant',
      'disease': 'Early Blight',
      'confidence': 0.94,
      'image': 'https://picsum.photos/400/300?random=21',
    },
    {
      'date': '1 day ago',
      'plant': 'Rose Bush',
      'disease': 'Black Spot',
      'confidence': 0.89,
      'image': 'https://picsum.photos/400/300?random=22',
    },
    {
      'date': '3 days ago',
      'plant': 'Apple Tree',
      'disease': 'Fire Blight',
      'confidence': 0.91,
      'image': 'https://picsum.photos/400/300?random=23',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          analysisResult = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _analyzeImage() async {
    if (selectedImage == null) return;

    setState(() {
      isAnalyzing = true;
    });

    _slideController.forward();

    // Simulate AI analysis delay
    await Future.delayed(Duration(seconds: 3));

    // Random disease selection for demo
    final randomDisease = staticDiseases[DateTime.now().millisecondsSinceEpoch % staticDiseases.length];

    setState(() {
      isAnalyzing = false;
      analysisResult = randomDisease;
    });

    final confidence = randomDisease['confidence'] as double;
    _showSnackBar('Analysis complete! Disease detected with ${(confidence * 100).toInt()}% confidence.');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FDF8),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildAnalysisSection(),
                if (analysisResult != null) _buildResultsSection(),
                _buildRecentAnalysesSection(),
                _buildStatsSection(),
                _buildFeaturesSection(),
                _buildTipsSection(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF4CAF50),
                Color(0xFF66BB6A),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant AI Doctor',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Smart Disease Detection',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[50]!,
            Colors.green[100]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.eco,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Text(
            'AI-Powered Plant Health Analysis',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.green[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Upload a photo of your plant and get instant disease detection with treatment recommendations from our advanced AI model.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.green[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Colors.green[600],
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Upload Plant Image',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          if (selectedImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
              child: isAnalyzing
                  ? Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing Plant...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while our AI examines the image',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
                  : null,
            ),
            SizedBox(height: 16),
          ] else ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green[200]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No image selected',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Take a photo or choose from gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green[500],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text(
                    'Camera',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text(
                    'Gallery',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[600]!, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (analysisResult == null) return SizedBox.shrink();

    final Color diseaseColor = analysisResult!['color'] as Color;
    final IconData diseaseIcon = analysisResult!['icon'] as IconData;
    final String diseaseName = analysisResult!['name'] as String;
    final double confidence = analysisResult!['confidence'] as double;
    final String description = analysisResult!['description'] as String;
    final String treatment = analysisResult!['treatment'] as String;
    final String prevention = analysisResult!['prevention'] as String;
    final String severity = analysisResult!['severity'] as String;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutQuart,
      )),
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: diseaseColor.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diseaseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    diseaseIcon,
                    color: diseaseColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disease Detected',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        diseaseName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: diseaseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}% confident',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: diseaseColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            _buildInfoCard(
              'Description',
              description,
              Icons.info_outlined,
              Colors.blue,
            ),

            SizedBox(height: 16),

            _buildInfoCard(
              'Treatment',
              treatment,
              Icons.medical_services_outlined,
              Colors.green,
            ),

            SizedBox(height: 16),

            _buildInfoCard(
              'Prevention',
              prevention,
              Icons.shield_outlined,
              Colors.orange,
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[500]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outlined, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Severity Level',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          severity,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysesSection() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Recent Analyses',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...recentAnalyses.map((analysis) => _buildAnalysisCard(analysis)),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final String plant = analysis['plant'] as String;
    final String disease = analysis['disease'] as String;
    final String date = analysis['date'] as String;
    final String imageUrl = analysis['image'] as String;
    final double confidence = analysis['confidence'] as double;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  disease,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.speed,
        'title': 'Instant Results',
        'description': 'Get disease detection results in seconds',
        'color': Colors.blue,
      },
      {
        'icon': Icons.precision_manufacturing,
        'title': '95% Accuracy',
        'description': 'Trained on thousands of plant disease images',
        'color': Colors.green,
      },
      {
        'icon': Icons.healing,
        'title': 'Treatment Plans',
        'description': 'Detailed treatment and prevention advice',
        'color': Colors.orange,
      },
      {
        'icon': Icons.eco,
        'title': 'Eco-Friendly',
        'description': 'Sustainable farming recommendations',
        'color': Colors.teal,
      },
    ];

    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: Colors.green[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Why Choose Plant AI Doctor?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              final IconData featureIcon = feature['icon'] as IconData;
              final String featureTitle = feature['title'] as String;
              final String featureDescription = feature['description'] as String;
              final Color featureColor = feature['color'] as Color;

              return Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: featureColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        featureIcon,
                        color: featureColor,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      featureTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      featureDescription,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {
        'title': 'Best Photo Tips',
        'subtitle': 'For accurate disease detection',
        'tips': [
          'Use natural daylight for clearer images',
          'Focus on affected leaf areas',
          'Avoid blurry or dark photos',
          'Include multiple angles if possible',
        ],
        'icon': Icons.camera_enhance,
        'color': Colors.blue,
      },
      {
        'title': 'Plant Care Basics',
        'subtitle': 'Prevention is better than cure',
        'tips': [
          'Water plants early morning',
          'Ensure proper air circulation',
          'Remove dead or infected leaves',
          'Use organic fertilizers when possible',
        ],
        'icon': Icons.local_florist,
        'color': Colors.green,
      },
    ];

    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.green[600], size: 24),
              SizedBox(width: 12),
              Text(
                'Pro Tips',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...tips.map((tip) {
            final String tipTitle = tip['title'] as String;
            final String tipSubtitle = tip['subtitle'] as String;
            final List<String> tipsList = tip['tips'] as List<String>;
            final IconData tipIcon = tip['icon'] as IconData;
            final Color tipColor = tip['color'] as Color;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tipColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tipIcon,
                          color: tipColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            tipSubtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...tipsList.map((tipText) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tipColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tipText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {
        'number': '10,000+',
        'label': 'Plants Analyzed',
        'icon': Icons.analytics,
        'color': Colors.blue,
      },
      {
        'number': '95%',
        'label': 'Accuracy Rate',
        'icon': Icons.verified,
        'color': Colors.green,
      },
      {
        'number': '50+',
        'label': 'Disease Types',
        'icon': Icons.bug_report,
        'color': Colors.orange,
      },
      {
        'number': '24/7',
        'label': 'Available',
        'icon': Icons.access_time,
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[600]!,
            Colors.green[500]!,
            Colors.lightGreen[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Trusted by Farmers Worldwide',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              final String statNumber = stat['number'] as String;
              final String statLabel = stat['label'] as String;
              final IconData statIcon = stat['icon'] as IconData;

              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      statIcon,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      statNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      statLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}