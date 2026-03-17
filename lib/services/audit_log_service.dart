import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _auditRef = FirebaseDatabase.instance.ref('audit_logs');

  Future<void> logEvent({
    required String action,
    required String severity,
    String? description,
    String? email,
    String? role,
    String? targetRole,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final resolvedEmail = email ?? user?.email ?? 'Unknown';
    final resolvedRole = role ?? await _getRole(user?.uid) ?? 'Unknown';

    await _auditRef.push().set({
      'action': action,
      'severity': severity,
      'description': description ?? '',
      'email': resolvedEmail,
      'role': resolvedRole,
      'userId': user?.uid ?? '',
      'targetRole': targetRole ?? '',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<String?> _getRole(String? uid) async {
    if (uid == null || uid.isEmpty) {
      return null;
    }
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final role = data['role'];
    return role is String ? role : null;
  }
}
