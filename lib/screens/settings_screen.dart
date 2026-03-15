import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smsEnabled = false;
  bool _pushEnabled = false;
  bool _isLoading = true;

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color brandBlue = Color(0xFF0EA5E9);
  static const Color dangerRed = Color(0xFFEF4444);

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _smsEnabled = data['smsNotificationsEnabled'] ?? false;
            _pushEnabled = data['pushNotificationsEnabled'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Error loading preferences: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updatePreference(String key, bool value) async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          key: value,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving preference: $e');
        // Revert UI on failure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
        );
        _loadPreferences();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgLight,
        body: Center(child: CircularProgressIndicator(color: brandBlue)),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.4),
        ),
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account'),
            const SizedBox(height: 12),
            _buildProfileCard(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 12),
            _buildPreferencesContainer(),

            const SizedBox(height: 32),
            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
            _buildSupportContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Profile Implementation
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: brandBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: brandBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'My Profile',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'User Email',
                        style: const TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesContainer() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.sms_rounded,
            title: 'SMS Notifications',
            subtitle: 'Receive alerts for critical levels',
            value: _smsEnabled,
            onChanged: (val) {
              setState(() => _smsEnabled = val);
              _updatePreference('smsNotificationsEnabled', val);
            },
          ),
          const Divider(height: 1, indent: 64),
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive app push alerts',
            value: _pushEnabled,
            onChanged: (val) {
              setState(() => _pushEnabled = val);
              _updatePreference('pushNotificationsEnabled', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContainer() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.headset_mic_rounded,
            title: 'Help & Support',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 64),
          _buildListTile(
            icon: Icons.info_outline_rounded,
            title: 'About the App',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 64),
          _buildListTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            textColor: dangerRed,
            iconColor: dangerRed,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: brandBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: brandBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = textPrimary,
    Color iconColor = textPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              ),
              if (textColor == textPrimary)
                const Icon(Icons.chevron_right_rounded, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: dangerRed),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true && mounted) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
