import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'weather_service.dart';

class ChatService {
  GenerativeModel? _model;
  ChatSession? _chat;
  final WeatherService _weatherService = WeatherService();

  // Lazily initializes the model and chat session with live context
  Future<void> _initializeChat() async {
    final apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured in .env file.');
    }

    // 1. Fetch the current user's assigned gate ID
    final user = FirebaseAuth.instance.currentUser;
    String? assignedGateId;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      assignedGateId = userDoc.data()?['assigned_gate_id'];
    }

    String floodContext = 'Flood monitoring data is currently unavailable.';
    if (assignedGateId != null) {
      final floodRef = FirebaseDatabase.instance.ref('flood_monitoring/$assignedGateId');
      final event = await floodRef.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final waterLevelM = (data['water_level_m'] ?? 0).toDouble();
        final gateStatus = data['floodgate_status'] ?? 'unknown';
        final waterLevel = data['water_level'] ?? 'unknown';
        final lastUpdated = data['last_updated'] ?? 'unknown';

        floodContext = '''
Current Flood Monitoring Status (Device: $assignedGateId):
- Water Height: ${waterLevelM.toStringAsFixed(3)} meters
- Water Level Status: $waterLevel
- Floodgate Status: $gateStatus
- Last Updated: $lastUpdated

Water Level Thresholds:
- Normal: 15.0m and below
- Caution: 15.1m to 17.9m
- Critical: 18.0m and above
''';
      }
    }

    // 2. Fetch current weather data
    String weatherContext = 'Weather data is currently unavailable.';
    try {
      final forecast = await _weatherService.getCompleteWeather('Philippines');
      final current = forecast.currentWeather;
      weatherContext = '''
Current Weather Conditions (Philippines):
- Temperature: ${current.temperature.toStringAsFixed(1)}°C
- Feels Like: ${current.feelsLike.toStringAsFixed(1)}°C
- Description: ${current.description}
- Humidity: ${current.humidity}%
- Wind Speed: ${current.windSpeed} m/s
''';
    } catch (e) {
      // Weather fetch failed, use fallback message
    }

    // 3. Build the system prompt with live data
    final systemPrompt = '''
You are an AI assistant for the HydroGate (Automated Floodgate and Monitoring System), a flood management application.
Your role is to help users understand the current flood situation, water levels, and weather conditions.

Here is the LIVE data as of right now:

$floodContext

$weatherContext

Instructions:
- Always respond in a clear, concise, and helpful manner.
- When asked about water levels, floodgate status, or weather, use the live data provided above.
- If the water level is Critical (18.0+), emphasize urgency and safety.
- If the water level is Caution (15.1-17.9), advise users to stay alert.
- If Normal (<=15.0), reassure the user but remind them to stay informed.
- You are read-only; you cannot control the floodgate. Only authorized admins can do that via the dashboard.
- Keep responses brief and focused on flood safety and system status.
- If asked something outside your scope (e.g., general trivia), politely redirect the user to flood-related topics.
''';

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content('system', [TextPart(systemPrompt)]),
    );
    _chat = _model!.startChat();
  }

  /// Sends a message and returns the AI response.
  /// Re-initializes the chat with fresh data on each new conversation.
  Future<String> sendMessage(String userMessage) async {
    try {
      if (_chat == null) {
        await _initializeChat();
      }
      final response = await _chat!.sendMessage(Content.text(userMessage));
      return response.text ?? 'I could not generate a response. Please try again.';
    } catch (e) {
      return 'An error occurred: ${e.toString()}. Please check your connection and try again.';
    }
  }

  /// Resets the chat session so next message starts a fresh conversation with updated data.
  void resetChat() {
    _chat = null;
    _model = null;
  }
}
