import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherUtils {
  // Get appropriate icon based on weather condition and icon code
  static IconData getWeatherIcon(String iconCode, String condition) {
    // OpenWeatherMap icon codes
    switch (iconCode.substring(0, 2)) {
      case '01': // clear sky
        return Icons.wb_sunny;
      case '02': // few clouds
        return Icons.cloud_queue_outlined;
      case '03': // scattered clouds
      case '04': // broken clouds
        return Icons.cloud_outlined;
      case '09': // shower rain
      case '10': // rain
        return Icons.grain; // rain icon
      case '11': // thunderstorm
        return Icons.flash_on;
      case '13': // snow
        return Icons.ac_unit;
      case '50': // mist
        return Icons.foggy;
      default:
        // Fallback based on main condition
        switch (condition.toLowerCase()) {
          case 'rain':
          case 'drizzle':
            return Icons.grain;
          case 'thunderstorm':
            return Icons.flash_on;
          case 'snow':
            return Icons.ac_unit;
          case 'clear':
            return Icons.wb_sunny;
          case 'clouds':
            return Icons.cloud_outlined;
          case 'mist':
          case 'smoke':
          case 'haze':
          case 'dust':
          case 'fog':
          case 'sand':
          case 'ash':
          case 'squall':
          case 'tornado':
            return Icons.foggy;
          default:
            return Icons.cloud_outlined;
        }
    }
  }

  // Format temperature
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°C';
  }

  // Format wind speed
  static String formatWindSpeed(double windSpeed) {
    // Convert from m/s to km/h
    double kmh = windSpeed * 3.6;
    return '${kmh.round()} km/h';
  }

  // Format humidity
  static String formatHumidity(int humidity) {
    return '$humidity%';
  }

  // Format pressure
  static String formatPressure(int pressure) {
    return '$pressure hPa';
  }

  // Capitalize first letter of each word in description
  static String capitalizeDescription(String description) {
    return description
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  // Format date for forecast
  static String formatForecastDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (targetDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (targetDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE').format(dateTime); // Day name (e.g., Monday)
    }
  }

  // Get rainfall info from weather description
  static String getRainfallInfo(String description, String main) {
    if (main.toLowerCase().contains('rain') || 
        description.toLowerCase().contains('rain')) {
      // This is a simplified rainfall estimate based on condition
      if (description.toLowerCase().contains('heavy')) {
        return '15-20 mm/hr';
      } else if (description.toLowerCase().contains('moderate')) {
        return '5-10 mm/hr';
      } else if (description.toLowerCase().contains('light')) {
        return '1-5 mm/hr';
      } else {
        return '10 mm/hr';
      }
    }
    return '0 mm/hr';
  }

  // Check if it's daytime (for icon selection)
  static bool isDaytime(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 6 && hour < 18;
  }

  // Get error message for common API errors
  static String getErrorMessage(String error) {
    if (error.contains('404')) {
      return 'City not found. Please check the city name.';
    } else if (error.contains('401') || error.contains('Invalid API key')) {
      return 'Invalid API key. Please check:\n• Email verification (check your inbox)\n• Wait 1-2 hours for key activation\n• Verify key in your OpenWeatherMap account';
    } else if (error.contains('429')) {
      return 'Too many requests. Please try again later.';
    } else if (error.contains('500')) {
      return 'Weather service is temporarily unavailable.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
}