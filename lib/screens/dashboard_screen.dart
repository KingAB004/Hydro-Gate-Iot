import 'package:flutter/material.dart';
import '../widgets/alerts_dropdown.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
  bool isGateOpen = true;
<<<<<<< Updated upstream
=======
  double waterHeightCm = 1500; // Default 15m
  String waterLevelStatus = 'Normal';
  String lastUpdated = '';
 
  // Realtime Database reference
  final DatabaseReference _floodRef = FirebaseDatabase.instance.ref('flood_monitoring');
>>>>>>> Stashed changes


  // Modern Minimal Color Palette
  static const Color bgColor = Color(0xFFF8F9FA); // Minimal light gray background
  static const Color cardColor = Colors.white;
  static const Color primaryBlue = Color(0xFF2563EB); // Modern vibrant blue
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color accentLightBlue = Color(0xFFDBEAFE); // Blue 100
 
  // Status Colors
  static const Color statusCritical = Color(0xFFEF4444); // Red 500
  static const Color statusWarning = Color(0xFFF59E0B); // Amber 500
  static const Color statusNormal = Color(0xFF10B981); // Emerald 500


<<<<<<< Updated upstream
=======
  String _username = 'Loading...';
  String _email = 'Loading...';


  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (mounted) {
            setState(() {
              _username = data['username'] ?? _username;
            });
          }
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
   
    // Listen to flood monitoring data
    _floodRef.onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          isGateOpen = data['floodgate_status'] != 'closed';
          waterHeightCm = (data['water_height_cm'] ?? 0).toDouble();
          waterLevelStatus = data['water_level']?.toString() ?? 'Normal';
          lastUpdated = data['last_updated']?.toString() ?? '';
        });
      }
    });
  }


>>>>>>> Stashed changes
  void _showNotificationsDropdown() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 70,
            right: 24,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
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
      backgroundColor: bgColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
<<<<<<< Updated upstream
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      color: cerulean,
                      iconSize: 28,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Dashboard',
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
              _buildWaterLevelMonitor(),
              const SizedBox(height: 16),
              _buildFloodgateControl(),
              const SizedBox(height: 16),
              _buildRainfallCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterLevelMonitor() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Level',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '16m',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: deepSpaceBlue,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 20),
              _buildGauge(),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(const Color(0xFFD32F2F), 'Critical', '18m+'),
                    const SizedBox(height: 12),
                    _buildLegendItem(const Color(0xFFF57C00), '2nd Alarm', '16-18m'),
                    const SizedBox(height: 12),
                    _buildLegendItem(frostedBlueLight, '1st Alarm', '15-16m'),
                    const SizedBox(height: 12),
                    _buildLegendItem(cerulean, 'Normal', '<15m'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Second alarm threshold reached',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    return Container(
      width: 60,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          // Background sections (for visual reference)
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(color: const Color(0xFFF57C00)),
              ),
              Expanded(
                flex: 1,
                child: Container(color: frostedBlueLight),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
          // Current water level overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120, // Adjust based on current level (16m = 2nd alarm)
            child: Container(
              decoration: BoxDecoration(
                color: cerulean,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String range) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
=======
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
>>>>>>> Stashed changes
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildGreeting(),
              const SizedBox(height: 32),
              _buildWaterLevelMonitor(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFloodgateControl()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRainfallCard()),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Builder(
          builder: (context) => InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _subtleShadow(),
              ),
              child: const Icon(Icons.menu, color: textMain, size: 24),
            ),
          ),
        ),
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textMain,
            letterSpacing: -0.5,
          ),
        ),
        InkWell(
          onTap: _showNotificationsDropdown,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _subtleShadow(),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: textMain, size: 24),
          ),
        ),
      ],
    );
  }

