class WeatherData {
  final double temperature;
  final String description;
  final String main;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String cityName;
  final String country;
  final DateTime dateTime;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.main,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.cityName,
    required this.country,
    required this.dateTime,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      main: json['weather'][0]['main'] as String,
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      cityName: json['name'] as String,
      country: json['sys']['country'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      icon: json['weather'][0]['icon'] as String,
    );
  }
}

class ForecastData {
  final DateTime dateTime;
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final String description;
  final String main;
  final int humidity;
  final double windSpeed;
  final String icon;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.main,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      minTemp: (json['main']['temp_min'] as num).toDouble(),
      maxTemp: (json['main']['temp_max'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      main: json['weather'][0]['main'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      icon: json['weather'][0]['icon'] as String,
    );
  }
}

class WeatherForecast {
  final WeatherData currentWeather;
  final List<ForecastData> forecast;

  WeatherForecast({
    required this.currentWeather,
    required this.forecast,
  });
}