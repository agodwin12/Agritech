import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Models for the Weather Screen
class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final double precipitation;
  final double humidity;
  final double windSpeed;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
    required this.humidity,
    required this.windSpeed,
  });
}

class FarmingTip {
  final String title;
  final String description;
  final String iconName;
  final String category;
  final int priority; // 1 = high, 2 = medium, 3 = low

  FarmingTip({
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    this.priority = 2,
  });
}

class WeatherScreen extends StatefulWidget {
  final String latitude;
  final String longitude;
  final String cityName;
  final Map userData;
  final String token;

  const WeatherScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<DailyForecast> _dailyForecasts = [];
  List<FarmingTip> _farmingTips = [];
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _hourlyData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Enhanced API call with more detailed weather data
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?'
              'latitude=${widget.latitude}&longitude=${widget.longitude}'
              '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m'
              '&hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,precipitation_probability,precipitation,rain,showers,snowfall,snow_depth,weather_code,pressure_msl,surface_pressure,cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility,evapotranspiration,et0_fao_evapotranspiration,vapour_pressure_deficit,wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_speed_180m,wind_direction_10m,wind_direction_80m,wind_direction_120m,wind_direction_180m,wind_gusts_10m,temperature_80m,temperature_120m,temperature_180m,soil_temperature_0cm,soil_temperature_6cm,soil_temperature_18cm,soil_temperature_54cm,soil_moisture_0_1cm,soil_moisture_1_3cm,soil_moisture_3_9cm,soil_moisture_9_27cm,soil_moisture_27_81cm'
              '&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,daylight_duration,sunshine_duration,uv_index_max,uv_index_clear_sky_max,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,precipitation_probability_max,precipitation_probability_min,precipitation_probability_mean,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant,shortwave_radiation_sum,et0_fao_evapotranspiration'
              '&timezone=auto'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      // Parse current weather
      setState(() {
        _currentWeather = data['current'];
        _hourlyData = data['hourly'];
      });

      // Parse daily forecasts with enhanced data
      final dailyData = data['daily'];
      final List<String> dates = List<String>.from(dailyData['time']);
      final List<int> weatherCodes = List<int>.from(dailyData['weather_code']);
      final List<double> maxTemps = List<double>.from(dailyData['temperature_2m_max']);
      final List<double> minTemps = List<double>.from(dailyData['temperature_2m_min']);
      final List<double> precipitations = List<double>.from(dailyData['precipitation_sum']);
      final List<double> windSpeeds = List<double>.from(dailyData['wind_speed_10m_max']);

      // Get humidity from hourly data (using daily average)
      List<double> humidities = [];
      if (_hourlyData != null && _hourlyData!['relative_humidity_2m'] != null) {
        final hourlyHumidity = List<double>.from(_hourlyData!['relative_humidity_2m']);
        // Calculate daily averages (24 hours per day)
        for (int day = 0; day < dates.length && day * 24 < hourlyHumidity.length; day++) {
          double daySum = 0;
          int count = 0;
          for (int hour = 0; hour < 24 && (day * 24 + hour) < hourlyHumidity.length; hour++) {
            daySum += hourlyHumidity[day * 24 + hour];
            count++;
          }
          humidities.add(count > 0 ? daySum / count : 50.0);
        }
      }

      List<DailyForecast> forecasts = [];
      for (int i = 0; i < dates.length; i++) {
        forecasts.add(DailyForecast(
          date: DateTime.parse(dates[i]),
          weatherCode: weatherCodes[i],
          maxTemp: maxTemps[i],
          minTemp: minTemps[i],
          precipitation: precipitations[i],
          humidity: i < humidities.length ? humidities[i] : 50.0,
          windSpeed: windSpeeds[i],
        ));
      }

      setState(() {
        _dailyForecasts = forecasts;
      });

