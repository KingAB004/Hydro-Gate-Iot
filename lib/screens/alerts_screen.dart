import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/alerts_dropdown.dart';
import 'main_home_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Modern Color Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  
  static const Color brandBlue = Color(0xFF0EA5E9);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);

  int _refreshKey = 0; // Key to force refresh stream

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

  void _refreshAlerts() {
    setState(() {
      _refreshKey++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking for new alerts...'),
        duration: Duration(seconds: 1),
        backgroundColor: brandBlue,
      ),
    );
  }

  Future<void> _deleteAllAlerts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete all alerts?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning_amber_rounded, color: dangerRed),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This will permanently remove all alerts. You cannot undo this action.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Proceed',
                style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final query = await FirebaseFirestore.instance.collection('announcements').get();
      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No alerts to delete'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All alerts deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete alerts'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              const Text(
                'Recent announcements and warnings',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildAnnouncementsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                final MainHomeScreenState? mainScreen = context.findAncestorStateOfType<MainHomeScreenState>();
                if (mainScreen != null) {
                  mainScreen.navigateToHome();
                }
              }
            },
            color: textPrimary,
            iconSize: 20,
          ),
        ),
        const Expanded(
          child: Text(
            'Alerts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshAlerts,
            color: textPrimary,
            iconSize: 24,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _deleteAllAlerts,
            color: dangerRed,
            iconSize: 24,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: _showNotificationsDropdown,
            color: textPrimary,
            iconSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey(_refreshKey),
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: CircularProgressIndicator(color: brandBlue),
            )
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading announcements'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: textSecondary),
                  SizedBox(height: 16),
                  Text('No announcements yet', style: TextStyle(color: textSecondary, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // Map Firestore data to an internally usable object concept
            final String title = data['title'] ?? 'Announcement';
            final String message = data['message'] ?? '';
            final String rawType = data['type'] ?? 'info';
            final Timestamp? timestamp = data['timestamp'] as Timestamp?;
            final DateTime dt = timestamp?.toDate() ?? DateTime.now();
            final String sender = data['sender'] ?? 'Admin';

            AlertPriority priority = AlertPriority.info;
            IconData icon = Icons.info_outline_rounded;
            
            if (rawType.toLowerCase() == 'emergency' || rawType.toLowerCase() == 'danger') {
              priority = AlertPriority.high;
              icon = Icons.warning_rounded;
            } else if (rawType.toLowerCase() == 'alert' || rawType.toLowerCase() == 'warning') {
              priority = AlertPriority.medium;
              icon = Icons.waves_rounded;
            } else if (rawType.toLowerCase() == 'low' || rawType.toLowerCase() == 'success') {
              priority = AlertPriority.low;
              icon = Icons.verified_rounded;
            } else {
              priority = AlertPriority.info;
              icon = Icons.campaign_rounded;
            }

            return Dismissible(
              key: ValueKey(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: dangerRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete alert?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                ) ?? false;
              },
              onDismissed: (_) async {
                await doc.reference.delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert deleted'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: _buildAlertCard(
                title: title,
                body: message,
                priority: priority,
                icon: icon,
                location: sender, 
                timestamp: dt,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String body,
    required AlertPriority priority,
    required IconData icon,
    required String location,
    required DateTime timestamp,
  }) {
    final colors = _getPriorityTheme(priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors['shadow']!,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colors['border']!, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color indicator
              Container(
                width: 6,
                color: colors['primary'],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: colors['primary'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colors['bg'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        priority.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: colors['primary'],
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _getTimeAgo(timestamp),
                              style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: textSecondary)),
                            const SizedBox(width: 12),
                            const Icon(Icons.person_pin, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getPriorityTheme(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return {
          'primary': dangerRed,
          'bg': dangerRed.withOpacity(0.1),
          'border': dangerRed.withOpacity(0.2),
          'shadow': dangerRed.withOpacity(0.05),
        };
      case AlertPriority.medium:
        return {
          'primary': warningOrange,
          'bg': warningOrange.withOpacity(0.1),
          'border': warningOrange.withOpacity(0.2),
          'shadow': warningOrange.withOpacity(0.05),
        };
      case AlertPriority.info:
        return {
          'primary': infoBlue,
          'bg': infoBlue.withOpacity(0.1),
          'border': infoBlue.withOpacity(0.2),
          'shadow': infoBlue.withOpacity(0.05),
        };
      case AlertPriority.low:
        return {
          'primary': successGreen,
          'bg': successGreen.withOpacity(0.1),
          'border': successGreen.withOpacity(0.2),
          'shadow': successGreen.withOpacity(0.02),
        };
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '\m ago';
    } else if (difference.inHours < 24) {
      return '\h ago';
    } else {
      return '\d ago';
    }
  }
}

enum AlertPriority { high, medium, info, low }