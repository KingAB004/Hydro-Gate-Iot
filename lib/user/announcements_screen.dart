import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen to display all announcements from LGU and private activity logs
/// Shows real-time updates from Firestore
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _role = 'Homeowner';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _role = doc.data()?['role'] ?? 'Homeowner';
          _initialized = true;
        });
      } else if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    // Build the query based on role
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('announcements');

    if (_role == 'Admin') {
      // Admins see everything (global alerts + all gate logs)
      query = query.orderBy('timestamp', descending: true);
    } else {
      // Regular users see global alerts + their own gate logs
      if (user != null) {
        // Fetch where userId is either 'global' or the current user's UID.
        query = query.where('userId', whereIn: ['global', user.uid])
                     .orderBy('timestamp', descending: true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_role == 'Admin' ? 'System Logs & Alerts' : 'Announcements'),
        backgroundColor: const Color(0xFF2c80ff),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.limit(50).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final String type = data['type'] ?? 'info';
              final String message = data['message'] ?? '';
              final Timestamp? timestamp = data['timestamp'];
              final String sender = data['sender'] ?? 'LGU';

              return AnnouncementCard(
                type: type,
                message: message,
                timestamp: timestamp,
                sender: sender,
              );
            },
          );
        },
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final String type;
  final String message;
  final Timestamp? timestamp;
  final String sender;

  const AnnouncementCard({
    Key? key,
    required this.type,
    required this.message,
    this.timestamp,
    required this.sender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeConfig = _getTypeConfig(type);
    final String timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: typeConfig['color'] as Color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type badge and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (typeConfig['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        typeConfig['icon'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeConfig['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: typeConfig['color'] as Color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Sender
            Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'gate_log':
        return {
          'label': 'GATE ACTION',
          'icon': '⚙️',
          'color': const Color(0xFF6366F1), // Indigo
        };
      case 'danger':
        return {
          'label': 'EMERGENCY',
          'icon': '🚨',
          'color': const Color(0xFFEF4444),
        };
      case 'warning':
        return {
          'label': 'WARNING',
          'icon': '⚠️',
          'color': const Color(0xFFF59E0B),
        };
      case 'info':
      default:
        return {
          'label': 'INFO',
          'icon': 'ℹ️',
          'color': const Color(0xFF3B82F6),
        };
    }
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
