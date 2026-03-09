import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_models.dart';

class WeatherService {
  // Initialize environment variables with fallbacks
  static String get _apiKey {
    try {
      final key = dotenv.env['OPENWEATHER_API_KEY'] ?? '0a428c33d880ef5798145243b047d322';
      print("API Key loaded: ${key.isEmpty ? 'EMPTY' : 'SUCCESS (${key.length} characters)'}");
      return key;
    } catch (e) {
      print("Error accessing dotenv for API key: $e");
      // Fallback if dotenv is not initialized
      return '0a428c33d880ef5798145243b047d322';
    }
  }
  
  static String get _baseUrl {
    try {
      return dotenv.env['OPENWEATHER_BASE_URL'] ?? 'https://api.openweathermap.org/data/2.5';
    } catch (e) {
      // Fallback if dotenv is not initialized
      return 'https://api.openweathermap.org/data/2.5';
    }
  }
  
  // Get current weather for a city
  Future<WeatherData> getCurrentWeather(String cityName) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenWeatherMap API key is not configured. Please check your .env file.');
      }
      
      final url = '$_baseUrl/weather?q=$cityName&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  // Get current weather by coordinates
  Future<WeatherData> getCurrentWeatherByCoordinates(double lat, double lon) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenWeatherMap API key is not configured. Please check your .env file.');
      }
      
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  // Get 5-day forecast for a city
  Future<List<ForecastData>> getForecast(String cityName) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenWeatherMap API key is not configured. Please check your .env file.');
      }
      
      final url = '$_baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Group forecasts by day and take one forecast per day (noon forecast)
        Map<String, ForecastData> dailyForecasts = {};
        
        for (var item in forecastList) {
          final forecast = ForecastData.fromJson(item);
          final dateKey = _formatDateKey(forecast.dateTime);
          
          // Take the forecast that's closest to noon (12:00)
          if (!dailyForecasts.containsKey(dateKey) || 
              _isCloserToNoon(forecast.dateTime, dailyForecasts[dateKey]!.dateTime)) {
            dailyForecasts[dateKey] = forecast;
          }
        }
        
        return dailyForecasts.values.take(5).toList();
      } else {
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }

  // Get 5-day forecast by coordinates
  Future<List<ForecastData>> getForecastByCoordinates(double lat, double lon) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        throw Exception('OpenWeatherMap API key is not configured. Please check your .env file.');
      }
      
      final url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        // Group forecasts by day and take one forecast per day (noon forecast)
        Map<String, ForecastData> dailyForecasts = {};
        
        for (var item in forecastList) {
          final forecast = ForecastData.fromJson(item);
          final dateKey = _formatDateKey(forecast.dateTime);
          
          // Take the forecast that's closest to noon (12:00)
          if (!dailyForecasts.containsKey(dateKey) || 
              _isCloserToNoon(forecast.dateTime, dailyForecasts[dateKey]!.dateTime)) {
            dailyForecasts[dateKey] = forecast;
          }
        }
        
        return dailyForecasts.values.take(5).toList();
      } else {
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }

  // Get both current weather and forecast
  Future<WeatherForecast> getCompleteWeather(String cityName) async {
    try {
      final currentWeather = await getCurrentWeather(cityName);
      final forecast = await getForecast(cityName);
      
      return WeatherForecast(
        currentWeather: currentWeather,
        forecast: forecast,
      );
    } catch (e) {
      throw Exception('Error fetching complete weather data: $e');
    }
  }

  // Get both current weather and forecast by coordinates
  Future<WeatherForecast> getCompleteWeatherByCoordinates(double lat, double lon) async {
    try {
      final currentWeather = await getCurrentWeatherByCoordinates(lat, lon);
      final forecast = await getForecastByCoordinates(lat, lon);
      
      return WeatherForecast(
        currentWeather: currentWeather,
        forecast: forecast,
      );
    } catch (e) {
      throw Exception('Error fetching complete weather data: $e');
    }
  }

  String _formatDateKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  bool _isCloserToNoon(DateTime current, DateTime existing) {
    const noonHour = 12;
    final currentDiff = (current.hour - noonHour).abs();
    final existingDiff = (existing.hour - noonHour).abs();
    return currentDiff < existingDiff;
  }
}