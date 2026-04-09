import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/chatbot_modal.dart';
import '../widgets/alerts_dropdown.dart';
import '../services/weather_service.dart';
import '../services/auth_service.dart';
import '../utils/weather_utils.dart';
import '../models/weather_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class LGUDashboardScreen extends StatefulWidget {
  const LGUDashboardScreen({super.key});

  @override
  State<LGUDashboardScreen> createState() => _LGUDashboardScreenState();
}

class _LGUDashboardScreenState extends State<LGUDashboardScreen> with SingleTickerProviderStateMixin {
  // User info
  String _username = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Unknown';

  // Flood monitoring
  final DatabaseReference _floodRef = FirebaseDatabase.instance.ref('flood_monitoring');
  double waterHeightCm = 1500;
  String waterLevelStatus = 'Normal';
  String lastUpdated = '';
  bool isGateOpen = true;

  // Weather
  final WeatherService _weatherService = WeatherService();
  WeatherForecast? _weatherForecast;
  bool _isLoadingWeather = true;

  // Messaging
  final CollectionReference _messagesRef = FirebaseFirestore.instance.collection('lgu_messages');
  final TextEditingController _messageController = TextEditingController();

  // Navigation
  int _selectedIndex = 0;

  // LGU Colors
  static const Color primaryTeal = Color(0xFF00695C);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUserData();
    _fetchWeatherData();
    _listenFloodMonitoring();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? 'No Email';
      _username = user.displayName ?? 'User';
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            _username = data['username'] ?? _username;
            _role = data['role'] ?? _role;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
      if (!mounted) return;
      setState(() {});
    }
  }

  void _listenFloodMonitoring() {
  _floodRef.onValue.listen((event) async {
    if (event.snapshot.exists && mounted) {
      final data = event.snapshot.value as Map;

      double newHeight = (data['water_height_cm'] ?? 0).toDouble();

      setState(() {
        waterHeightCm = newHeight;
      });

      // import 'package:fl_chart/fl_chart.dart'; Save history automatically
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

       //removethe//HERE
      //await _floodRef.child('history/$timestamp').set(newHeight);
    }
  });
}

  Future<void> _fetchWeatherData() async {
    try {
      final forecast = await _weatherService.getCompleteWeather('Philippines');
      if (!mounted) return;
      setState(() {
        _weatherForecast = forecast;
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint("Weather fetch error: $e");
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _sendMessage() {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    _messagesRef.add({
      'message': msg,
      'sender': _username,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _messageController.clear();
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

  Widget _buildChatbotFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ChatbotModal(),
        );
      },
      backgroundColor: const Color.fromRGBO(14, 165, 233, 1),
      elevation: 6,
      icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      label: const Text(
        'AI Assistant',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCurrentStatusMessage() {
    final double simulatedMeters = waterHeightCm / 2.54;
    
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    if (simulatedMeters >= 8) {
      // CRITICAL LEVEL
      bgColor = dangerRed.withOpacity(0.1);
      iconColor = dangerRed;
      icon = Icons.warning_rounded;
      title = 'CRITICAL WATER LEVEL';
      message = 'Water levels exceed 8 meters. Immediate action required.';
    } else if (simulatedMeters >= 7) {
      // WARNING LEVEL
      bgColor = warningOrange.withOpacity(0.1);
      iconColor = warningOrange;
      icon = Icons.report_problem_rounded;
      title = 'WARNING: ELEVATED WATER LEVEL';
      message = 'Water levels are between 7 and 8 meters. Please monitor the situation closely.';
    } else {
      // NORMAL LEVEL
      bgColor = successGreen.withOpacity(0.1);
      iconColor = successGreen;
      icon = Icons.check_circle_outline_rounded;
      title = 'STATUS: NORMAL';
      message = 'Water levels are stable below 7 meters. No immediate action required.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildHeader() {
    return Row(
      children: [
        Builder(
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
              color: textPrimary,
              iconSize: 24,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            'Dashboard',
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
            color: const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
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

  // Replace _buildStatisticsTab() with this:
Widget _buildStatisticsTab() {
  final double meters = waterHeightCm / 100.0; // ← corrected: cm → m is /100
  final bool isCritical = meters >= 8;
  final bool isWarning  = meters >= 7 && meters < 8;
  final bool isNormal   = meters < 7;

  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero Water Level Card ──────────────────────────────────────────
        _buildHeroWaterCard(meters, isCritical, isWarning, isNormal),
        const SizedBox(height: 16),

        // ── Section Label ──────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'MONITORING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
        ),

        // ── 2-Column Stat Cards ────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _buildStatCard(
              label: 'Rain today',
              value: isCritical ? '87 mm' : '12 mm',
              sub: isCritical ? '▲ Heavy rainfall' : '▲ 3 mm from avg',
              subColor: isCritical ? dangerRed : successGreen,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(
              label: 'Temperature',
              value: _isLoadingWeather
                  ? '—'
                  : '${_weatherForecast!.currentWeather.temperature.toStringAsFixed(0)}°C',
              sub: _isLoadingWeather
                  ? 'Loading...'
                  : WeatherUtils.capitalizeDescription(
                      _weatherForecast!.currentWeather.description),
              subColor: textSecondary,
            )),
          ],
        ),
        const SizedBox(height: 10),

        // ── Weather Strip ──────────────────────────────────────────────────
        _buildWeatherStrip(isCritical),
      ],
    ),
  );
}

// ── Hero water level card ──────────────────────────────────────────────────────
Widget _buildHeroWaterCard(
    double meters, bool isCritical, bool isWarning, bool isNormal) {

  final Color statusColor = isCritical
      ? dangerRed
      : isWarning ? warningOrange : successGreen;
  final String statusLabel = isCritical
      ? 'Critical'
      : isWarning ? 'Warning' : 'Normal';
  final double gaugeFraction = (meters / 9.0).clamp(0.0, 1.0);
  final String gateStatus   = isGateOpen ? 'Open' : 'Closed';

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isCritical
            ? dangerRed.withOpacity(0.35)
            : Colors.black.withOpacity(0.07),
        width: isCritical ? 1.5 : 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        _buildStatusBadge(statusLabel, statusColor),
        const SizedBox(height: 14),

        // Meter value + gauge
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              meters.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: isCritical ? dangerRed : textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('meters',
                  style: TextStyle(fontSize: 14, color: textSecondary)),
            ),
            const Spacer(),
            // Gauge column
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3-zone gauge bar
                  Stack(
                    children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(
                            stops: [0, 0.78, 0.78, 0.89, 0.89, 1.0],
                            colors: [
                              Color(0xFF10B981), Color(0xFF10B981),
                              Color(0xFFF59E0B), Color(0xFFF59E0B),
                              Color(0xFFEF4444), Color(0xFFEF4444),
                            ],
                          ),
                        ),
                      ),
                      // Pointer
                      Positioned(
                        left: (gaugeFraction * 136).clamp(0, 136),
                        child: Container(
                          width: 3,
                          height: 11,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: statusColor.withOpacity(0.5),
                                  blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('0m', style: TextStyle(fontSize: 9, color: textSecondary)),
                      Text('7m', style: TextStyle(fontSize: 9, color: textSecondary)),
                      Text('8m+', style: TextStyle(fontSize: 9, color: textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Critical alert banner (only shown when critical)
        if (isCritical) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: dangerRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_rounded, color: dangerRed, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Immediate action required. Water exceeds 8 m threshold.',
                    style: TextStyle(fontSize: 11, color: dangerRed, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: 12),

        // Meta chips row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetaChip('Gate', gateStatus,
                isGateOpen ? successGreen : dangerRed),
            _buildMetaChip('Status', statusLabel, statusColor),
            _buildMetaChip('Updated', lastUpdated.isEmpty ? 'Just now' : lastUpdated,
                textSecondary),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatusBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildMetaChip(String label, String value, Color valueColor) {
  return Column(
    children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: textSecondary)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: valueColor)),
    ],
  );
}

Widget _buildStatCard({
  required String label,
  required String value,
  required String sub,
  required Color subColor,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(fontSize: 10, color: subColor)),
      ],
    ),
  );
}

