import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather/weather.dart';
import 'dart:convert';

import '../navigation bar/navigation_bar.dart';

// Import the navigation bar

// Model classes
class PlantDisease {
  final String title;
  final String description;
  final String date;
  final String imageUrl;

  PlantDisease({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    return PlantDisease(
      title: json['title'] ?? 'Unknown Disease',
      description: json['description'] ?? 'No description available',
      date: json['date'] ?? DateFormat('MMM dd, yyyy').format(DateTime.now()),
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/150',
    );
  }
}

class FarmingTip {
  final String title;
  final String description;
  final String category;
  final IconData icon;

  FarmingTip({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });

  factory FarmingTip.fromJson(Map<String, dynamic> json) {
    IconData iconData;
    switch (json['category']?.toLowerCase() ?? '') {
      case 'water management':
        iconData = Icons.water_drop;
        break;
      case 'soil health':
        iconData = Icons.terrain;
        break;
      case 'pest management':
        iconData = Icons.bug_report;
        break;
      case 'harvesting':
        iconData = Icons.access_time;
        break;
      case 'planting':
        iconData = Icons.grass;
        break;
      default:
        iconData = Icons.agriculture;
        break;
    }

    return FarmingTip(
      title: json['title'] ?? 'Unknown Tip',
      description: json['description'] ?? 'No description available',
      category: json['category'] ?? 'General',
      icon: iconData,
    );
  }
}

class FeaturePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const FeaturePage({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);


  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  // Location and weather
  Position? _currentPosition;
  String _currentAddress = "Locating...";
  String _currentCity = "";
  String _currentDate = "";
  Weather? _weatherData;

  // Data
  List<PlantDisease> _diseases = [];
  List<FarmingTip> _tips = [];
  bool _isLoading = true;
  bool _isError = false;

  // API Keys and URLs
  final String _weatherApiKey = 'e1aec962217269cb21622d157c043f5f';

  @override
  void initState() {
    super.initState();
    print("👤 Logged in user: ${widget.userData}");
    print("🔐 Token: ${widget.token}");
    _getCurrentDateTime();
    _getCurrentLocation();
    _loadSampleData();
  }


  void _getCurrentDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('EEEE, MMMM d').format(now);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Location services disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Location permissions denied";
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _getAddressFromLatLng();
      await _getWeatherData();
    } catch (e) {
      setState(() {
        _currentAddress = "Error: Could not get location";
        _isError = true;
        _isLoading = false;
      });
      print("Error getting location: $e");
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.locality}, ${place.country}";
          _currentCity = place.locality ?? "Unknown City";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Error: Could not get address";
      });
      print("Error getting address: $e");
    }
  }

  Future<void> _getWeatherData() async {
    try {
      if (_currentPosition != null) {
        WeatherFactory wf = WeatherFactory(_weatherApiKey);
        Weather weather = await wf.currentWeatherByLocation(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        setState(() {
          _weatherData = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      print("Error getting weather: $e");
    }
  }

  void _loadSampleData() {
    // Generate sample diseases
    _diseases = [
      PlantDisease(
        title: "Tomato Leaf Blight in Eastern Region",
        description: "Monitor crops closely as leaf blight incidents have increased this season.",
        date: "Apr 15, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Leaf+Blight",
      ),
      PlantDisease(
        title: "Wheat Rust Spreading in Northern Areas",
        description: "Apply preventative fungicides to protect wheat crops from rust infections.",
        date: "Apr 12, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Wheat+Rust",
      ),
      PlantDisease(
        title: "Powdery Mildew Alert",
        description: "Maintain proper spacing between plants to reduce powdery mildew spread.",
        date: "Apr 10, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Powdery+Mildew",
      ),
    ];

    // Generate sample tips
    _tips = [
      FarmingTip(
        title: "Optimize Irrigation",
        description: "Check for leaks and ensure even water distribution to conserve water.",
        category: "Water Management",
        icon: Icons.water_drop,
      ),
      FarmingTip(
        title: "Crop Rotation Benefits",
        description: "Implement a 3-4 year rotation plan to break pest cycles and improve soil health.",
        category: "Soil Health",
        icon: Icons.terrain,
      ),
      FarmingTip(
        title: "Natural Pest Control",
        description: "Introduce beneficial insects like ladybugs to control harmful pests naturally.",
        category: "Pest Management",
        icon: Icons.bug_report,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  String _getWeatherIcon() {
    if (_weatherData == null) return '🌤️';

    final String lowerCaseWeather = _weatherData!.weatherMain?.toLowerCase() ?? "";

    if (lowerCaseWeather.contains("rain")) {
      return '🌧️';
    } else if (lowerCaseWeather.contains("cloud")) {
      return '☁️';
    } else if (lowerCaseWeather.contains("clear")) {
      return '☀️';
    } else if (lowerCaseWeather.contains("snow")) {
      return '❄️';
    } else if (lowerCaseWeather.contains("thunderstorm")) {
      return '⚡';
    } else if (lowerCaseWeather.contains("mist") || lowerCaseWeather.contains("fog")) {
      return '🌫️';
    } else {
      return '🌤️';
    }
  }

  String _getWeatherRecommendation() {
    if (_weatherData == null) return "Monitor weather";

    final String lowerCaseWeather = _weatherData!.weatherMain?.toLowerCase() ?? "";
    final double temp = _weatherData!.temperature?.celsius ?? 20.0;

    if (lowerCaseWeather.contains("rain")) {
      return "Check drainage";
    } else if (lowerCaseWeather.contains("clear") && temp > 30) {
      return "Water crops";
    } else if (lowerCaseWeather.contains("clear") && temp < 30) {
      return "Good for fieldwork";
    } else if (lowerCaseWeather.contains("cloud")) {
      return "Good for transplanting";
    } else if (lowerCaseWeather.contains("snow") || temp < 0) {
      return "Protect crops";
    } else {
      return "Monitor weather";
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    await _getCurrentLocation();
    _loadSampleData();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingScreen()
          : _isError
          ? _buildErrorScreen()
          : _buildMainContent(),
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: false,
        darkColor: Colors.green[900]!,
        primaryColor: Colors.green[700]!,
        textColor: Colors.grey[800]!,
        currentIndex: 0,
        userData: widget.userData,
        token: widget.token,
      ),

    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[700]!,
            Colors.green[500]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading farm assistant...",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[700]!,
            Colors.green[500]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              "Connection Error",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Could not load farming data. Check your connection.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.green[700],
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildWeatherCard(),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Disease Alerts"),
                    const SizedBox(height: 10),
                    ..._diseases.map((disease) => _buildDiseaseCard(disease)).toList(),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Farming Tips"),
                    const SizedBox(height: 10),
                    ..._tips.map((tip) => _buildTipCard(tip)).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.green[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentDate,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                _currentCity.isNotEmpty ? _currentCity : _currentAddress,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final temp = _weatherData?.temperature?.celsius?.toStringAsFixed(1) ?? "--";
    final condition = _weatherData?.weatherMain ?? "Unknown";
    final humidity = _weatherData?.humidity?.toStringAsFixed(0) ?? "--";
    final windSpeed = _weatherData?.windSpeed?.toStringAsFixed(1) ?? "--";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S WEATHER",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "$temp°C",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          condition,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  _getWeatherIcon(),
                  style: const TextStyle(fontSize: 40),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                    icon: Icons.water_drop,
                    value: "$humidity%",
                    label: "Humidity"
                ),
                _buildWeatherDetail(
                    icon: Icons.air,
                    value: "$windSpeed m/s",
                    label: "Wind"
                ),
                _buildWeatherDetail(
                    icon: Icons.agriculture,
                    value: _getWeatherRecommendation(),
                    label: "Action"
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String value,
    required String label
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.green[700],
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to see all
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.green[700],
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                "View all",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseCard(PlantDisease disease) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[400]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          disease.date,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                disease.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to disease details
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "READ MORE",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(FarmingTip tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green[700]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tip.icon,
                  color: Colors.green[700],
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tip.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}