import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/alerts_dropdown.dart';
import '../utils/notifications.dart';
import '../services/weather_service.dart';
import '../utils/formatters.dart';
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
  double waterLevelM = 0.0;
  String lastUpdated = '';
  
  // Realtime Database reference (null until device is loaded)
  DatabaseReference? _floodRef;
  StreamSubscription<DatabaseEvent>? _floodSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
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

  int _currentAlarmLevel = 0; // 0: Normal, 1: Watch, 2: Warning, 3: Danger, 4: Emergency

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
      final forecast = await _weatherService.getCompleteWeather('Marikina');
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
    _userSubscription?.cancel();
    _floodSubscription?.cancel();
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

      // LISTEN to real-time changes in the user's Firestore document
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists || !mounted) return;

        final data = snapshot.data();
        if (data != null) {
          final String? newGateId = data['assigned_gate_id'];

          setState(() {
            _username = data['username'] ?? _username;
            _role = data['role'] ?? _role;
          });

          // DEVICE ASSIGNMENT REACTION LOGIC
          if (newGateId != assignedGateId) {
            // Cancel existing RTDB listener before switching
            _floodSubscription?.cancel();
            
            setState(() {
              assignedGateId = newGateId;
              _isLoadingDevice = (newGateId != null);
            });

            if (newGateId != null) {
              _floodRef = FirebaseDatabase.instance.ref('flood_monitoring/$newGateId');
              
              // Start listening to the NEWly assigned gate
              _floodSubscription = _floodRef!.onValue.listen((event) {
                if (!mounted) return;
                
                if (event.snapshot.exists) {
                  final floodData = event.snapshot.value as Map<dynamic, dynamic>;
                  setState(() {
                    isGateOpen = floodData['floodgate_status'] != 'closed';
                    waterLevelM = (floodData['water_level_m'] ?? 0).toDouble();
                    lastUpdated = floodData['last_updated']?.toString() ?? '';
                    _isLoadingDevice = false;
                  });

                  // --- MARIKINA THRESHOLD LOGIC ---
                  int newAlarmLevel = 0;
                  if (waterLevelM >= 18.0) {
                    newAlarmLevel = 4;
                  } else if (waterLevelM >= 17.0) {
                    newAlarmLevel = 3;
                  } else if (waterLevelM >= 16.0) {
                    newAlarmLevel = 2;
                  } else if (waterLevelM >= 15.0) {
                    newAlarmLevel = 1;
                  }

                  if (newAlarmLevel > _currentAlarmLevel) {
                    _currentAlarmLevel = newAlarmLevel;
                    // Skip showing level 1 if gate is already closed (no point recommending gate closure only)
                    if (!(newAlarmLevel == 1 && !isGateOpen)) {
                      _showLevelThresholdDialog(newAlarmLevel, waterLevelM);
                    }
                  } else if (newAlarmLevel < _currentAlarmLevel) {
                    _currentAlarmLevel = newAlarmLevel; // Reset state when level recedes
                  }
                } else {
                  setState(() => _isLoadingDevice = false);
                }
              });
            } else {
              // No device assigned
              _floodRef = null;
              setState(() => _isLoadingDevice = false);
            }
          }
        }
      }, onError: (e) {
        debugPrint("Error listening to user data: $e");
        if (mounted) setState(() => _isLoadingDevice = false);
      });
    }
  }

  Future<void> _showNotificationsDropdown() async {
    final result = await showDialog<String>(
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

    if (result == 'switch_tab_0' && mounted) {
      SwitchTabNotification(0).dispatch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgLight,
      child: SafeArea(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: textPrimary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MONITOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('Hello, ${_username.split(' ')[0]}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: _showNotificationsDropdown,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: textPrimary, size: 24),
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

  void _showLevelThresholdDialog(int level, double levelMeters) {
    if (!mounted) return;
    
    final parentContext = context;
    
    String title = '';
    String message = '';
    Color themeColor = warningOrange; // default
    IconData iconData = Icons.warning_amber_rounded;
    String actionText = 'Close Gate';
    
    if (level == 1) {
      title = 'LEVEL 1: WATCH';
      message = 'Water level shifted to ${levelMeters.toStringAsFixed(1)} m. The system recommends closing the floodgate for protection.';
      themeColor = const Color(0xFFEAB308); // Amber
      actionText = 'Close Floodgate';
    } else if (level == 2) {
      title = 'LEVEL 2: WARNING';
      message = 'Water level reached ${levelMeters.toStringAsFixed(1)} m. Prepare to evacuate or stay indoors and wait for the flood to settle.';
      themeColor = warningOrange;
      actionText = 'Prepare & Close Gate';
    } else if (level == 3) {
      title = 'LEVEL 3: DANGER';
      message = 'Water level is at ${levelMeters.toStringAsFixed(1)} m. It is highly recommended to evacuate to your designated evacuation centers now.';
      themeColor = dangerRed;
      actionText = 'Evacuate & Close Gate';
    } else if (level == 4) {
      title = 'LEVEL 4: EMERGENCY';
      message = 'Water level has reached ${levelMeters.toStringAsFixed(1)} m. FORCE EVACUATION is now in effect. Please proceed to the nearest safe zone immediately.';
      themeColor = const Color(0xFF7F1D1D); // Dark Red
      actionText = 'Close Gate & Contacts';
    }

    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(iconData, color: themeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: themeColor),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: textSecondary, height: 1.4),
                ),
                if (level == 4) ...[
                  const SizedBox(height: 16),
                  const Text('EMERGENCY CONTACTS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                  const SizedBox(height: 8),
                  _buildEmergencyContactRow('Marikina Rescue', '161'),
                  _buildEmergencyContactRow('Marikina Police', '941-4033'),
                  _buildEmergencyContactRow('Marikina Fire Dept', '941-4532'),
                  _buildEmergencyContactRow('NDRRMC', '911-5061'),
                  _buildEmergencyContactRow('Red Cross Marikina', '942-3974'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Dismiss', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
              ),
              if (isGateOpen)
                ElevatedButton(
                  onPressed: () async {
                    final newStatus = 'closed';
                    Navigator.of(dialogContext).pop();
                    try {
                      if (_floodRef != null) {
                        await _floodRef!.update({'floodgate_status': newStatus});
                        
                        await AuditLogService().logEvent(
                          action: 'floodgate_update',
                          severity: level >= 3 ? 'danger' : 'warning',
                          description: 'Floodgate closed from Level $level prompt on device $assignedGateId',
                          role: _role,
                        );

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance.collection('announcements').add({
                            'userId': user.uid,
                            'message': '$_username closed the floodgate ($assignedGateId) at Level $level.',
                            'title': 'Emergency Floodgate Action',
                            'type': level >= 3 ? 'emergency' : 'warning',
                            'timestamp': FieldValue.serverTimestamp(),
                            'sender': 'System',
                            'gateId': assignedGateId,
                          });
                        }
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Floodgate closed successfully.'),
                            backgroundColor: successGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Firebase Update Error: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          );
        },
      );
    });
  }

  Widget _buildEmergencyContactRow(String name, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14, color: textSecondary)),
          GestureDetector(
            onTap: () async {
               final String rawNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
               final Uri url = Uri(scheme: 'tel', path: rawNumber);
               if (await canLaunchUrl(url)) {
                 await launchUrl(url);
               } else {
                 debugPrint('Could not launch \$number');
               }
            },
            child: Text(
              number, 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D), decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
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
