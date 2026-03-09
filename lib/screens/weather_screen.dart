import 'package:flutter/material.dart';
import '../widgets/alerts_dropdown.dart';
import '../services/weather_service.dart';
import '../models/weather_models.dart';
import '../utils/weather_utils.dart';
import 'main_home_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // Color Palette
  static const Color deepSpaceBlue = Color(0xFF003249);
  static const Color cerulean = Color(0xFF007EA7);
  static const Color ambientGrey = Color(0xFFCCDBDC);

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
      print('Weather API Error: $e'); // Debug print
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
      backgroundColor: ambientGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshWeather,
          color: cerulean,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          // Navigate back to home tab instead of popping navigation stack
                          final MainHomeScreenState? mainScreen = context.findAncestorStateOfType<MainHomeScreenState>();
                          if (mainScreen != null) {
                            mainScreen.navigateToHome();
                          }
                        },
                        color: cerulean,
                        iconSize: 24,
                      ),
                      const Expanded(
                        child: Text(
                          'Weather Forecast',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: cerulean,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: _showNotificationsDropdown,
                        color: cerulean,
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    _buildLoadingWidget()
                  else if (_error != null)
                    _buildErrorWidget()
                  else if (_weatherForecast != null) ...[
                    _buildCurrentWeather(),
                    const SizedBox(height: 24),
                    const Text(
                      '5-Day Forecast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: deepSpaceBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildForecastList(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(40.0),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(cerulean),
            ),
            SizedBox(height: 16),
            Text(
              'Loading weather data...',
              style: TextStyle(
                fontSize: 16,
                color: deepSpaceBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchWeatherData,
            style: ElevatedButton.styleFrom(
              backgroundColor: cerulean,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
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
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: deepSpaceBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Weather',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Text(
                current.cityName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temperature,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherStat('Rainfall', rainfall),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildWeatherStat('Humidity', humidity),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildWeatherStat('Wind', windSpeed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: cerulean,
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
                        fontWeight: FontWeight.w600,
                        color: deepSpaceBlue,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                      fontWeight: FontWeight.w600,
                      color: deepSpaceBlue,
                    ),
                  ),
                  Text(
                    rainfall,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
