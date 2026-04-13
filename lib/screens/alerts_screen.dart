import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audit_log_service.dart';
import '../widgets/alerts_dropdown.dart';
import 'main_home_screen.dart';
import '../services/notification_state_service.dart';
import 'package:flutter/services.dart';


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

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedAlertIds = {};

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
      child: Stack(
        children: [
          SingleChildScrollView(
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
                _buildAnnouncementsList(isStandalone),
                const SizedBox(height: 100), // Extra space for FAB and Bottom Bar
              ],
            ),
          ),
          if (_isSelectionMode && _selectedAlertIds.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildBulkActionBar(),
            ),
        ],
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

  Widget _buildHeader(bool isStandalone, {List<String> allVisibleIds = const []}) {
    final bool isAllSelected = allVisibleIds.isNotEmpty && _selectedAlertIds.length == allVisibleIds.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isStandalone && !_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            if (!_isSelectionMode)
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
            if (_isSelectionMode)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedAlertIds.clear();
                  });
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
                  child: const Icon(Icons.close_rounded, color: dangerRed, size: 22),
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
                  _isSelectionMode ? '${_selectedAlertIds.length} Selected' : 'Recent Updates',
                  style: TextStyle(
                    fontSize: _isSelectionMode ? 20 : 22,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            if (!_isSelectionMode) ...[
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
              if (_role == 'Admin' || _role == 'LGU')
                const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.checklist_rtl_rounded, color: brandBlue, size: 24),
                ),
              ),
            ] else 
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isAllSelected) {
                      _selectedAlertIds.clear();
                      _isSelectionMode = false;
                    } else {
                      _selectedAlertIds.addAll(allVisibleIds);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAllSelected ? brandBlue : brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAllSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                        color: isAllSelected ? Colors.white : brandBlue, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList(bool isStandalone) {
    if (_isLoadingRole || _currentUserId == null) {
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
      builder: (context, userSnapshot) {
        List<String> hiddenAlerts = [];
        List<String> readAlerts = [];
        if (userSnapshot.hasData && userSnapshot.data?.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          hiddenAlerts = List<String>.from(userData['hiddenAlerts'] ?? []);
          readAlerts = List<String>.from(userData['readAlerts'] ?? []);
        }

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

            // Filter out hidden alerts
            var docs = snapshot.data!.docs.toList();
            docs = docs.where((doc) => !hiddenAlerts.contains(doc.id)).toList();

            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text('No new announcements', style: TextStyle(color: textSecondary, fontSize: 16)),
                    ],
                  ),
                ),
              );
            }

            // Sort client-side to avoid index requirements
        // Date Grouping Logic
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        Map<String, List<QueryDocumentSnapshot>> groupedDocs = {
          'Today': [],
          'Yesterday': [],
          'Earlier': [],
        };

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp == null) {
            groupedDocs['Earlier']!.add(doc);
            continue;
          }
          final date = timestamp.toDate();
          final compareDate = DateTime(date.year, date.month, date.day);

          if (compareDate == today) {
            groupedDocs['Today']!.add(doc);
          } else if (compareDate == yesterday) {
            groupedDocs['Yesterday']!.add(doc);
          } else {
            groupedDocs['Earlier']!.add(doc);
          }
        }

        return Column(
          children: [
            ...groupedDocs.entries.map((entry) {
              if (entry.value.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final doc = entry.value[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final String title = data['title'] ?? 'Announcement';
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

                      final bool isRead = readAlerts.contains(doc.id);
                      final bool isSelected = _selectedAlertIds.contains(doc.id);

                      return Dismissible(
                        key: ValueKey(doc.id),
                        direction: _isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
                        // Swipe Right -> Mark Read/Unread
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: brandBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: Icon(
                            isRead ? Icons.mark_chat_unread_rounded : Icons.mark_chat_read_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        // Swipe Left -> Dismiss (Hide)
                        secondaryBackground: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: dangerRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(
                            Icons.visibility_off_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          HapticFeedback.mediumImpact();
                          if (direction == DismissDirection.startToEnd) {
                            // Toggle Read Status
                            if (isRead) {
                              await NotificationStateService().markAsUnread(doc.id);
                            } else {
                              await NotificationStateService().markAsRead(doc.id);
                            }
                            return false; // Don't actually dismiss the card
                          }
                          return true; // Proceed with dismissal for Left Swipe
                        },
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await NotificationStateService().hideAlert(doc.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Alert dismissed'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                        child: GestureDetector(
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _isSelectionMode = true;
                              _selectedAlertIds.add(doc.id);
                            });
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedAlertIds.remove(doc.id);
                                  if (_selectedAlertIds.isEmpty) _isSelectionMode = false;
                                } else {
                                  _selectedAlertIds.add(doc.id);
                                }
                              });
                            } else if (!isRead) {
                              NotificationStateService().markAsRead(doc.id);
                            }
                          },
                          child: _buildAlertCard(
                            title: title,
                            body: message,
                            priority: priority,
                            icon: icon,
                            location: sender, 
                            timestamp: dt,
                            isRead: isRead,
                            isSelected: isSelected,
                            alertId: doc.id,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  },
);
}

