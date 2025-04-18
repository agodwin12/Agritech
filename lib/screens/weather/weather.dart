import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WeatherScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const WeatherScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String _apiKey = 'e1aec962217269cb21622d157c043f5f'; // 🔐 Your OpenWeather API key
  late WeatherFactory _weatherFactory;

  Weather? _currentWeather;
  List<Weather> _forecast = [];
  String? _recommendation;
  bool _isLoading = true;

  // Color scheme
  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _lightGreen = const Color(0xFFAED581);
  final Color _darkGreen = const Color(0xFF1B5E20);
  final Color _earthBrown = const Color(0xFF795548);
  final Color _skyBlue = const Color(0xFF64B5F6);

  @override
  void initState() {
    super.initState();
    _weatherFactory = WeatherFactory(_apiKey);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoading = true);
    try {
      Position pos = await _getPosition();
      Weather current = await _weatherFactory.currentWeatherByLocation(pos.latitude, pos.longitude);
      List<Weather> forecastList = await _weatherFactory.fiveDayForecastByLocation(pos.latitude, pos.longitude);

      // Get 1 forecast per day (every 24h)
      final Map<String, Weather> dailyForecast = {};
      for (var w in forecastList) {
        final date = DateFormat('yyyy-MM-dd').format(w.date!);
        if (!dailyForecast.containsKey(date)) {
          dailyForecast[date] = w;
        }
      }

      setState(() {
        _currentWeather = current;
        _forecast = dailyForecast.values.take(5).toList();
        _recommendation = _getRecommendation(current);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching weather: $e");
      setState(() {
        _recommendation = "Failed to load weather data.";
        _isLoading = false;
      });
    }
  }

  Future<Position> _getPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
  }

  String _getRecommendation(Weather weather) {
    final temp = weather.temperature?.celsius ?? 0;
    final description = weather.weatherMain?.toLowerCase() ?? "";

    if (description.contains("rain")) return "🌧️ Rain: Ensure drainage & avoid pesticide application.";
    if (temp > 32) return "🔥 Hot: Irrigate early morning or evening.";
    if (description.contains("clear")) return "☀️ Clear: Ideal for planting or harvesting.";
    if (description.contains("cloud")) return "☁️ Cloudy: Good for transplanting.";
    return "👨‍🌾 Monitor conditions for optimal farming.";
  }

  String _getWeatherIcon(String description) {
    description = description.toLowerCase();
    if (description.contains("rain")) return "assets/icons/rain.svg";
    if (description.contains("cloud")) return "assets/icons/cloudy.svg";
    if (description.contains("clear")) return "assets/icons/sunny.svg";
    if (description.contains("storm")) return "assets/icons/storm.svg";
    if (description.contains("snow")) return "assets/icons/snow.svg";
    return "assets/icons/partly_cloudy.svg";
  }

  String _getWeatherEmoji(String description) {
    description = description.toLowerCase();
    if (description.contains("rain")) return "🌧️";
    if (description.contains("cloud")) return "☁️";
    if (description.contains("clear")) return "☀️";
    if (description.contains("storm")) return "⚡";
    if (description.contains("snow")) return "❄️";
    return "🌤️";
  }

  Color _getWeatherColor(String description) {
    description = description.toLowerCase();
    if (description.contains("rain")) return _skyBlue;
    if (description.contains("cloud")) return Colors.grey[400]!;
    if (description.contains("clear")) return Colors.amber;
    if (description.contains("storm")) return Colors.indigo;
    if (description.contains("snow")) return Colors.lightBlue[100]!;
    return _skyBlue;
  }

  Widget _buildCurrentWeatherCard() {
    final weather = _currentWeather;
    if (weather == null) return const SizedBox.shrink();

    final temp = weather.temperature?.celsius?.toStringAsFixed(1) ?? "--";
    final feelsLike = weather.tempFeelsLike?.celsius?.toStringAsFixed(1) ?? "--";
    final humidity = weather.humidity?.toString() ?? "--";
    final windSpeed = weather.windSpeed?.toString() ?? "--";
    final weatherMain = weather.weatherMain ?? "Unknown";
    final weatherDescription = weather.weatherDescription ?? "";
    final sunriseTime = weather.sunrise != null ? DateFormat('h:mm a').format(weather.sunrise!) : "--";
    final sunsetTime = weather.sunset != null ? DateFormat('h:mm a').format(weather.sunset!) : "--";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getWeatherColor(weatherMain),
            _getWeatherColor(weatherMain).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            weather.areaName ?? "Your Location",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "$temp°C",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Feels like $feelsLike°C",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _getWeatherEmoji(weatherMain),
                      style: const TextStyle(fontSize: 50),
                    ),
                    Text(
                      weatherMain,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      weatherDescription,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(Icons.water_drop, "$humidity%", "Humidity"),
                _buildWeatherDetail(Icons.air, "$windSpeed m/s", "Wind"),
                _buildWeatherDetail(Icons.wb_sunny, sunriseTime, "Sunrise"),
                _buildWeatherDetail(Icons.wb_twilight, sunsetTime, "Sunset"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _lightGreen,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _lightGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.eco,
              color: _darkGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Farming Tip",
                  style: GoogleFonts.poppins(
                    color: _darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _recommendation ?? "Check back later for farming tips based on weather conditions.",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Weather forecast) {
    final date = DateFormat('EEEE, MMM d').format(forecast.date!);
    final emoji = _getWeatherEmoji(forecast.weatherMain ?? "");
    final temp = forecast.temperature?.celsius?.toStringAsFixed(1) ?? "--";
    final minTemp = forecast.tempMin?.celsius?.toStringAsFixed(1) ?? "--";
    final maxTemp = forecast.tempMax?.celsius?.toStringAsFixed(1) ?? "--";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${forecast.weatherMain} • ${forecast.weatherDescription}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$temp°C",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkGreen,
                      ),
                    ),
                    Text(
                      "$minTemp° / $maxTemp°",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Weather & Farming',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWeatherData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryGreen),
            const SizedBox(height: 20),
            Text(
              "Loading weather data...",
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentWeatherCard(),
              const SizedBox(height: 24),
              _buildRecommendationCard(),
              const SizedBox(height: 30),
              Row(
                children: [
                  Icon(Icons.calendar_month, color: _darkGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "5-Day Forecast",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._forecast.map((f) => _buildForecastCard(f)),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _fetchWeatherData,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    "Refresh Weather",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}