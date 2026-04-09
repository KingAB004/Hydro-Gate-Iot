import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firestore Listener Service - Monitors announcements in real-time
/// Shows local notifications when LGU creates new announcements
class AnnouncementListenerService {
  static final AnnouncementListenerService _instance = AnnouncementListenerService._internal();
  factory AnnouncementListenerService() => _instance;
  AnnouncementListenerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _announcementSubscription;
  String? _lastAnnouncementId;
  bool _isInitialized = false;
  String _role = 'Homeowner';
  String? _currentUserId;

  /// Initialize the listener service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get current user and role
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _role = doc.data()?['role'] ?? 'Homeowner';
      }
    }

    // Get the latest announcement ID to avoid showing old announcements on app start
    await _getLatestAnnouncementId();

    // Start listening for new announcements
    _startListening();

    _isInitialized = true;
    print('Announcement Listener Service initialized with role: $_role');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Get the ID of the latest announcement to use as baseline
  Future<void> _getLatestAnnouncementId() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastAnnouncementId = snapshot.docs.first.id;
        print('Baseline announcement ID set');
      }
    } catch (e) {
      print('Error getting baseline announcement: $e');
    }
  }

  /// Start listening to Firestore for new announcements
  void _startListening() {
    if (_currentUserId == null) return;

    // We'll use a simple listener and filter in Dart to avoid Filter.or version issues
    _announcementSubscription = _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.docs.isEmpty) return;

            final doc = snapshot.docs.first;
            final data = doc.data() as Map<String, dynamic>;
            
            // ROLE-BASED FILTERING (IN DART)
            final String? docUserId = data['userId'];
            final String docType = data['type'] ?? 'info';

            // Filter out if it's not meant for the current user
            bool isMeantForMe = false;
            if (_role == 'Admin') {
              // Admin sees everything global + all gate logs
              if (docUserId == 'global' || docType == 'gate_log' || docUserId == null) {
                isMeantForMe = true;
              }
            } else {
              // Regular user sees global + their own logs
              if (docUserId == 'global' || docUserId == _currentUserId || docUserId == null) {
                isMeantForMe = true;
              }
            }

            if (!isMeantForMe) return;

            final announcementId = doc.id;

            // Skip if this is the same as the last announcement we've seen
            if (_lastAnnouncementId == null) {
              _lastAnnouncementId = announcementId;
              return; // First load, don't show notification
            }

            if (announcementId == _lastAnnouncementId) {
              return; // Same announcement, skip
            }

            // New announcement detected!
            _lastAnnouncementId = announcementId;

            // 1. Check if the user has push notifications enabled in Firestore
            bool hasNotificationsEnabled = await _checkIfPushNotificationsEnabled();
            if (!hasNotificationsEnabled) {
               print('Notifications are disabled by user, skipping local notification.');
               return; 
            }

            // Get announcement data
            final data = doc.data() as Map<String, dynamic>;
            final String type = data['type'] ?? 'info';
            final String message = data['message'] ?? '';
            final String sender = data['sender'] ?? 'LGU';
            final String title = data['title'] ?? 'New Notification';

            // Show local notification
            _showLocalNotification(type, message, sender, announcementId, title);
          },
          onError: (error) {
            print('Error listening to announcements: $error');
          },
        );
  }

  /// Check User Preferences for Notifications
  Future<bool> _checkIfPushNotificationsEnabled() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        // Return whatever is set for pushNotificationsEnabled. Default is false if it doesn't exist
        return doc.data()?['pushNotificationsEnabled'] ?? false;
      }
      return false; // Document doesn't exist, assume false
    } catch (e) {
      print('Error reading user preference');
      return false; // Error reading, assume false
    }
  }

  /// Show local notification for new announcement
  Future<void> _showLocalNotification(
    String type,
    String message,
    String sender,
    String announcementId,
    String title
  ) async {
    print('Showing notification: $title - $message');

    final config = _getNotificationConfig(type, title);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      config['channelId'] as String,
      config['channelName'] as String,
      channelDescription: 'LGU announcements and alerts',
      importance: config['importance'] as Importance,
      priority: config['priority'] as Priority,
      color: config['color'] as Color,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: config['title'] as String,
        summaryText: sender,
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      announcementId.hashCode, // Unique ID based on announcement
      config['title'] as String,
      message,
      details,
      payload: announcementId,
    );

    print('Notification shown successfully');
  }

  /// Get notification configuration based on type
  Map<String, dynamic> _getNotificationConfig(String type, String title) {
    switch (type.toLowerCase()) {
      case 'gate_log':
        return {
          'title': '⚙️ Gate Activity',
          'channelId': 'gate_alerts',
          'channelName': 'Gate Monitoring',
          'importance': Importance.high,
          'priority': Priority.high,
          'color': const Color(0xFF6366F1), // Indigo
        };
      case 'emergency':
      case 'danger':
        return {
          'title': '🚨 Notification',
          'channelId': 'emergency_alerts',
          'channelName': 'Emergency Alerts',
          'importance': Importance.max,
          'priority': Priority.max,
          'color': const Color(0xFFEF4444), // Red
        };
      case 'warning':
      case 'alert':
        return {
          'title': '⚠️ Warning',
          'channelId': 'warning_alerts',
          'channelName': 'Warning Alerts',
          'importance': Importance.high,
          'priority': Priority.high,
          'color': const Color(0xFFF59E0B), // Orange
        };
      case 'info':
      default:
        return {
          'title': 'ℹ️ Info',
          'channelId': 'info_alerts',
          'channelName': 'Information',
          'importance': Importance.defaultImportance,
          'priority': Priority.defaultPriority,
          'color': const Color(0xFF3B82F6), // Blue
        };
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped');
  }

  /// Stop listening for announcements
  void dispose() {
    _announcementSubscription?.cancel();
    _isInitialized = false;
    print('Announcement Listener Service disposed');
  }
}
