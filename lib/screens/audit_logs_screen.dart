import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  Color _severityColor(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'danger') {
      return dangerRed;
    }
    if (normalized == 'warning') {
      return warningOrange;
    }
    return successGreen;
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final logsStream = FirebaseDatabase.instance
      .ref('audit_logs')
      .orderByChild('timestamp')
      .limitToLast(200)
      .onValue;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 1,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: logsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load audit logs.'));
          }
          final raw = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          final entries = <Map<String, dynamic>>[];
          if (raw != null) {
            raw.forEach((key, value) {
              if (value is Map) {
                entries.add(Map<String, dynamic>.from(value));
              }
            });
            entries.sort((a, b) {
              final at = (a['timestamp'] as int?) ?? 0;
              final bt = (b['timestamp'] as int?) ?? 0;
              return bt.compareTo(at);
            });
          }
          if (entries.isEmpty) {
            return const Center(child: Text('No audit logs found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = entries[index];
              final action = (data['action'] ?? 'unknown').toString();
              final severity = (data['severity'] ?? 'safe').toString();
              final role = (data['role'] ?? 'Unknown').toString();
              final email = (data['email'] ?? 'Unknown').toString();
              final description = (data['description'] ?? '').toString();
              final timestamp = data['timestamp'] as int?;
              final timeText = _formatTimestamp(timestamp);
              final color = _severityColor(severity);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          action.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeText,
                          style: const TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      email,
                      style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(color: textPrimary, fontSize: 14, height: 1.3),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
