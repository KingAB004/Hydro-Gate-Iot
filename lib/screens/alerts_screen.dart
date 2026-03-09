import 'package:flutter/material.dart';
import '../widgets/alerts_dropdown.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Color Palette
  static const Color deepSpaceBlue = Color(0xFF003249);
  static const Color cerulean = Color(0xFF007EA7);
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

  // Alert priority colors
  static const Color highPriorityBg = Color(0xFFFEE2E2);
  static const Color highPriorityTag = Color(0xFFEF4444);
  static const Color mediumPriorityBg = Color(0xFFFEF9C3);
  static const Color mediumPriorityTag = Color(0xFFEAB308);
  static const Color infoPriorityBg = Color(0xFFE0F2FE);
  static const Color infoPriorityTag = Color(0xFF3B82F6);
  static const Color lowPriorityBg = Color(0xFFDCFCE7);
  static const Color lowPriorityTag = Color(0xFF22C55E);

  final List<AlertItem> alerts = [
    AlertItem(
      title: "High Water Level Alert",
      body: "Water level reached 18.2m at Marikina River. Critical threshold exceeded. Automated systems active.",
      priority: AlertPriority.high,
      icon: "⚠",
      location: "Marikina River - Tumana",
      timestamp: DateTime.now(),
    ),
    AlertItem(
      title: "Rising Water Level",
      body: "Water level increasing at 0.3m/hour. Continue monitoring and move valuables to higher ground.",
      priority: AlertPriority.medium,
      icon: "⚠",
      location: "Pasig River - C5 Area",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AlertItem(
      title: "Weather Advisory",
      body: "Heavy rainfall expected in the next 6 hours. Monitor water levels closely for changes.",
      priority: AlertPriority.info,
      icon: "ⓘ",
      location: "PAGASA Weather Bureau",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AlertItem(
      title: "Water Level Stable",
      body: "Manggahan Floodway levels stable at 6.5m. Normal operations confirmed.",
      priority: AlertPriority.low,
      icon: "✓",
      location: "Manggahan Floodway",
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                  color: cerulean,
                  iconSize: 24,
                ),
                const Expanded(
                  child: Text(
                    'Alerts',
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
            const SizedBox(height: 8),
            const Text(
              'Recent notifications and warnings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            ...alerts.map((alert) => _buildAlertCard(alert)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final colors = _getPriorityColors(alert.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                alert.icon,
                style: TextStyle(fontSize: 22, color: colors['tag']),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors['tag'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert.priority.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(alert.timestamp),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.location,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getPriorityColors(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return {'bg': highPriorityBg, 'tag': highPriorityTag};
      case AlertPriority.medium:
        return {'bg': mediumPriorityBg, 'tag': mediumPriorityTag};
      case AlertPriority.info:
        return {'bg': infoPriorityBg, 'tag': infoPriorityTag};
      case AlertPriority.low:
        return {'bg': lowPriorityBg, 'tag': lowPriorityTag};
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

enum AlertPriority { high, medium, info, low }

class AlertItem {
  final String title;
  final String body;
  final AlertPriority priority;
  final String icon;
  final String location;
  final DateTime timestamp;

  AlertItem({
    required this.title,
    required this.body,
    required this.priority,
    required this.icon,
    required this.location,
    required this.timestamp,
  });
}
