import 'package:flutter/material.dart';
import '../screens/alerts_screen.dart';

class AlertsDropdown extends StatelessWidget {
  const AlertsDropdown({super.key});

  // Color Palette
  static const Color deepSpaceBlue = Color(0xFF003249);
  static const Color cerulean = Color(0xFF007EA7);
  static const Color ambientGrey = Color(0xFFCCDBDC);

  // Alert priority colors
  static const Color highPriorityTag = Color(0xFFEF4444);
  static const Color mediumPriorityTag = Color(0xFFEAB308);
  static const Color infoPriorityTag = Color(0xFF3B82F6);
  static const Color lowPriorityTag = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final List<AlertItem> recentAlerts = [
      AlertItem(
        title: "High Water Level Alert",
        body: "",
        priority: AlertPriority.high,
        icon: "⚠",
        location: "Marikina River",
        timestamp: DateTime.now(),
      ),
      AlertItem(
        title: "Rising Water Level",
        body: "",
        priority: AlertPriority.medium,
        icon: "⚠",
        location: "Pasig River",
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AlertItem(
        title: "Weather Advisory",
        body: "",
        priority: AlertPriority.info,
        icon: "ⓘ",
        location: "PAGASA",
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: deepSpaceBlue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AlertsScreen()),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cerulean,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alerts List
          Flexible(
            child: recentAlerts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: recentAlerts.length,
                    itemBuilder: (context, index) {
                      return _buildAlertItem(context, recentAlerts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertItem alert) {
    final tagColor = _getPriorityColor(alert.priority);

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tagColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(alert.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return highPriorityTag;
      case AlertPriority.medium:
        return mediumPriorityTag;
      case AlertPriority.info:
        return infoPriorityTag;
      case AlertPriority.low:
        return lowPriorityTag;
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
