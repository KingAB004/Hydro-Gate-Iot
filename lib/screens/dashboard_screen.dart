import 'package:flutter/material.dart';
import '../widgets/alerts_dropdown.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isGateOpen = true;

  
  static const Color deepSpaceBlue = Color(0xFF003249);
  static const Color cerulean = Color(0xFF007EA7);
  static const Color frostedBlueMedium = Color(0xFF80CED7);
  static const Color frostedBlueLight = Color(0xFF9AD1D4);
  static const Color ambientGrey = Color(0xFFCCDBDC);

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
      backgroundColor: ambientGrey,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: deepSpaceBlue,
                ),
              ),
              Text(
                range,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          ),
          const SizedBox(height: 20),
          Text(
            isGateOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isGateOpen ? 'Flow Active • Floodgate' : 'Flow Blocked • Floodgate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainfallCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: deepSpaceBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.water_drop,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rainfall',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '12',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: const Text(
                  'mm/hr',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Moderate Rain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF007EA7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ambientGrey,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: deepSpaceBlue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Isaac Day',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'q@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to profile screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile screen coming soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings screen coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    // Handle logout
                    Navigator.pop(context); // Go back to login
                  },
                  iconColor: Colors.red,
                  textColor: Colors.red,
                ),
              ],
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
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? deepSpaceBlue,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
    );
  }
}