Widget _buildBulkActionBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: textPrimary,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBulkActionItem(
          icon: Icons.mark_chat_read_rounded,
          label: 'Read',
          onTap: () async {
            await NotificationStateService().markAllAsRead(_selectedAlertIds.toList());
            setState(() {
              _isSelectionMode = false;
              _selectedAlertIds.clear();
            });
          },
        ),
        Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),
        _buildBulkActionItem(
          icon: Icons.visibility_off_rounded,
          label: 'Hide',
          onTap: () async {
            await NotificationStateService().dismissMultiple(_selectedAlertIds.toList());
            setState(() {
              _isSelectionMode = false;
              _selectedAlertIds.clear();
            });
          },
        ),
      ],
    ),
  );
}

Widget _buildBulkActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      onTap();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

  Widget _buildAlertCard({
    required String title,
    required String body,
    required AlertPriority priority,
    required IconData icon,
    required String location,
    required DateTime timestamp,
    required bool isRead,
    required bool isSelected,
    String? alertId,
  }) {
    final colors = _getPriorityTheme(priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? brandBlue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? brandBlue : colors['border']!, 
          width: isSelected ? 2.0 : 1.2
        ),
        boxShadow: [
          BoxShadow(
            color: isRead ? Colors.transparent : Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selection Indicator or Dot
              if (_isSelectionMode)
                Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? brandBlue.withOpacity(0.1) : Colors.transparent,
                    border: Border(right: BorderSide(color: Colors.black.withOpacity(0.05))),
                  ),
                  child: Center(
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? brandBlue : textSecondary.withOpacity(0.3),
                      size: 24,
                    ),
                  ),
                )
              else if (!isRead)
                Container(
                  width: 4,
                  color: brandBlue,
                ),
              
              Expanded(
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
                                  color: isRead ? colors['bg']!.withOpacity(0.5) : colors['bg'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon, 
                                  color: isRead ? colors['primary']!.withOpacity(0.5) : colors['primary'], 
                                  size: 20
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                              color: isRead ? textPrimary.withOpacity(0.6) : textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (!isRead && !_isSelectionMode)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: brandBlue,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(color: brandBlue, blurRadius: 4),
                                              ],
                                            ),
                                          ),
                                      ],
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
                              if (!_isSelectionMode)
                                _buildCardPopupMenu(alertId, isRead),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF475569).withOpacity(isRead ? 0.7 : 1.0),
                                height: 1.5,
                                fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors['bg']!.withOpacity(isRead ? 0.15 : 0.3),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              priority.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: colors['primary'],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPopupMenu(String? alertId, bool isRead) {
    if (alertId == null) return const SizedBox.shrink();
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
      onSelected: (value) async {
        HapticFeedback.lightImpact();
        if (value == 'toggle_read') {
          if (isRead) {
            await NotificationStateService().markAsUnread(alertId);
          } else {
            await NotificationStateService().markAsRead(alertId);
          }
        } else if (value == 'dismiss') {
          await NotificationStateService().hideAlert(alertId);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle_read',
          child: Row(
            children: [
              Icon(isRead ? Icons.mark_chat_unread_rounded : Icons.mark_chat_read_rounded, size: 18, color: brandBlue),
              const SizedBox(width: 12),
              Text(isRead ? 'Mark as Unread' : 'Mark as Read'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'dismiss',
          child: Row(
            children: [
              Icon(Icons.visibility_off_rounded, size: 18, color: dangerRed),
              const SizedBox(width: 12),
              Text('Dismiss Alert'),
            ],
          ),
        ),
      ],
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