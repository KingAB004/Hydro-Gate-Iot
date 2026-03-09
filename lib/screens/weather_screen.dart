import 'package:flutter/material.dart';
import '../widgets/alerts_dropdown.dart';

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
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
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
          ),
        ),
    );
  }

  Widget _buildCurrentWeather() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: deepSpaceBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Weather',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '24°C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Moderate Rain',
                    style: TextStyle(
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
              _buildWeatherStat('Rainfall', '12 mm/hr'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildWeatherStat('Humidity', '85%'),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
              ),
              _buildWeatherStat('Wind', '12 km/h'),
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
    final forecasts = [
      {
        'day': 'Today',
        'temp': '24°C',
        'condition': 'Moderate Rain',
        'rainfall': '12 mm/hr',
        'icon': Icons.cloud_outlined,
      },
      {
        'day': 'Tomorrow',
        'temp': '22°C',
        'condition': 'Heavy Rain',
        'rainfall': '18 mm/hr',
        'icon': Icons.cloud_outlined,
      },
      {
        'day': 'Friday',
        'temp': '26°C',
        'condition': 'Light Rain',
        'rainfall': '5 mm/hr',
        'icon': Icons.cloud_outlined,
      },
      {
        'day': 'Saturday',
        'temp': '28°C',
        'condition': 'Partly Cloudy',
        'rainfall': '2 mm/hr',
        'icon': Icons.cloud_queue_outlined,
      },
      {
        'day': 'Sunday',
        'temp': '27°C',
        'condition': 'Light Rain',
        'rainfall': '8 mm/hr',
        'icon': Icons.cloud_outlined,
      },
    ];

    return Column(
      children: forecasts.map((forecast) {
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
                forecast['icon'] as IconData,
                size: 40,
                color: cerulean,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast['day'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: deepSpaceBlue,
                      ),
                    ),
                    Text(
                      forecast['condition'] as String,
                      style: TextStyle(
                        fontSize: 13,
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
                    forecast['temp'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: deepSpaceBlue,
                    ),
                  ),
                  Text(
                    forecast['rainfall'] as String,
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
