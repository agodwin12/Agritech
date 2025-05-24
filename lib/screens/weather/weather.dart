import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key, required Map<String, dynamic> userData, required String token}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  String _weatherDescription = '';
  String _temperature = '';
  String _tip = '';
  String _iconCode = '';
  String _cityName = '';
  int _humidity = 0;
  int _windSpeed = 0;
  int _pressure = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _forecast = [];

  late AnimationController _rainController;
  late AnimationController _sunController;
  late AnimationController _thunderController;
  late AnimationController _snowController;
  late AnimationController _fadeController;

  late Animation<double> _sunRotation;
  late Animation<double> _fadeAnimation;

  final String _apiKey = 'e1aec962217269cb21622d157c043f5f';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _determinePosition();
  }

  void _initAnimations() {
    _rainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sunController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _thunderController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _snowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sunRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startWeatherAnimation(String condition) {
    // Stop all animations first
    _rainController.stop();
    _sunController.stop();
    _thunderController.stop();
    _snowController.stop();

    switch (condition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        _rainController.repeat();
        break;
      case 'clear':
        _sunController.repeat();
        break;
      case 'thunderstorm':
        _rainController.repeat();
        _startThunderAnimation();
        break;
      case 'snow':
        _snowController.repeat();
        break;
    }
  }

  void _startThunderAnimation() {
    Future.delayed(Duration.zero, () {
      _thunderController.forward().then((_) {
        _thunderController.reverse().then((_) {
          if (mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _startThunderAnimation();
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _rainController.dispose();
    _sunController.dispose();
    _thunderController.dispose();
    _snowController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _weatherDescription = 'Location services are disabled.';
        _loading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _weatherDescription = 'Location permissions are denied';
          _loading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _weatherDescription = 'Location permissions are permanently denied.';
        _loading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    await _fetchCurrentWeather(position.latitude, position.longitude);
    await _fetchForecast(position.latitude, position.longitude);
  }

  Future<void> _fetchCurrentWeather(double lat, double lon) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['weather'][0];
        final main = data['main'];
        final wind = data['wind'];

        setState(() {
          _weatherDescription = weather['main'];
          _iconCode = weather['icon'];
          _temperature = '${main['temp'].toStringAsFixed(0)}';
          _cityName = data['name'];
          _humidity = main['humidity'];
          _windSpeed = (wind['speed'] * 3.6).toInt();
          _pressure = main['pressure'];
          _tip = _getTipBasedOnWeather(weather['main']);
        });

        _startWeatherAnimation(_weatherDescription);
      }
    } catch (e) {
      setState(() {
        _weatherDescription = 'Failed to load weather';
      });
    }
  }

  Future<void> _fetchForecast(double lat, double lon) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];

        Map<String, List<dynamic>> dailyForecasts = {};

        for (var item in forecastList) {
          DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          String dayKey = '${date.year}-${date.month}-${date.day}';

          if (!dailyForecasts.containsKey(dayKey)) {
            dailyForecasts[dayKey] = [];
          }
          dailyForecasts[dayKey]!.add(item);
        }

        List<Map<String, dynamic>> processedForecast = [];

        dailyForecasts.entries.take(7).forEach((entry) {
          var dayData = entry.value;
          var maxTemp = dayData.map((e) => e['main']['temp_max']).reduce((a, b) => a > b ? a : b);
          var minTemp = dayData.map((e) => e['main']['temp_min']).reduce((a, b) => a < b ? a : b);
          var weather = dayData.first['weather'][0];
          var date = DateTime.fromMillisecondsSinceEpoch(dayData.first['dt'] * 1000);

          processedForecast.add({
            'date': date,
            'maxTemp': maxTemp.toStringAsFixed(0),
            'minTemp': minTemp.toStringAsFixed(0),
            'icon': weather['icon'],
            'description': weather['main'],
          });
        });

        setState(() {
          _forecast = processedForecast;
          _loading = false;
        });

        _fadeController.forward();
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _getTipBasedOnWeather(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '🌱 Perfect conditions for outdoor farming activities. Apply fertilizers and check irrigation systems.';
      case 'rain':
      case 'drizzle':
        return '🌧️ Natural irrigation day! Avoid pesticide application and ensure proper drainage around crops.';
      case 'thunderstorm':
        return '⛈️ Secure all farming equipment and avoid field work. Perfect time for indoor planning.';
      case 'snow':
        return '❄️ Protect sensitive crops and check greenhouse heating. Monitor livestock shelter.';
      case 'clouds':
        return '☁️ Ideal for transplanting seedlings and working outdoors without harsh sun exposure.';
      case 'mist':
      case 'fog':
        return '🌫️ High humidity benefits certain crops. Good time for greenhouse activities.';
      default:
        return '🚜 Monitor crop conditions and adjust farming activities based on weather changes.';
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Dark Green
              Color(0xFF4CAF50), // Medium Green
              Color(0xFF81C784), // Light Green
            ],
          ),
        ),
        child: Stack(
          children: [
            // Weather Animation Layer
            if (!_loading) ...[
              // Rain Animation
              if (_weatherDescription.toLowerCase().contains('rain') ||
                  _weatherDescription.toLowerCase().contains('drizzle') ||
                  _weatherDescription.toLowerCase().contains('thunderstorm'))
                _buildRainAnimation(),

              // Sun Animation
              if (_weatherDescription.toLowerCase() == 'clear')
                _buildSunAnimation(),

              // Thunder Animation
              if (_weatherDescription.toLowerCase().contains('thunderstorm'))
                _buildThunderAnimation(),

              // Snow Animation
              if (_weatherDescription.toLowerCase().contains('snow'))
                _buildSnowAnimation(),
            ],

            // Main Content
            SafeArea(
              child: _loading
                  ? _buildLoadingScreen()
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40 : 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(isTablet),
                        SizedBox(height: isTablet ? 40 : 20),
                        _buildMainWeatherCard(isTablet, screenWidth),
                        SizedBox(height: isTablet ? 40 : 25),
                        _buildWeatherStats(isTablet),
                        SizedBox(height: isTablet ? 40 : 25),
                        _buildFarmingTipCard(isTablet),
                        SizedBox(height: isTablet ? 40 : 25),
                        _buildForecastCard(isTablet),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Getting weather forecast...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
        ),
        Column(
          children: [
            Text(
              _cityName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 24 : 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Farm Weather Station',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isTablet ? 16 : 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => _determinePosition(),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard(bool isTablet, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 40 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.network(
            'https://openweathermap.org/img/wn/${_iconCode}@4x.png',
            height: isTablet ? 140 : 120,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.wb_sunny,
              size: isTablet ? 140 : 120,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _temperature,
                style: TextStyle(
                  fontSize: isTablet ? 80 : 64,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                '°C',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            _weatherDescription,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStats(bool isTablet) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('💧', '$_humidity%', 'Humidity', isTablet)),
        SizedBox(width: isTablet ? 20 : 15),
        Expanded(child: _buildStatCard('💨', '${_windSpeed}km/h', 'Wind Speed', isTablet)),
        SizedBox(width: isTablet ? 20 : 15),
        Expanded(child: _buildStatCard('🌡️', '${_pressure}hPa', 'Pressure', isTablet)),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: isTablet ? 28 : 24)),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontFamily: 'Poppins',
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingTipCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: const Color(0xFF1B5E20).withOpacity(0.3),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Today\'s Farm Advice',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            _tip,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontFamily: 'Poppins',
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                '7-Day Forecast',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 25 : 20),
          ..._forecast.map((day) => _buildForecastItem(day, isTablet)).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> day, bool isTablet) {
    DateTime date = day['date'];
    bool isToday = DateTime.now().day == date.day;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 15),
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : 12,
        horizontal: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isToday ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              isToday ? 'Today' : _getDayName(date),
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/${day['icon']}.png',
                  height: isTablet ? 35 : 30,
                  width: isTablet ? 35 : 30,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    day['description'],
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${day['maxTemp']}°/${day['minTemp']}°',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainAnimation() {
    return AnimatedBuilder(
      animation: _rainController,
      builder: (context, child) {
        return CustomPaint(
          painter: RainPainter(_rainController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildSunAnimation() {
    return Positioned(
      top: 100,
      right: 30,
      child: AnimatedBuilder(
        animation: _sunRotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _sunRotation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.8),
                    Colors.orange.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: Colors.yellow,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThunderAnimation() {
    return AnimatedBuilder(
      animation: _thunderController,
      builder: (context, child) {
        return Container(
          color: Colors.white.withOpacity(_thunderController.value * 0.3),
        );
      },
    );
  }

  Widget _buildSnowAnimation() {
    return AnimatedBuilder(
      animation: _snowController,
      builder: (context, child) {
        return CustomPaint(
          painter: SnowPainter(_snowController.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class RainPainter extends CustomPainter {
  final double animation;

  RainPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height * 2 + animation * size.height * 2) % (size.height + 50);

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SnowPainter extends CustomPainter {
  final double animation;

  SnowPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + animation * size.height * 0.5) % size.height;
      final radius = random.nextDouble() * 3 + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}