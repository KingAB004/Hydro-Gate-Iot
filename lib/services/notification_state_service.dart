import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationStateService {
  static final NotificationStateService _instance = NotificationStateService._internal();

  factory NotificationStateService() {
    return _instance;
  }

  NotificationStateService._internal();

  Future<void> hideAlert(String alertId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'hiddenAlerts': FieldValue.arrayUnion([alertId]),
      });
    } catch (e) {
      debugPrint('Error hiding alert: $e');
    }
  }

  Future<void> markAsRead(String alertId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'readAlerts': FieldValue.arrayUnion([alertId]),
      });
    } catch (e) {
      debugPrint('Error marking alert as read: $e');
    }
  }

  Future<void> markAsUnread(String alertId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'readAlerts': FieldValue.arrayRemove([alertId]),
      });
    } catch (e) {
      debugPrint('Error marking alert as unread: $e');
    }
  }

  Future<void> markAllAsRead(List<String> alertIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || alertIds.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'readAlerts': FieldValue.arrayUnion(alertIds),
      });
    } catch (e) {
      debugPrint('Error marking all alerts as read: $e');
    }
  }

  Future<void> dismissMultiple(List<String> alertIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || alertIds.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'hiddenAlerts': FieldValue.arrayUnion(alertIds),
      });
    } catch (e) {
      debugPrint('Error dismissing multiple alerts: $e');
    }
  }
}
