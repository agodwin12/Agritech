import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather/weather.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../navigation bar/navigation_bar.dart';

// Model classes
class PlantDisease {
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  final String sourceUrl;

  PlantDisease({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.sourceUrl,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    String publishedDate = json['publishedAt'] ?? '';
    String formattedDate;

    try {
      if (publishedDate.isNotEmpty) {
        formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(publishedDate));
      } else {
        formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
      }
    } catch (e) {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    }

    return PlantDisease(
      title: json['title'] ?? 'Unknown Disease',
      description: json['description'] ?? 'No description available',
      date: formattedDate,
      imageUrl: json['urlToImage'] ?? 'https://via.placeholder.com/150?text=Plant+Disease',
      sourceUrl: json['url'] ?? 'https://example.com',
    );
  }
}

class AgricultureNews {
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  final String sourceUrl;
  final String sourceName;

  AgricultureNews({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.sourceUrl,
    required this.sourceName,
  });

  factory AgricultureNews.fromJson(Map<String, dynamic> json) {
    String publishedDate = json['publishedAt'] ?? '';
    String formattedDate;

    try {
      if (publishedDate.isNotEmpty) {
        formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(publishedDate));
      } else {
        formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
      }
    } catch (e) {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    }

    return AgricultureNews(
      title: json['title'] ?? 'Unknown News',
      description: json['description'] ?? 'No description available',
      date: formattedDate,
      imageUrl: json['urlToImage'] ?? 'https://via.placeholder.com/150?text=Agriculture+News',
      sourceUrl: json['url'] ?? 'https://example.com',
      sourceName: json['source'] != null ? json['source']['name'] ?? 'Unknown Source' : 'Unknown Source',
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
  List<AgricultureNews> _news = [];
  List<FarmingTip> _tips = [];
  bool _isLoading = true;
  bool _isError = false;

  // API Keys and URLs
  final String _weatherApiKey = 'e1aec962217269cb21622d157c043f5f';
  final String _newsApiKey = '80d9361201a841c39e9f5418dec247f8'; // Replace with your actual News API key

  @override
  void initState() {
    super.initState();
    print("👤 Logged in user: ${widget.userData}");
    print("🔐 Token: ${widget.token}");
    _getCurrentDateTime();
    _getCurrentLocation();
    _fetchNewsAndDiseases();
    _loadFarmingTips();
  }

  // Launch URL in browser
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        print("Could not launch $url");
      }
    } catch (e) {
      print("Error launching URL: $e");
    }
  }

  Future<void> _fetchNewsAndDiseases() async {
    try {
      // Attempt to fetch news and diseases from the API
      await Future.wait([
        _fetchAgricultureNews(),
        _fetchPlantDiseases(),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
      _loadFallbackData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fetch agriculture news from News API
  Future<void> _fetchAgricultureNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?q=agriculture+farming&sortBy=publishedAt&language=en&apiKey=$_newsApiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok' && data['articles'] != null) {
          final List<dynamic> articles = data['articles'];
          if (mounted) {
            setState(() {
              _news = articles.map((article) => AgricultureNews.fromJson(article)).toList();
              // Limit to first 5 articles
              if (_news.length > 5) {
                _news = _news.sublist(0, 5);
              }
            });
          }
        } else {
          print("API Error: ${data['message'] ?? 'Unknown error'}");
          _loadFallbackNews();
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        _loadFallbackNews();
      }
    } catch (e) {
      print("Error fetching agriculture news: $e");
      _loadFallbackNews();
    }
  }

  // Fetch plant disease alerts
  Future<void> _fetchPlantDiseases() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?q=plant+disease+agriculture&sortBy=publishedAt&language=en&apiKey=$_newsApiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok' && data['articles'] != null) {
          final List<dynamic> articles = data['articles'];
          if (mounted) {
            setState(() {
              _diseases = articles.map((article) => PlantDisease.fromJson(article)).toList();
              // Limit to first 5 disease alerts
              if (_diseases.length > 5) {
                _diseases = _diseases.sublist(0, 5);
              }
            });
          }
        } else {
          print("API Error: ${data['message'] ?? 'Unknown error'}");
          _loadFallbackDiseases();
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        _loadFallbackDiseases();
      }
    } catch (e) {
      print("Error fetching plant diseases: $e");
      _loadFallbackDiseases();
    }
  }

  void _getCurrentDateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentDate = DateFormat('EEEE, MMMM d').format(now);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = "Location services disabled";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentAddress = "Location permissions denied";
            });
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      await _getAddressFromLatLng();
      await _getWeatherData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Error: Could not get location";
          _isError = true;
          _isLoading = false;
        });
      }
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

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _currentAddress = "${place.locality ?? ''}, ${place.country ?? ''}";
              _currentCity = place.locality ?? "Unknown City";
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Error: Could not get address";
        });
      }
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

        if (mounted) {
          setState(() {
            _weatherData = weather;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
      print("Error getting weather: $e");
    }
  }

  void _loadFallbackData() {
    _loadFallbackNews();
    _loadFallbackDiseases();
    _loadFarmingTips();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load fallback data if API fails
  void _loadFallbackDiseases() {
    _diseases = [
      PlantDisease(
        title: "Tomato Leaf Blight in Eastern Region",
        description: "Monitor crops closely as leaf blight incidents have increased this season. Apply copper-based fungicides early in the season.",
        date: "May 05, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Leaf+Blight",
        sourceUrl: "https://en.wikipedia.org/wiki/Tomato_leaf_blight",
      ),
      PlantDisease(
        title: "Wheat Rust Spreading in Northern Areas",
        description: "Apply preventative fungicides to protect wheat crops from rust infections. Early detection is crucial.",
        date: "May 02, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Wheat+Rust",
        sourceUrl: "https://en.wikipedia.org/wiki/Wheat_rust",
      ),
      PlantDisease(
        title: "Powdery Mildew Alert",
        description: "Maintain proper spacing between plants to reduce powdery mildew spread. Consider sulfur-based treatments.",
        date: "Apr 28, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Powdery+Mildew",
        sourceUrl: "https://en.wikipedia.org/wiki/Powdery_mildew",
      ),
    ];
  }

  void _loadFallbackNews() {
    _news = [
      AgricultureNews(
        title: "New Sustainable Farming Methods Show Promise",
        description: "Recent studies show that regenerative farming practices can improve soil health and increase crop yields by up to 30% while reducing water usage.",
        date: "May 06, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Sustainable+Farming",
        sourceUrl: "https://www.example.com/sustainable-farming",
        sourceName: "Agriculture Today",
      ),
      AgricultureNews(
        title: "Government Launches New Subsidy Program for Small Farms",
        description: "Small-scale farmers can now apply for financial support under a new government initiative aimed at increasing food security and promoting sustainable practices.",
        date: "May 04, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Farm+Subsidies",
        sourceUrl: "https://www.example.com/farm-subsidies",
        sourceName: "Rural News Network",
      ),
      AgricultureNews(
        title: "Climate Change Affecting Crop Patterns Globally",
        description: "Researchers observe shifting growing seasons and recommend adaptation strategies for farmers as traditional planting times become less reliable.",
        date: "May 01, 2025",
        imageUrl: "https://via.placeholder.com/150?text=Climate+Change",
        sourceUrl: "https://www.example.com/climate-agriculture",
        sourceName: "Climate Science Journal",
      ),
    ];
  }

  void _loadFarmingTips() {
    _tips = [
      FarmingTip(
        title: "Optimize Irrigation",
        description: "Check for leaks and ensure even water distribution to conserve water. Consider drip irrigation for higher efficiency.",
        category: "Water Management",
        icon: Icons.water_drop,
      ),
      FarmingTip(
        title: "Crop Rotation Benefits",
        description: "Implement a 3-4 year rotation plan to break pest cycles and improve soil health without relying on chemical inputs.",
        category: "Soil Health",
        icon: Icons.terrain,
      ),
      FarmingTip(
        title: "Natural Pest Control",
        description: "Introduce beneficial insects like ladybugs to control harmful pests naturally and reduce pesticide dependency.",
        category: "Pest Management",
        icon: Icons.bug_report,
      ),
    ];
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isError = false;
      });
    }

    try {
      await _getCurrentLocation();
      await _fetchNewsAndDiseases();
      _loadFarmingTips();
    } catch (e) {
      print("Error refreshing data: $e");
      _loadFallbackData();
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

                    _buildSectionTitle("Agriculture News"),
                    const SizedBox(height: 10),
                    if (_news.isEmpty)
                      _buildEmptyCard("No agriculture news available")
                    else
                      ..._news.map((news) => _buildNewsCard(news)).toList(),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Disease Alerts"),
                    const SizedBox(height: 10),
                    if (_diseases.isEmpty)
                      _buildEmptyCard("No disease alerts available")
                    else
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

  Widget _buildEmptyCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
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
            child: const Icon(
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

  Widget _buildNewsCard(AgricultureNews news) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _launchURL(news.sourceUrl),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        news.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.source,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  news.sourceName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                news.date,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  news.description,
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
                    onPressed: () => _launchURL(news.sourceUrl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "READ MORE",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        child: InkWell(
          onTap: () => _launchURL(disease.sourceUrl),
          borderRadius: BorderRadius.circular(16),
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
                            maxLines: 2,
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
                    onPressed: () => _launchURL(disease.sourceUrl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "READ MORE",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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