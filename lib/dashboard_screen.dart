import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isGateOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9EE), // Very light yellow/orange tint
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWaterLevelMonitor(),
            const SizedBox(height: 16),
            _buildFloodgateControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLevelMonitor() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A7AF0), // Blue circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water Level Monitor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '15.2m',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Gauge
              _buildGauge(),
              const SizedBox(width: 32),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(const Color(0xFFE53935), 'Critical', '18m+ (3rd)'),
                  const SizedBox(height: 16),
                  _buildLegendItem(const Color(0xFFFF8A00), '2nd Alarm', '16-18m'),
                  const SizedBox(height: 16),
                  _buildLegendItem(const Color(0xFFFFC107), '1st Alarm', '15-16m'),
                  const SizedBox(height: 16),
                  _buildLegendItem(const Color(0xFF4CAF50), 'Normal', '<15m'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    return Stack(
      children: [
        // Base structure
        Container(
          width: 100,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              // Critical Section
              Expanded(
                flex: 4, // Represents size based on scale
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF44336), // Red
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8),
                  child: const Text('CRITICAL', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              // 2nd Alarm Section
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFFFF8F00), // Orange
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8),
                  child: const Text('2ND', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              // 1st Alarm Section
              Expanded(
                flex: 3,
                child: Container(
                  color: const Color(0xFFFFC107), // Yellow
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8),
                  child: const Text('1ST', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              // Normal Section placeholder
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Actual Water Fill Layer (Overlaying everything)
        // Positioned at the bottom, growing upwards
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 140, // Currently filling up to normal/1st alarm level
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)), // Curve bottom
            ),
            child: Stack(
              children: [
                // Highlight at top of water
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                // Tiny overlapping indicators (arrows)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(Icons.arrow_left, color: Colors.blue[800], size: 20),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.arrow_right, color: Colors.blue[800], size: 20),
                ),
                // Bubbles (optional simple circles)
                Positioned(top: 20, left: 20, child: _bubble()),
                Positioned(top: 60, right: 20, child: _bubble()),
                Positioned(bottom: 30, left: 30, child: _bubble()),
              ],
            ),
          ),
        ),
        // Base plate
        Positioned(
          bottom: -5,
          left: -10,
          right: -10,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF455A64), // Dark grey base
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String range) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              range,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloodgateControl() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white, // Also looks like it's inside a slightly colored container in the image, but we'll use white
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6D00), // Orange circle
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Floodgate Control',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        isGateOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isGateOpen ? const Color(0xFFD84315) : const Color(0xFF4CAF50), // Red-orange if open, green if closed
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isGateOpen,
                activeColor: const Color(0xFF2A7AF0), // Light blue toggle when on
                inactiveTrackColor: Colors.grey[300],
                onChanged: (value) {
                  setState(() {
                    isGateOpen = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Flow visualization
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // Inner white box
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // The blue stream representation
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)], // Light blue to darker blue
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Dark grey gate columns on the sides
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF37474F), // Dark grey
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF37474F), // Dark grey
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                          ),
                        ),
                      ),
                      // If gate is closed, draw a gate block coming down
                      if (!isGateOpen)
                        Positioned(
                          top: 0,
                          left: 20,
                          right: 20,
                          bottom: 0,
                          child: Container(
                            color: const Color(0xFF607D8B), // Grey gate
                            child: const Center(
                              child: Text(
                                'CLOSED',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      // Button overlaid on stream
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: isGateOpen ? const Color(0xFF1976D2) : const Color(0xFFD84315),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                isGateOpen = !isGateOpen;
                              });
                            },
                            child: Text(isGateOpen ? 'OPEN FLOW' : 'CLOSE FLOW', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Gate position text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6D00), // Orange dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isGateOpen ? 'Gate Position: OPEN (100%)' : 'Gate Position: CLOSED (0%)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const Icon(Icons.notifications_none_outlined, color: Color(0xFFFF6D00), size: 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your home floodgate is open. Close it when flood risk increases.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