Widget _buildWeatherStrip(bool isCritical) {
  if (_isLoadingWeather) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
    );
  }
  final w = _weatherForecast!.currentWeather;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: isCritical ? const Color(0xFF7F1D1D) : primaryTeal,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          WeatherUtils.getWeatherIcon(w.icon, w.main),
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${w.temperature.toStringAsFixed(0)}°C',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              WeatherUtils.capitalizeDescription(w.description),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${w.humidity ?? '—'}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Text('Humidity',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildChartsTab() {
  return StreamBuilder<DatabaseEvent>(
    stream: _floodRef.child('history').onValue, // Listen specifically to history for efficiency
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: primaryTeal));
      }

      if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
        return _buildEmptyState();
      }

      final Map<dynamic, dynamic> historyData = snapshot.data!.snapshot.value as Map;
      
      // Sort entries by timestamp (key)
      final sortedKeys = historyData.keys.toList()..sort();
      
      // Limit to last 10-15 readings so the chart doesn't get too crowded
      final recentKeys = sortedKeys.length > 15 
          ? sortedKeys.sublist(sortedKeys.length - 15) 
          : sortedKeys;

      List<FlSpot> spots = [];
      for (int i = 0; i < recentKeys.length; i++) {
        final key = recentKeys[i];
        double value = (historyData[key] ?? 0).toDouble() / 100; // cm to meters
        spots.add(FlSpot(i.toDouble(), value));
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Water Level Trends",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const Text(
              "Real-time history from sensors",
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= recentKeys.length || index % 3 != 0) {
                              return const SizedBox.shrink();
                            }
                            // Convert timestamp key to HH:mm
                            final date = DateTime.fromMillisecondsSinceEpoch(int.parse(recentKeys[index]));
                            return Text(
                              "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: textSecondary, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            "${value.toInt()}m",
                            style: const TextStyle(color: textSecondary, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primaryTeal,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              primaryTeal.withOpacity(0.3),
                              primaryTeal.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 12, // Based on your 8m critical threshold
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.show_chart_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text("No sensor data available yet", style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );
}

 Widget _buildMessagingTab() {
  return Column(
    children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _messagesRef.orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Connection Error"));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text("No messages yet. Start the conversation!", 
                      style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              );
            }

            return ListView.builder(
              reverse: true, // Key for chat apps: starts at bottom
              itemCount: docs.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final message = data['message'] ?? '';
                final sender = data['sender'] ?? 'Anonymous';
                final isMe = sender == _username; // Logic to check if you are the sender
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                return _buildChatBubble(message, sender, isMe, timestamp);
              },
            );
          },
        ),
      ),
      _buildMessageInput(),
    ],
  );
}

Widget _buildChatBubble(String message, String sender, bool isMe, DateTime time) {
  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(sender, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? primaryTeal : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMessageInput() {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 24), // Extra bottom padding for iOS/modern screens
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type an announcement...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14),
              ),
              maxLines: null, // Allows the box to expand with long text
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: primaryTeal,
          radius: 22,
          child: IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            onPressed: _sendMessage,
          ),
        ),
      ],
    ),
  );
}

  // ---------------- Drawer ----------------
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      color: primaryTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: const Icon(Icons.person_rounded, size: 34, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(_email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _role.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? dangerRed : textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDestructive ? dangerRed.withOpacity(0.04) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDestructive ? dangerRed.withOpacity(0.18) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDestructive ? dangerRed.withOpacity(0.12) : primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                ),
                Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildStatisticsTab(),
      _buildChartsTab(),
      _buildMessagingTab(),
    ];

    return Scaffold(
      appBar: AppBar(
  title: const Text('LGU Dashboard'),
  backgroundColor: (waterHeightCm / 100.0) >= 8 ? dangerRed : primaryTeal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: _showNotificationsDropdown,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Charts'),
          BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
        ],
      ),
    );
  }
}