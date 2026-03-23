import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/alerts_dropdown.dart';
import '../services/weather_service.dart';
import '../models/weather_models.dart';
import '../utils/weather_utils.dart';
import 'main_home_screen.dart';
import '../widgets/chatbot_modal.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // Modern Color Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color nightBlue = Color(0xFF0B1B3D);
  static const Color nightBlueDeep = Color(0xFF081432);
  static const Color starBlue = Color(0xFF1E3A8A);
  
  static const Color brandBlue = Color(0xFF007EAA);
  static const Color primaryGradientStart = Color(0xFF1D4ED8);
  static const Color primaryGradientEnd = Color(0xFF007EAA);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  final WeatherService _weatherService = WeatherService();
  WeatherForecast? _weatherForecast;
  bool _isLoading = true;
  String? _error;
  String _cityName = 'Philippines'; // Default city

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherForecast = await _weatherService.getCompleteWeather(_cityName);
      setState(() {
        _weatherForecast = weatherForecast;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Weather API Error: $e');
      setState(() {
        _error = WeatherUtils.getErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWeather() async {
    await _fetchWeatherData();
  }

  void _showNotificationsDropdown() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 60,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: const AlertsDropdown(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ChatbotModal(),
          );
        },
        backgroundColor: brandBlue,
        elevation: 6,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshWeather,
          color: brandBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_isLoading)
                  _buildLoadingWidget()
                else if (_error != null)
                  _buildErrorWidget()
                else if (_weatherForecast != null) ...[
                  _buildCurrentWeather(),
                  const SizedBox(height: 20),
                  _buildHourlyForecast(),
                  const SizedBox(height: 20),
                  _buildSunriseCard(),
                  const SizedBox(height: 20),
                  _buildDailyForecast(),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              final MainHomeScreenState? mainScreen = context.findAncestorStateOfType<MainHomeScreenState>();
              if (mainScreen != null) {
                mainScreen.navigateToHome();
              }
            },
            color: textPrimary,
            iconSize: 20,
          ),
        ),
        const Expanded(
          child: Text(
            'Weather',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: _showNotificationsDropdown,
            color: textPrimary,
            iconSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(brandBlue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Fetching latest weather data...',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dangerRed.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: dangerRed.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dangerRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: dangerRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _error ?? 'An expected error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchWeatherData,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_weatherForecast == null) return const SizedBox();
    
    final current = _weatherForecast!.currentWeather;
    final icon = WeatherUtils.getWeatherIcon(current.icon, current.main);
    final temperature = WeatherUtils.formatTemperature(current.temperature);
    final description = WeatherUtils.capitalizeDescription(current.description);
    final windSpeed = WeatherUtils.formatWindSpeed(current.windSpeed);
    final humidity = WeatherUtils.formatHumidity(current.humidity);
    final rainfall = WeatherUtils.getRainfallInfo(current.description, current.main);
    final feelsLike = WeatherUtils.formatTemperature(current.feelsLike);

    final hourly = _weatherForecast?.hourlyForecast ?? [];
    final temps = hourly.isNotEmpty ? hourly.map((h) => h.temperature).toList() : [current.temperature];
    final minTemp = WeatherUtils.formatTemperature(temps.reduce((a, b) => a < b ? a : b));
    final maxTemp = WeatherUtils.formatTemperature(temps.reduce((a, b) => a > b ? a : b));
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nightBlue, starBlue],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: nightBlue.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    current.cityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temperature,
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '↑ $maxTemp  ↓ $minTemp  •  Feels like $feelsLike',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 90, color: Colors.white),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherStat(Icons.water_drop_rounded, 'Rainfall', rainfall),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                    _buildWeatherStat(Icons.water_rounded, 'Humidity', humidity),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                    _buildWeatherStat(Icons.air_rounded, 'Wind', windSpeed),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    if (_weatherForecast == null) return const SizedBox();
    final hourly = _weatherForecast!.hourlyForecast;
    if (hourly.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nightBlueDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = hourly[index];
                final hourLabel = DateFormat('h a').format(item.dateTime);
                final icon = WeatherUtils.getWeatherIcon(item.icon, item.main);
                final temp = WeatherUtils.formatTemperature(item.temperature);
                return Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hourLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        temp,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseCard() {
    if (_weatherForecast == null) return const SizedBox();
    final current = _weatherForecast!.currentWeather;
    if (current.sunrise == null || current.sunset == null) return const SizedBox();

    final sunriseText = DateFormat('h:mm a').format(current.sunrise!);
    final sunsetText = DateFormat('h:mm a').format(current.sunset!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: warningOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: warningOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sunrise & Sunset',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sunrise $sunriseText  •  Sunset $sunsetText',
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    if (_weatherForecast == null) return const SizedBox();
    final daily = _weatherForecast!.forecast;
    if (daily.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5-Day Forecast',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 12),
          ...daily.map((forecast) {
            final day = WeatherUtils.formatForecastDate(forecast.dateTime);
            final minTemp = WeatherUtils.formatTemperature(forecast.minTemp);
            final maxTemp = WeatherUtils.formatTemperature(forecast.maxTemp);
            final icon = WeatherUtils.getWeatherIcon(forecast.icon, forecast.main);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      day,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ),
                  Icon(icon, size: 20, color: brandBlue),
                  const SizedBox(width: 12),
                  Text(
                    minTemp,
                    style: const TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    maxTemp,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    if (_weatherForecast == null) return const SizedBox();
    
    return Column(
      children: _weatherForecast!.forecast.map((forecast) {
        final day = WeatherUtils.formatForecastDate(forecast.dateTime);
        final temp = WeatherUtils.formatTemperature(forecast.temperature);
        final description = WeatherUtils.capitalizeDescription(forecast.description);
        final rainfall = WeatherUtils.getRainfallInfo(forecast.description, forecast.main);
        final icon = WeatherUtils.getWeatherIcon(forecast.icon, forecast.main);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: brandBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    temp,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rainfall,
                    style: const TextStyle(
                      fontSize: 12,
                      color: brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
