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
import 'package:flutter_svg/flutter_svg.dart';
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
  
  // Realtime Database reference (null until device is loaded)
  DatabaseReference? _floodRef;
  String? assignedGateId;
  bool _isLoadingDevice = true;

  // Modern Color Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  
  static const Color brandBlue = Color(0xFF007EAA);
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
              // FETCH ASSIGNED GATE ID
              assignedGateId = data['assigned_gate_id'];
            });

            if (assignedGateId != null) {
              // Initialize Ref to the specific gate
              _floodRef = FirebaseDatabase.instance.ref('flood_monitoring/$assignedGateId');
              
              // Listen to flood monitoring data for THIS gate
              _floodRef!.onValue.listen((event) {
                if (event.snapshot.exists && mounted) {
                  final data = event.snapshot.value as Map<dynamic, dynamic>;
                  setState(() {
                    isGateOpen = data['floodgate_status'] != 'closed';
                    waterHeightCm = (data['water_height_cm'] ?? 0).toDouble();
                    // Read the meter value directly (1:1 mapping with database)
                    waterLevelM = (data['water_level_m'] ?? 0).toDouble();
                    waterLevelStatus = data['water_level']?.toString() ?? 'Normal';
                    lastUpdated = data['last_updated']?.toString() ?? '';
                    _isLoadingDevice = false;
                  });
                } else if (mounted) {
                   setState(() => _isLoadingDevice = false);
                }
              });
            } else {
              if (mounted) setState(() => _isLoadingDevice = false);
            }
          }
        } else {
          if (mounted) setState(() => _isLoadingDevice = false);
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
        if (mounted) setState(() => _isLoadingDevice = false);
      }
    }
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

      body: SafeArea(
        child: _isLoadingDevice 
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : assignedGateId == null
            ? _buildNoDeviceState()
            : SingleChildScrollView(
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

  Widget _buildCurrentStatusMessage() {
    final double simulatedMeters = waterLevelM;
    
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    if (simulatedMeters >= 18.0) {
      // CRITICAL LEVEL
      bgColor = dangerRed.withOpacity(0.1);
      iconColor = dangerRed;
      icon = Icons.warning_rounded;
      title = 'CRITICAL WATER LEVEL';
      message = 'Water levels exceed 18m. Immediate action required.';
    } else if (simulatedMeters >= 15.0) {
      // CAUTION LEVEL
      bgColor = warningOrange.withOpacity(0.1);
      iconColor = warningOrange;
      icon = Icons.report_problem_rounded;
      title = 'CAUTION: ELEVATED WATER LEVEL';
      message = 'Water levels are 15m or higher. Please monitor the situation closely.';
    } else {
      // NORMAL LEVEL
      bgColor = successGreen.withOpacity(0.1);
      iconColor = successGreen;
      icon = Icons.check_circle_outline_rounded;
      title = 'STATUS: NORMAL';
      message = 'Water levels are stable below 15m. No immediate action required.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: iconColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: iconColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: textPrimary, size: 24),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showNotificationsDropdown,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: textPrimary, size: 24),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: dangerRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Welcome Back, ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
              TextSpan(
                text: '${_username.split(' ')[0]}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyFloodgateControl() {
    final Color statusColor = isGateOpen ? brandBlue : dangerRed;
    final String statusText = isGateOpen ? 'GATE OPEN: FLOW ACTIVE' : 'GATE CLOSED: FLOW BLOCKED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY CONTROL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
                scale: _isButtonDown ? 0.92 : (isGateOpen ? 1.0 : _pulseAnimation.value),
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isGateOpen ? Icons.water_drop_rounded : Icons.block_flipped,
                              size: 40,
                              color: statusColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isGateOpen ? 'CLOSE\nGATE' : 'OPEN\nGATE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
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
          const SizedBox(height: 20),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
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
                  if (_floodRef != null) {
                    await _floodRef!.update({'floodgate_status': newStatus});
                    
                    // 1. Existing Audit Log (RTDB)
                    await AuditLogService().logEvent(
                      action: 'floodgate_update',
                      severity: 'warning',
                      description: 'Floodgate set to $newStatus on device $assignedGateId',
                      role: _role,
                    );

                    // 2. NEW: Announcements Log (Firestore)
                    // This will recreate the collection if it was deleted
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('announcements').add({
                        'userId': user.uid,
                        'message': '$_username ${newStatus == 'open' ? 'opened' : 'closed'} the floodgate ($assignedGateId).',
                        'title': 'Floodgate Update',
                        'type': 'gate_log',
                        'timestamp': FieldValue.serverTimestamp(),
                        'sender': 'System',
                        'gateId': assignedGateId,
                      });
                    }
                  }
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
    final bool isCritical = simulatedMeters >= 18.0;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
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
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (waterLevelM >= 18.0 ? dangerRed : (waterLevelM >= 15.0 ? warningOrange : successGreen)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: waterLevelM >= 18.0 ? dangerRed : (waterLevelM >= 15.0 ? warningOrange : successGreen),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (waterLevelM >= 18.0 ? 'CRITICAL' : (waterLevelM >= 15.0 ? 'CAUTION' : 'SAFE')),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: waterLevelM >= 18.0 ? dangerRed : (waterLevelM >= 15.0 ? warningOrange : successGreen),
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
                      '${simulatedMeters.toInt()}m',
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
                    _buildLegendItem(dangerRed, 'Critical', '18m+'),
                    const SizedBox(height: 12),
                    _buildLegendItem(warningOrange, 'Caution', '15-18m'),
                    const SizedBox(height: 12),
                    _buildLegendItem(successGreen, 'Normal', '<15m'),
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
            height: ((simulatedMeters / 25) * 220).clamp(0.0, 220.0), // Max 25cm mapped to 220px
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  (simulatedMeters >= 18.0 ? dangerRed : (simulatedMeters >= 15.0 ? warningOrange : brandBlue)),
                  (simulatedMeters >= 18.0 ? dangerRed : (simulatedMeters >= 15.0 ? warningOrange : brandBlue)).withOpacity(0.8),
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

  Widget _buildNoDeviceState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.router_rounded, color: brandBlue, size: 64),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Device Linked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account is not currently linked to a HydroGate device. Please contact your LGU or Admin to assign your gateway.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _loadUserData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Refresh Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
