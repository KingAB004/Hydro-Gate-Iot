import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audit_log_service.dart';
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
  
  static const Color brandBlue = Color(0xFF007EAA);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);

  int _refreshKey = 0; // Key to force refresh stream
  String _role = 'Homeowner';
  String _username = 'User';
  String? _currentUserId;
  bool _isLoadingRole = true;
  String? _assignedGateId;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _role = doc.data()?['role'] ?? 'Homeowner';
          _username = doc.data()?['username'] ?? 'User';
          _assignedGateId = doc.data()?['assigned_gate_id'];
          _isLoadingRole = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingRole = false);
      }
    }
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

      try {
        await AuditLogService().logEvent(
          action: 'alerts_delete_all',
          severity: 'danger',
          description: 'All alerts deleted',
        );
      } catch (e) {
        debugPrint('Audit log write failed: $e');
      }

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
    final bool isStandalone = ModalRoute.of(context)?.canPop ?? false;

    final Widget body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isStandalone),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );

    if (isStandalone) {
      return Scaffold(
        backgroundColor: bgLight,
        body: body,
      );
    }

    return Material(
      color: bgLight,
      child: body,
    );
  }

  Widget _buildHeader(bool isStandalone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isStandalone)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  if (!isStandalone) {
                    Scaffold.of(context).openDrawer();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(isStandalone ? Icons.notifications_active_rounded : Icons.menu_rounded, color: isStandalone ? brandBlue : textPrimary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Recent Updates',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_role == 'Admin' || _role == 'LGU')
          GestureDetector(
            onTap: _deleteAllAlerts,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: dangerRed, size: 24),
            ),
          ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    if (_isLoadingRole) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40.0),
          child: CircularProgressIndicator(color: brandBlue),
        ),
      );
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('announcements');

    // Filter by gateId
    query = query.where('gateId', isEqualTo: _assignedGateId);

    return StreamBuilder<QuerySnapshot>(
      key: ValueKey(_refreshKey),
      stream: query.snapshots(),
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
          debugPrint('Firestore Error: ${snapshot.error}');
          return const Center(child: Text('Error loading announcements'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text('No announcements yet', style: TextStyle(color: textSecondary, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        // Sort client-side to avoid index requirements
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
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // Map Firestore data to an internally usable object concept
            final String title = data['title'] ?? 'Announcement';
            // Fallback to 'description' if 'message' is missing (for backward compatibility)
            final String message = formatGateId(data['message'] ?? data['description'] ?? '');
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
                try {
                  await AuditLogService().logEvent(
                    action: 'alert_deleted',
                    severity: 'warning',
                    description: 'Alert deleted: $title',
                  );
                } catch (e) {
                  debugPrint('Audit log write failed: $e');
                }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors['border']!, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors['bg'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: colors['primary'], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors['bg'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: colors['primary'],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors['bg']!.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  _getTimeAgo(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: colors['primary']!.withOpacity(0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getPriorityTheme(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.high:
        return {
          'primary': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFEE2E2),
          'shadow': const Color(0xFFEF4444).withOpacity(0.04),
        };
      case AlertPriority.medium:
        return {
          'primary': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFFFBEB),
          'border': const Color(0xFFFEF3C7),
          'shadow': const Color(0xFFF59E0B).withOpacity(0.04),
        };
      case AlertPriority.info:
        return {
          'primary': const Color(0xFF007EAA),
          'bg': const Color(0xFFF0F9FF),
          'border': const Color(0xFFE0F2FE),
          'shadow': const Color(0xFF007EAA).withOpacity(0.04),
        };
      case AlertPriority.low:
        return {
          'primary': const Color(0xFF10B981),
          'bg': const Color(0xFFF0FDF4),
          'border': const Color(0xFFDCFCE7),
          'shadow': const Color(0xFF10B981).withOpacity(0.02),
        };
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