      // Generate comprehensive farming tips
      await _generateDynamicFarmingTips();

    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _error = 'Failed to load weather data. Please check your connection and try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateDynamicFarmingTips() async {
    try {
      List<FarmingTip> tips = [];

      if (_dailyForecasts.isEmpty || _currentWeather == null) return;

      // Analyze weather patterns for the next 7 days
      final currentTemp = _currentWeather!['temperature_2m'];
      final currentHumidity = _currentWeather!['relative_humidity_2m'];
      final currentWindSpeed = _currentWeather!['wind_speed_10m'];
      final currentPrecip = _currentWeather!['precipitation'];

      // Check for immediate weather concerns (today)
      final today = _dailyForecasts[0];

      // Temperature-based tips
      if (today.maxTemp > 35) {
        tips.add(FarmingTip(
          title: 'Extreme Heat Alert',
          description: 'Temperature exceeding 35°C today. Provide shade cloth for sensitive crops, increase watering frequency, and avoid working during peak hours (10 AM - 4 PM).',
          iconName: 'warning',
          category: 'Temperature',
          priority: 1,
        ));
      } else if (today.maxTemp > 30) {
        tips.add(FarmingTip(
          title: 'High Temperature Warning',
          description: 'Hot weather expected (${today.maxTemp.toStringAsFixed(1)}°C). Water crops early morning or late evening. Consider mulching to retain soil moisture.',
          iconName: 'wb_sunny',
          category: 'Temperature',
          priority: 2,
        ));
      }

      if (today.minTemp < 0) {
        tips.add(FarmingTip(
          title: 'Frost Warning',
          description: 'Freezing temperatures expected (${today.minTemp.toStringAsFixed(1)}°C). Protect sensitive plants with frost cloth. Harvest any remaining tender vegetables.',
          iconName: 'ac_unit',
          category: 'Temperature',
          priority: 1,
        ));
      } else if (today.minTemp < 5) {
        tips.add(FarmingTip(
          title: 'Cold Weather Alert',
          description: 'Low temperatures expected (${today.minTemp.toStringAsFixed(1)}°C). Monitor for cold stress in plants. Consider row covers for protection.',
          iconName: 'thermostat',
          category: 'Temperature',
          priority: 2,
        ));
      }

      // Precipitation analysis
      double totalPrecip = _dailyForecasts.take(7).map((f) => f.precipitation).reduce((a, b) => a + b);
      double avgDailyPrecip = totalPrecip / 7;

      if (today.precipitation > 20) {
        tips.add(FarmingTip(
          title: 'Heavy Rain Expected',
          description: '${today.precipitation.toStringAsFixed(1)}mm of rain forecasted. Postpone spraying activities. Check drainage systems. Good time for indoor farm maintenance.',
          iconName: 'water_drop',
          category: 'Precipitation',
          priority: 1,
        ));
      } else if (today.precipitation > 5) {
        tips.add(FarmingTip(
          title: 'Moderate Rain Forecast',
          description: '${today.precipitation.toStringAsFixed(1)}mm of rain expected. Ideal for transplanting. Delay irrigation as natural watering will occur.',
          iconName: 'grain',
          category: 'Precipitation',
          priority: 2,
        ));
      }

      if (totalPrecip < 5) {
        tips.add(FarmingTip(
          title: 'Dry Week Ahead',
          description: 'Only ${totalPrecip.toStringAsFixed(1)}mm total rainfall expected this week. Ensure irrigation systems are functional. Consider drought-resistant practices.',
          iconName: 'water_drop_outlined',
          category: 'Precipitation',
          priority: 2,
        ));
      }

      // Wind-based tips
      if (today.windSpeed > 25) {
        tips.add(FarmingTip(
          title: 'High Wind Warning',
          description: 'Strong winds up to ${today.windSpeed.toStringAsFixed(1)} km/h expected. Secure greenhouse structures, delay spraying, and check plant supports.',
          iconName: 'air',
          category: 'Wind',
          priority: 1,
        ));
      }

      // Humidity-based tips
      if (today.humidity > 80) {
        tips.add(FarmingTip(
          title: 'High Humidity Alert',
          description: 'Humidity levels around ${today.humidity.toStringAsFixed(0)}%. Increased risk of fungal diseases. Ensure good air circulation and monitor plants closely.',
          iconName: 'opacity',
          category: 'Humidity',
          priority: 2,
        ));
      } else if (today.humidity < 30) {
        tips.add(FarmingTip(
          title: 'Low Humidity Notice',
          description: 'Dry air conditions (${today.humidity.toStringAsFixed(0)}% humidity). Plants may need extra watering. Consider misting for humidity-loving crops.',
          iconName: 'dry_cleaning',
          category: 'Humidity',
          priority: 2,
        ));
      }

      // Weekly pattern analysis
      bool hasConsistentRain = _dailyForecasts.take(3).every((f) => f.precipitation > 2);
      bool hasHeatWave = _dailyForecasts.take(5).where((f) => f.maxTemp > 30).length >= 3;
      bool hasTemperatureSwings = _dailyForecasts.take(7).any((f) => (f.maxTemp - f.minTemp) > 15);

      if (hasConsistentRain) {
        tips.add(FarmingTip(
          title: 'Extended Wet Period',
          description: 'Rain expected for multiple days. Monitor for waterlogging. Consider covered areas for drying harvested crops. Watch for slug and snail activity.',
          iconName: 'cloud_queue',
          category: 'Pattern',
          priority: 2,
        ));
      }

      if (hasHeatWave) {
        tips.add(FarmingTip(
          title: 'Heat Wave Pattern',
          description: 'Extended hot weather ahead. Plan deep, infrequent watering. Consider temporary shade structures. Monitor livestock for heat stress.',
          iconName: 'local_fire_department',
          category: 'Pattern',
          priority: 2,
        ));
      }

      if (hasTemperatureSwings) {
        tips.add(FarmingTip(
          title: 'Variable Temperature Alert',
          description: 'Large daily temperature variations expected. This can stress plants. Consider season extenders and monitor sensitive crops closely.',
          iconName: 'device_thermostat',
          category: 'Pattern',
          priority: 2,
        ));
      }

      // Season-appropriate general tips
      DateTime now = DateTime.now();
      String season = _getCurrentSeason(now);

      tips.addAll(_getSeasonalTips(season));

      // Soil condition tips based on weather
      if (totalPrecip > 50) {
        tips.add(FarmingTip(
          title: 'Soil Moisture Management',
          description: 'Heavy rainfall this week may lead to waterlogged soils. Avoid heavy machinery use. Check for proper field drainage.',
          iconName: 'terrain',
          category: 'Soil',
          priority: 2,
        ));
      }

      // Sort tips by priority and limit to most relevant
      tips.sort((a, b) => a.priority.compareTo(b.priority));

      setState(() {
        _farmingTips = tips.take(8).toList(); // Limit to 8 most important tips
      });

    } catch (e) {
      print('Error generating farming tips: $e');
      // Set some default tips if generation fails
      setState(() {
        _farmingTips = [
          FarmingTip(
            title: 'Daily Monitoring',
            description: 'Check your crops daily for signs of stress, pests, or disease. Early detection is key to successful farming.',
            iconName: 'visibility',
            category: 'General',
            priority: 3,
          ),
        ];
      });
    }
  }

  String _getCurrentSeason(DateTime date) {
    int month = date.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  List<FarmingTip> _getSeasonalTips(String season) {
    switch (season) {
      case 'Spring':
        return [
          FarmingTip(
            title: 'Spring Planting Season',
            description: 'Perfect time for cool-season crops. Prepare seedbeds and start warm-season transplants indoors.',
            iconName: 'eco',
            category: 'Seasonal',
            priority: 3,
          ),
        ];
      case 'Summer':
        return [
          FarmingTip(
            title: 'Summer Growth Management',
            description: 'Focus on consistent watering and pest monitoring. Harvest early morning for best quality.',
            iconName: 'wb_sunny',
            category: 'Seasonal',
            priority: 3,
          ),
        ];
      case 'Fall':
        return [
          FarmingTip(
            title: 'Fall Harvest & Preparation',
            description: 'Harvest time for many crops. Begin winter preparation and cover crop planting.',
            iconName: 'agriculture',
            category: 'Seasonal',
            priority: 3,
          ),
        ];
      case 'Winter':
        return [
          FarmingTip(
            title: 'Winter Planning & Maintenance',
            description: 'Plan next year\'s crops. Maintain equipment and prepare for spring planting.',
            iconName: 'build',
            category: 'Seasonal',
            priority: 3,
          ),
        ];
      default:
        return [];
    }
  }

  // Helper methods for weather display
  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode <= 3) {
      return Icons.wb_sunny;
    } else if (weatherCode >= 45 && weatherCode <= 57) {
      return Icons.cloud;
    } else if ((weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return Icons.grain;
    } else if ((weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86)) {
      return Icons.ac_unit;
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      return Icons.flash_on;
    }
    return Icons.help_outline;
  }

  String _getWeatherCondition(int weatherCode) {
    if (weatherCode <= 3) {
      return "Clear";
    } else if (weatherCode >= 45 && weatherCode <= 57) {
      return "Foggy";
    } else if ((weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return "Rainy";
    } else if ((weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86)) {
      return "Snowy";
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      return "Thunderstorm";
    }
    return "Unknown";
  }

  Color _getWeatherColor(int weatherCode) {
    if (weatherCode <= 3) {
      return Color(0xFFF9A825);
    } else if (weatherCode >= 45 && weatherCode <= 57) {
      return Color(0xFF607D8B);
    } else if ((weatherCode >= 61 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return Color(0xFF1976D2);
    } else if ((weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86)) {
      return Color(0xFF00ACC1);
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      return Color(0xFF7B1FA2);
    }
    return Color(0xFF388E3C);
  }

  String _getDayName(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE').format(date);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  IconData _getTipIcon(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'water_drop_outlined':
        return Icons.water_drop_outlined;
      case 'thermostat':
        return Icons.thermostat;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'bug_report':
        return Icons.bug_report;
      case 'warning':
        return Icons.warning;
      case 'grain':
        return Icons.grain;
      case 'air':
        return Icons.air;
      case 'opacity':
        return Icons.opacity;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'cloud_queue':
        return Icons.cloud_queue;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'device_thermostat':
        return Icons.device_thermostat;
      case 'terrain':
        return Icons.terrain;
      case 'visibility':
        return Icons.visibility;
      case 'eco':
        return Icons.eco;
      case 'agriculture':
        return Icons.agriculture;
      case 'build':
        return Icons.build;
      default:
        return Icons.eco;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Color(0xFFE53935); // High priority - Red
      case 2:
        return Color(0xFFFF9800); // Medium priority - Orange
      case 3:
        return Color(0xFF4CAF50); // Low priority - Green
      default:
        return Color(0xFF4CAF50);
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'HIGH';
      case 2:
        return 'MED';
      case 3:
        return 'LOW';
      default:
        return 'INFO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading weather data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          // App Bar with Weather Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: _currentWeather != null
                ? _getWeatherColor(_currentWeather!['weather_code'])
                : Color(0xFF388E3C),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _currentWeather != null
                  ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getWeatherColor(_currentWeather!['weather_code']),
                      _getWeatherColor(_currentWeather!['weather_code']).withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white.withOpacity(0.9)),
                            SizedBox(width: 8),
                            Text(
                              widget.cityName,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_currentWeather!['temperature_2m'].toStringAsFixed(1)}°C',
                                  style: GoogleFonts.poppins(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _getWeatherCondition(_currentWeather!['weather_code']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Feels like ${_currentWeather!['apparent_temperature'].toStringAsFixed(1)}°C',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getWeatherIcon(_currentWeather!['weather_code']),
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(
                                icon: Icons.air,
                                value: '${_currentWeather!['wind_speed_10m'].toStringAsFixed(1)} km/h',
                                label: 'Wind',
                              ),
                              _buildWeatherDetail(
                                icon: Icons.opacity,
                                value: '${_currentWeather!['relative_humidity_2m'].toStringAsFixed(0)}%',
                                label: 'Humidity',
                              ),
                              _buildWeatherDetail(
                                icon: Icons.compress,
                                value: '${(_currentWeather!['surface_pressure'] ?? 1013).toStringAsFixed(0)} hPa',
                                label: 'Pressure',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : Container(),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Color(0xFF2E7D32),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: '7-Day Forecast'),
                  Tab(text: 'Farming Insights'),
                ],
              ),
            ),
            pinned: true,
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForecastTab(),
                _buildFarmingTipsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastTab() {
    return _dailyForecasts.isEmpty
        ? Center(
      child: Text(
        'No forecast data available',
        style: GoogleFonts.poppins(),
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _dailyForecasts.length,
      itemBuilder: (context, index) {
        final forecast = _dailyForecasts[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDayName(forecast.date),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            _formatDate(forecast.date),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getWeatherColor(forecast.weatherCode).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getWeatherIcon(forecast.weatherCode),
                              size: 24,
                              color: _getWeatherColor(forecast.weatherCode),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getWeatherCondition(forecast.weatherCode),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward, size: 16, color: Color(0xFFE53935)),
                                  SizedBox(width: 4),
                                  Text(
                                    '${forecast.maxTemp.toStringAsFixed(1)}°C',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward, size: 16, color: Color(0xFF1E88E5)),
                                  SizedBox(width: 4),
                                  Text(
                                    '${forecast.minTemp.toStringAsFixed(1)}°C',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Color(0xFF1E88E5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildForecastDetail(
                      icon: Icons.water_drop,
                      value: '${forecast.precipitation.toStringAsFixed(1)} mm',
                      label: 'Rain',
                      color: Color(0xFF1976D2),
                    ),
                    _buildForecastDetail(
                      icon: Icons.opacity,
                      value: '${forecast.humidity.toStringAsFixed(0)}%',
                      label: 'Humidity',
                      color: Color(0xFF00ACC1),
                    ),
                    _buildForecastDetail(
                      icon: Icons.air,
                      value: '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                      label: 'Wind',
                      color: Color(0xFF607D8B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForecastDetail({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmingTipsTab() {
    return _farmingTips.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
          SizedBox(height: 16),
          Text(
            'Generating farming insights...',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _farmingTips.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Farming Insights',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Personalized recommendations based on real-time weather data for ${widget.cityName}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Last updated: ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        final tip = _farmingTips[index - 1];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getPriorityColor(tip.priority).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(tip.priority).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTipIcon(tip.iconName),
                        color: _getPriorityColor(tip.priority),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            tip.category,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(tip.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityLabel(tip.priority),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  tip.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                if (tip.priority == 1) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: Color(0xFFE53935),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Immediate attention recommended',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper class for SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}