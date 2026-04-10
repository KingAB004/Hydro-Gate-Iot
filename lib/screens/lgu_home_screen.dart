import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/chatbot_modal.dart';
import '../widgets/alerts_dropdown.dart';
import '../services/weather_service.dart';
import '../utils/formatters.dart';
import '../services/auth_service.dart';
import '../utils/weather_utils.dart';
import '../models/weather_models.dart';
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
  String _role = 'LGU';
  String? _assignedGateId;

  // Flood monitoring
  DatabaseReference? _floodRef;
  StreamSubscription<DatabaseEvent>? _floodSubscription;
  double waterLevelM = 0.0;
  bool isGateOpen = true;
  String lastUpdated = '';

  // Water level threshold prompt flags
  bool _hasShownWarningPrompt = false;
  bool _hasShownCriticalPrompt = false;

  // Weather
  final WeatherService _weatherService = WeatherService();
  WeatherForecast? _weatherForecast;
  bool _isLoadingWeather = true;

  // Messaging (Announcements)
  final CollectionReference _announcementsRef = FirebaseFirestore.instance.collection('announcements');
  final TextEditingController _announcementTitleController = TextEditingController();
  final TextEditingController _announcementDescController = TextEditingController();
  String _selectedPriority = 'info';

  // Navigation
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Professional Teal Palette
  static const Color brandTeal = Color(0xFF00897B);
  static const Color brandTealDark = Color(0xFF00695C);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _floodSubscription?.cancel();
    _announcementTitleController.dispose();
    _announcementDescController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      setState(() {
        _email = user.email ?? 'No Email';
        _username = user.displayName ?? 'LGU User';
      });
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          if (data != null) {
            setState(() {
              _username = data['username'] ?? _username;
              _role = data['role'] ?? _role;
              _assignedGateId = data['assigned_gate_id'];
            });

            if (_assignedGateId != null) {
              _floodRef = FirebaseDatabase.instance.ref('flood_monitoring/$_assignedGateId');
              
              // Cancel any existing subscription before creating a new one
              await _floodSubscription?.cancel();
              
              _floodSubscription = _floodRef!.onValue.listen((event) {
                if (event.snapshot.exists && mounted) {
                  final floodData = event.snapshot.value as Map<dynamic, dynamic>;
                  setState(() {
                    isGateOpen = floodData['floodgate_status'] != 'closed';
                    waterLevelM = (floodData['water_level_m'] ?? 0.0).toDouble();
                    lastUpdated = floodData['last_updated']?.toString() ?? 'Just now';
                  });

                  // --- THRESHOLD ALERT LOGIC ---
                  if (mounted && isGateOpen) {
                    if (waterLevelM >= 18.0 && !_hasShownCriticalPrompt) {
                      _hasShownCriticalPrompt = true;
                      _showLevelThresholdDialog(
                        isCritical: true,
                        message: 'Water level has reached CRITICAL (${waterLevelM.toStringAsFixed(1)}m). It is highly recommended to CLOSE the gate immediately.',
                      );
                    } else if (waterLevelM >= 16.0 && waterLevelM < 18.0 && !_hasShownWarningPrompt) {
                      _hasShownWarningPrompt = true;
                      _showLevelThresholdDialog(
                        isCritical: false,
                        message: 'Water level has reached CAUTION (${waterLevelM.toStringAsFixed(1)}m). Consider closing the gate.',
                      );
                    }
                  }

                  // Reset flags if level drops back down
                  if (waterLevelM < 16.0) {
                    _hasShownWarningPrompt = false;
                    _hasShownCriticalPrompt = false;
                  } else if (waterLevelM >= 16.0 && waterLevelM < 18.0) {
                    _hasShownCriticalPrompt = false;
                  }
                  // -------------------------
                }
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      final forecast = await _weatherService.getCompleteWeather('Marikina');
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

  // ──────────────────────────────────────────────────────────────────────────
  // TAB NAVIGATION
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      children: [
        _buildMonitorTab(),
        _buildNotificationsTab(),
        _buildMessagingTab(),
        _buildProfileTab(),
      ],
    );
  }

  // ── TAB 1: MONITOR ────────────────────────────────────────────────────────

  Widget _buildMonitorTab() {
    final bool isCritical = waterLevelM >= 18.0;
    final bool isWarning = waterLevelM >= 15.0 && waterLevelM < 18.0;
    final bool isNormal = waterLevelM < 15.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Monitor'),
          const SizedBox(height: 24),
          _buildHeroWaterCard(waterLevelM, isCritical, isWarning, isNormal),
          const SizedBox(height: 24),
          // Quick Stats
          const Text('SYSTEM OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: textSecondary)),
          const SizedBox(height: 12),
          _buildQuickStatsRow(),
          const SizedBox(height: 24),
          // Threshold Legend
          const Text('THRESHOLD LEVELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: textSecondary)),
          const SizedBox(height: 12),
          _buildThresholdLegend(),
          const SizedBox(height: 24),
          // Weather
          const Text('SYSTEM WEATHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: textSecondary)),
          const SizedBox(height: 12),
          _buildWeatherSummaryStrip(),
          const SizedBox(height: 24),
          // Recent Activity
          const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: textSecondary)),
          const SizedBox(height: 12),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  // ── TAB 2: NOTIFICATIONS (Audit Logs) ────────────────────────────────────

  Widget _buildNotificationsTab() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: _buildHeader('Live Feed')),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('audit_logs').orderByChild('timestamp').limitToLast(50).onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: brandTeal));
              }
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return _buildEmptyState('No activity recorded.', Icons.history_rounded);
              }

              final Map<dynamic, dynamic> logs = snapshot.data!.snapshot.value as Map;
              final List<MapEntry<dynamic, dynamic>> sortedLogs = logs.entries.toList()
                ..sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

              // Filter for gate related actions if needed
              final filteredLogs = sortedLogs.where((entry) {
                final action = entry.value['action']?.toString().toLowerCase() ?? '';
                return action.contains('gate') || action.contains('flood');
              }).toList();

              if (filteredLogs.isEmpty) return _buildEmptyState('No gate activities found.', Icons.dns_rounded);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index].value as Map;
                  return _buildLogItem(log);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map log) {
    final String action = log['action'] ?? 'Unknown Action';
    final String desc = log['description'] ?? '';
    final int ts = log['timestamp'] ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: brandTeal.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: brandTeal, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
                const SizedBox(height: 6),
                Text('${dt.hour}:${dt.minute.toString().padLeft(2, '0')} • ${dt.month}/${dt.day}', style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: MESSAGING (Announcements) ─────────────────────────────────────

  Widget _buildMessagingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Broadcast'),
          const SizedBox(height: 24),
          const Text('NEW ANNOUNCEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Title', _announcementTitleController, Icons.title_rounded, 'Emergency Alert...'),
                const SizedBox(height: 20),
                _buildTextField('Message', _announcementDescController, Icons.subject_rounded, 'Please be advised that...', maxLines: 5),
                const SizedBox(height: 20),
                const Text('PRIORITY LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: ['info', 'warning', 'danger'].map((p) => _buildPriorityChip(p)).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _sendAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Send to Local Users', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildPriorityChip(String p) {
    final isSelected = _selectedPriority == p;
    final color = p == 'danger' ? dangerRed : (p == 'warning' ? warningOrange : brandTeal);
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(p.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : color)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              icon: Icon(icon, color: textSecondary, size: 20),
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _sendAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final desc = _announcementDescController.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      await _announcementsRef.add({
        'title': title,
        'message': desc, // Standardized key
        'type': _selectedPriority,
        'timestamp': FieldValue.serverTimestamp(),
        'gateId': _assignedGateId, // GATE SCOPING
        'sender': _username,
      });
      _announcementTitleController.clear();
      _announcementDescController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement broadcasted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _cleanupDatabase() async {
    try {
      final rootRef = FirebaseDatabase.instance.ref('flood_monitoring');
      
      // 1. Remove dangling root keys
      await rootRef.update({
        'floodgate_status': null,
        'last_updated': null,
        'sensor_warning': null,
        'water_level': null,
        'water_level_m': null,
      });

      // 2. Cleanup inside gate buckets
      final snapshot = await rootRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final gates = snapshot.value as Map;
        for (var gateId in gates.keys) {
          if (gateId.toString().startsWith('gate_')) {
            await rootRef.child(gateId).update({
              'sensor_warning': null,
              'water_level': null,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database cleanup successful! Optimized keys removed.'), backgroundColor: successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleanup failed: $e'), backgroundColor: dangerRed),
        );
      }
    }
  }

  // ── TAB 4: PROFILE ────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          _buildHeader('Settings'),
          const SizedBox(height: 32),
          const CircleAvatar(
            radius: 50,
            backgroundColor: brandTeal,
            child: Icon(Icons.admin_panel_settings_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(_username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 4),
          Text(_email, style: const TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          _buildProfileItem('Role', _role, Icons.security_rounded),
          _buildProfileItem('Station ID', _assignedGateId != null ? formatGateId(_assignedGateId!) : 'None Assigned', Icons.sensors_rounded),
          _buildProfileItem('Account Status', 'Active', Icons.verified_user_rounded, valueColor: successGreen),


          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded, color: dangerRed),
              label: const Text('Logout', style: TextStyle(color: dangerRed, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dangerRed.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Row(
        children: [
          Icon(icon, color: textSecondary, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor ?? textPrimary)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SHARED STYLES & HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: textSecondary)),
            const SizedBox(height: 4),
            const Text('HydroGate Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroWaterCard(double meters, bool isCritical, bool isWarning, bool isNormal) {
    final Color statusColor = isCritical ? dangerRed : (isWarning ? warningOrange : successGreen);
    final String statusLabel = isCritical ? 'CRITICAL' : (isWarning ? 'CAUTION' : 'NORMAL');
    final double progress = (meters / 25.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(statusLabel, statusColor),
              _buildBadge('Gate: ${isGateOpen ? "Open" : "Closed"}', isGateOpen ? successGreen : dangerRed),
            ],
          ),
          const SizedBox(height: 24),
          Text('${meters.toStringAsFixed(1)}m', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: textPrimary, height: 1.0, letterSpacing: -1.5)),
          const SizedBox(height: 8),
          const Text('Real-Time Water Level', style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          _buildModernGauge(progress, statusColor),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: _buildSmallInfo('Last Sync', lastUpdated)),
            Expanded(child: _buildSmallInfo('Assigned ID', formatGateId(_assignedGateId ?? 'N/A'))),
            Expanded(child: _buildSmallInfo('Timezone', 'Asia/Manila (PHT)')),
          ]),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)));
  }

  Widget _buildModernGauge(double progress, Color color) {
    return Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(6)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]))));
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          value, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textPrimary),
          softWrap: true,
        )
      ],
    );
  }

  Widget _buildWeatherSummaryStrip() {
    if (_isLoadingWeather) return const Center(child: CircularProgressIndicator(color: brandTeal));
    final w = _weatherForecast?.currentWeather;
    if (w == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [brandTeal, brandTealDark]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        Icon(WeatherUtils.getWeatherIcon(w.icon, w.main), color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${w.temperature.toStringAsFixed(0)}°C', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(WeatherUtils.capitalizeDescription(w.description), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        ]),
        const Spacer(),
        Text('${w.humidity}% Humid', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.security_rounded,
          label: 'Gate Status',
          value: isGateOpen ? 'OPEN' : 'CLOSED',
          color: isGateOpen ? successGreen : dangerRed,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.water_rounded,
          label: 'Water Level',
          value: '${waterLevelM.toStringAsFixed(1)}m',
          color: waterLevelM >= 18.0 ? dangerRed : (waterLevelM >= 15.0 ? warningOrange : successGreen),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.speed_rounded,
          label: 'Status',
          value: waterLevelM >= 18.0 ? 'CRITICAL' : (waterLevelM >= 15.0 ? 'WARNING' : 'NORMAL'),
          color: waterLevelM >= 18.0 ? dangerRed : (waterLevelM >= 15.0 ? warningOrange : successGreen),
        )),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildThresholdLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _buildLegendRow(successGreen, 'Safe', '0 – 14.9m', waterLevelM < 15.0),
          const SizedBox(height: 12),
          _buildLegendRow(warningOrange, 'Caution', '15.0 – 17.9m', waterLevelM >= 15.0 && waterLevelM < 18.0),
          const SizedBox(height: 12),
          _buildLegendRow(dangerRed, 'Critical', '18.0m+', waterLevelM >= 18.0),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String title, String range, bool isActive) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: isActive ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w800 : FontWeight.w500, color: isActive ? textPrimary : textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(range, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? color : textSecondary)),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('audit_logs').orderByChild('timestamp').limitToLast(5).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: brandTeal)));
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return _buildEmptyActivityCard();
        }

        final Map<dynamic, dynamic> logs = snapshot.data!.snapshot.value as Map;
        final List<MapEntry<dynamic, dynamic>> sortedLogs = logs.entries.toList()
          ..sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

        final gateLogs = sortedLogs.where((entry) {
          final action = entry.value['action']?.toString().toLowerCase() ?? '';
          return action.contains('gate') || action.contains('flood');
        }).take(4).toList();

        if (gateLogs.isEmpty) return _buildEmptyActivityCard();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: gateLogs.map((entry) {
              final log = entry.value as Map;
              final String desc = formatGateId(log['description'] ?? '');
              final int ts = log['timestamp'] ?? 0;
              final dt = DateTime.fromMillisecondsSinceEpoch(ts);
              final String action = log['action']?.toString() ?? '';
              final bool isClose = desc.toLowerCase().contains('closed');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isClose ? dangerRed : successGreen).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isClose ? Icons.lock_rounded : Icons.lock_open_rounded, color: isClose ? dangerRed : successGreen, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${dt.hour}:${dt.minute.toString().padLeft(2, '0')} • ${dt.month}/${dt.day}', style: const TextStyle(fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: const Center(
        child: Text('No recent gate activity', style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WATER LEVEL THRESHOLD MODAL
  // ──────────────────────────────────────────────────────────────────────────

  void _showLevelThresholdDialog({required bool isCritical, required String message}) {
    if (!mounted) return;

    final parentContext = context;
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isCritical ? dangerRed : warningOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isCritical ? 'CRITICAL LEVEL' : 'CAUTION LEVEL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isCritical ? dangerRed : textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, color: textSecondary, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Dismiss', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  try {
                    if (_floodRef != null) {
                      await _floodRef!.update({'floodgate_status': 'closed'});

                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Floodgate closed successfully.'),
                            backgroundColor: successGreen,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Firebase Update Error: $e');
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
                  backgroundColor: isCritical ? dangerRed : warningOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Close Gate', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 48, color: Colors.grey[200]), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: textSecondary, fontWeight: FontWeight.bold))]));
  }

  Widget _buildFloatingNavBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.sensors_outlined, Icons.sensors_rounded, 'Monitor'),
            _buildNavItem(1, Icons.history_edu_outlined, Icons.history_edu_rounded, 'Feed'),
            _buildNavItem(2, Icons.campaign_outlined, Icons.campaign_rounded, 'Broadcast'),
            _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? brandTeal : Colors.transparent, shape: BoxShape.circle), child: Icon(isSelected ? activeIcon : icon, color: isSelected ? Colors.white : textSecondary, size: 22)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? brandTeal : textSecondary))]),
    );
  }
}