<<<<<<< Updated upstream
  Widget _buildFloodgateControl() {
    final Color ringColor = isGateOpen ? cerulean : const Color(0xFFEF5350);
    final Color fillColor = isGateOpen ? frostedBlueMedium : const Color(0xFFEF5350);
    final Color textColor = isGateOpen ? cerulean : const Color(0xFFEF5350);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (isGateOpen) {
                // Show confirmation dialog when closing the gate
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: const Color(0xFFF57C00), size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Close Floodgate?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Are you sure you want to close the floodgate? This will stop water flow.',
                        style: TextStyle(fontSize: 15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              isGateOpen = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF5350),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Close Gate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Show confirmation dialog when opening the gate
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.info_outline, color: cerulean, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Open Floodgate?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Are you sure you want to open the floodgate? This will allow water flow.',
                        style: TextStyle(fontSize: 15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              isGateOpen = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cerulean,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Open Gate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: 8,
                ),
                color: Colors.grey.shade200,
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                ),
                child: Center(
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
=======

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $_username',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textMain,
            letterSpacing: -0.5,
>>>>>>> Stashed changes
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here is your flood monitoring update.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
        ),
      ],
    );
  }


  Widget _buildWaterLevelMonitor() {
    final double waterLevelM = waterHeightCm / 100;
   
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _subtleShadow(),
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
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(waterLevelStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(waterLevelStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      waterLevelStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(waterLevelStatus),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                waterLevelM.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'meters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildModernGauge(waterLevelM),
        ],
      ),
    );
  }


  Widget _buildModernGauge(double waterLevelM) {
    // Max level around 20m for visualization
    const double maxLevel = 20.0;
    final double fillPercentage = (waterLevelM / maxLevel).clamp(0.0, 1.0);
   
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fillPercentage,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.6),
                      primaryBlue,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildGaugeLabel('Safe', '<15m', statusNormal),
            _buildGaugeLabel('Alert', '15-18m', statusWarning),
            _buildGaugeLabel('Critical', '>18m', statusCritical),
          ],
        )
      ],
    );
  }


  Widget _buildGaugeLabel(String title, String range, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            Text(
              range,
              style: const TextStyle(
                fontSize: 11,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildFloodgateControl() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      // Make heights match rainfall card
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _subtleShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGateOpen ? accentLightBlue : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sensor_door_outlined,
              color: isGateOpen ? primaryBlue : statusCritical,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Floodgate',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isGateOpen ? 'Open' : 'Closed',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggleFloodgate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isGateOpen ? primaryBlue : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isGateOpen ? null : Border.all(color: Colors.red.shade200, width: 2),
                boxShadow: isGateOpen
                  ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
              ),
              child: Center(
                child: Text(
                  isGateOpen ? 'Close Gate' : 'Open Gate',
                  style: TextStyle(
                    color: isGateOpen ? Colors.white : statusCritical,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _toggleFloodgate() {
    final bool willOpen = !isGateOpen;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            willOpen ? 'Open Floodgate' : 'Close Floodgate',
            style: const TextStyle(fontWeight: FontWeight.bold, color: textMain),
          ),
          content: Text(
            willOpen
                ? 'Are you sure you want to open the floodgate? Water will flow.'
                : 'Are you sure you want to close the floodgate? Water flow will stop.',
            style: const TextStyle(color: textMuted, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _floodRef.update({'floodgate_status': willOpen ? 'open' : 'closed'});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: willOpen ? primaryBlue : statusCritical,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildRainfallCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Blue 600 to 700
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rainfall',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '12 mm/h',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Moderate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('critical')) return statusCritical;
    if (status.toLowerCase().contains('alarm')) return statusWarning;
    return statusNormal;
  }


  List<BoxShadow> _subtleShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }


  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 80, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentLightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ),
<<<<<<< Updated upstream
                const SizedBox(height: 16),
                const Text(
                  'Isaac Day',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
=======
                const SizedBox(height: 20),
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textMain,
>>>>>>> Stashed changes
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'q@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: bgColor),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile screen coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings screen coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: statusCritical,
              textColor: statusCritical,
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to login
              },
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
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentLightBlue.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isSelected ? primaryBlue : textMuted),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor ?? (isSelected ? primaryBlue : textMain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





