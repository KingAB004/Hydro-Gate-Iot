import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/alerts_screen.dart';
import '../utils/notifications.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

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
                    Navigator.pop(context, 'switch_tab_0');
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
          // Alerts List via Stream
          Flexible(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String? assignedGateId = userData?['assigned_gate_id'];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('announcements')
                      .where('gateId', isEqualTo: assignedGateId) // FILTER BY GATE ID
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Sort client-side to avoid index requirement
                    final docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime); // Descending
                    });

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final String title = data['title'] ?? 'Announcement';
                        final String rawType = data['type'] ?? 'info';
                        final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                        final DateTime dt = timestamp?.toDate() ?? DateTime.now();

                        AlertPriority priority = AlertPriority.info;
                        if (rawType.toLowerCase() == 'emergency' || rawType.toLowerCase() == 'danger') {
                          priority = AlertPriority.high;
                        } else if (rawType.toLowerCase() == 'alert' || rawType.toLowerCase() == 'warning') {
                          priority = AlertPriority.medium;
                        } else if (rawType.toLowerCase() == 'low' || rawType.toLowerCase() == 'success') {
                          priority = AlertPriority.low;
                        }

                        return _buildAlertItem(context, title, priority, dt);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, String title, AlertPriority priority, DateTime timestamp) {
    final Color priorityColor = _getPriorityColor(priority);

    return InkWell(
      onTap: () {
        Navigator.pop(context, 'switch_tab_0');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.05), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                priority == AlertPriority.high ? Icons.warning_rounded : Icons.notifications_rounded,
                size: 16,
                color: priorityColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.grey.shade300,
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
        return const Color(0xFFEF4444);
      case AlertPriority.medium:
        return const Color(0xFFF59E0B);
      case AlertPriority.info:
        return const Color(0xFF007EAA);
      case AlertPriority.low:
        return const Color(0xFF10B981);
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
