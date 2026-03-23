import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/alerts_dropdown.dart';
import '../services/weather_service.dart';
import '../services/auth_service.dart';
import '../services/audit_log_service.dart';
import '../models/weather_models.dart';
import '../utils/weather_utils.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';
import 'audit_logs_screen.dart';
import '../widgets/chatbot_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool isGateOpen = true;
  double waterHeightCm = 1500; // Default 15m
  double waterLevelM = 0.0;
  String waterLevelStatus = 'Normal';
  String lastUpdated = '';
  
  // Realtime Database reference
  final DatabaseReference _floodRef = FirebaseDatabase.instance.ref('flood_monitoring');

  // Modern Color Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  
  static const Color brandBlue = Color(0xFF0EA5E9);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  String _username = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Unknown';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isButtonDown = false;

  final WeatherService _weatherService = WeatherService();
  WeatherForecast? _weatherForecast;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserData();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final forecast = await _weatherService.getCompleteWeather('Philippines');
      if (mounted) {
        setState(() {
          _weatherForecast = forecast;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching weather data: $e");
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _email = user.email ?? 'No Email';
          _username = user.displayName ?? 'User';
        });
      }
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && mounted) {
            setState(() {
              _username = data['username'] ?? _username;
              _role = data['role'] ?? _role;
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
    
    // Listen to flood monitoring data
    _floodRef.onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          isGateOpen = data['floodgate_status'] != 'closed';
          waterHeightCm = (data['water_height_cm'] ?? 0).toDouble();
          waterLevelM = (data['water_level_m'] ?? 0).toDouble();
          waterLevelStatus = data['water_level']?.toString() ?? 'Normal';
          lastUpdated = data['last_updated']?.toString() ?? '';
        });
      }
    });
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
      drawer: _buildDrawer(),
      floatingActionButton: _buildChatbotFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCurrentStatusMessage(),
              const SizedBox(height: 20),
              _buildEmergencyFloodgateControl(),
              const SizedBox(height: 20),
              _buildWaterLevelMonitorCard(),
              const SizedBox(height: 20),
              _buildRainfallInfoCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
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
      backgroundColor: brandBlue,
      elevation: 6,
      icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      label: const Text(
        'AI Assistant',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCurrentStatusMessage() {
    final double simulatedMeters = waterLevelM;
    
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
              color: cardWhite,
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

  Widget _buildEmergencyFloodgateControl() {
    final Color statusColor = isGateOpen ? brandBlue : dangerRed;
    final String statusText = isGateOpen ? 'GATE OPEN: FLOW ACTIVE' : 'GATE CLOSED: FLOW BLOCKED';
    final String subText = isGateOpen ? 'System operating normally' : 'EMERGENCY: Restricted Flow';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY CONTROL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return AnimatedScale(
                scale: _isButtonDown ? 0.90 : (isGateOpen ? 1.0 : _pulseAnimation.value),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutQuad,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF1F5F9)], // Slight gradient for 3D effect
                    ),
                    boxShadow: _isButtonDown ? [
                      BoxShadow( // Pressed state shadow
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ] : [
                      BoxShadow( // Normal state drop shadow
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow( // Inner highlight shadow effect
                        color: Colors.white,
                        blurRadius: 5,
                        offset: Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: _toggleGateDialog,
                      onHighlightChanged: (isHighlighted) {
                        setState(() => _isButtonDown = isHighlighted);
                      },
                      splashColor: statusColor.withOpacity(0.2),
                      highlightColor: statusColor.withOpacity(0.1),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isGateOpen ? Icons.water : Icons.block,
                              size: 40,
                              color: statusColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isGateOpen ? 'CLOSE\nGATE' : 'RAISE\nGATE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: 0.5,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleGateDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isGateOpen ? Icons.warning_amber_rounded : Icons.info_outline, 
                color: isGateOpen ? warningOrange : brandBlue, 
                size: 28
              ),
              const SizedBox(width: 12),
              Text(
                isGateOpen ? 'Close Floodgate?' : 'Open Floodgate?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            isGateOpen 
              ? 'Are you sure you want to CLOSE the floodgate? This will stop water flow.'
              : 'Are you sure you want to OPEN the floodgate? This will allow water flow.',
            style: const TextStyle(fontSize: 16, color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newStatus = isGateOpen ? 'closed' : 'open';
                Navigator.of(dialogContext).pop();
                try {
                  await _floodRef.update({'floodgate_status': newStatus});
                  await AuditLogService().logEvent(
                    action: 'floodgate_update',
                    severity: 'warning',
                    description: 'Floodgate set to $newStatus',
                    role: _role,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('successfully updated floodgate to $newStatus'),
                        backgroundColor: successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Firebase Update Error: $e");
                  await AuditLogService().logEvent(
                    action: 'floodgate_update_failed',
                    severity: 'danger',
                    description: 'Failed to set floodgate to $newStatus: $e',
                    role: _role,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: dangerRed,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isGateOpen ? dangerRed : brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(isGateOpen ? 'Close Gate' : 'Open Gate', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterLevelMonitorCard() {
    final double simulatedMeters = waterLevelM;
    final bool isCritical = simulatedMeters >= 8;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Water Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCritical ? dangerRed.withOpacity(0.1) : successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCritical ? dangerRed : successGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      waterLevelStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCritical ? dangerRed : successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildGauge(),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${simulatedMeters.toStringAsFixed(2)}m',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Current Height',
                      style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    _buildLegendItem(dangerRed, 'Critical', '8m+'),
                    const SizedBox(height: 12),
                    _buildLegendItem(warningOrange, 'Warning', '7-8m'),
                    const SizedBox(height: 12),
                    _buildLegendItem(successGreen, 'Normal', '<7m'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    final double simulatedMeters = waterLevelM;
    return Container(
      width: 48,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: bgLight,
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Current water level overlay
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            curve: Curves.fastOutSlowIn,
            height: ((simulatedMeters / 11) * 220).clamp(0.0, 220.0), // Max 11 simulated meters mapped to 220px
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  brandBlue,
                  brandBlue.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          // Markers
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                width: index % 2 == 0 ? 20 : 10,
                height: 2,
                color: Colors.white.withOpacity(0.6),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String range) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const Spacer(),
        Text(range, style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRainfallInfoCard() {
    String value = '0';
    String unit = 'mm/hr';
    String condition = 'Loading...';
    IconData icon = Icons.cloud_outlined;

    if (!_isLoadingWeather && _weatherForecast != null) {
      final current = _weatherForecast!.currentWeather;
      final rainfallText = WeatherUtils.getRainfallInfo(current.description, current.main);
      final parts = rainfallText.split(' ');
      value = parts.isNotEmpty ? parts[0] : '0';
      unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'mm/hr';
      condition = WeatherUtils.capitalizeDescription(current.description);
      icon = WeatherUtils.getWeatherIcon(current.icon, current.main);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark sleek color
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: brandBlue, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Local Weather & Rainfall',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (_isLoadingWeather)
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit, style: const TextStyle(fontSize: 16, color: brandBlue, fontWeight: FontWeight.w600)),
                    Text(condition, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardWhite,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(icon: Icons.manage_accounts_rounded, title: 'Account', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Divider()),
                _buildDrawerItem(icon: Icons.logout_rounded, title: 'Logout', onTap: () async {
                  Navigator.pop(context);
                  await AuditLogService().logEvent(
                    action: 'logout',
                    severity: 'safe',
                    description: 'User logged out',
                    role: _role,
                  );
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                      (route) => false,
                    );
                  }
                }, isDestructive: true),
                if (_role == 'Admin')
                  _buildDrawerItem(icon: Icons.receipt_long_rounded, title: 'Audit Logs', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildDrawerHeaderContent(
        username: _username,
        email: _email,
        role: _role,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String username = _username;
        String role = _role;
        final String email = user.email ?? _email;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            username = data['username'] ?? username;
            role = data['role'] ?? role;
          }
        }

        return _buildDrawerHeaderContent(
          username: username,
          email: email,
          role: role,
        );
      },
    );
  }

  Widget _buildDrawerHeaderContent({required String username, required String email, required String role}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: brandBlue, width: 2),
            ),
            child: const Icon(Icons.person_rounded, size: 34, color: brandBlue),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
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
              color: isDestructive ? dangerRed.withOpacity(0.04) : const Color(0xFFF8FAFC),
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
                    color: isDestructive ? dangerRed.withOpacity(0.12) : brandBlue.withOpacity(0.12),
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
}
