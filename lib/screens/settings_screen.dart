import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/audit_log_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color brandBlue = Color(0xFF007EAA);
  static const Color dangerRed = Color(0xFFEF4444);

  // ── Profile state ────────────────────────────────────────────────────────────
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _email = '';
  String _role = '';

  // ── Preferences state ────────────────────────────────────────────────────────
  bool _smsEnabled = false;
  bool _pushEnabled = false;

  // ── General ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────
  Future<void> _loadAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null && mounted) {
          final data = doc.data()!;
          setState(() {
            _usernameController.text = data['username'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _role = data['role'] ?? 'User';
            _smsEnabled = data['smsNotificationsEnabled'] ?? false;
            _pushEnabled = data['pushNotificationsEnabled'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Error loading account data: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Save profile ─────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(_usernameController.text.trim());

      try {
        await AuditLogService().logEvent(
          action: 'profile_update',
          severity: 'safe',
          description: 'Profile updated via Account screen',
        );
      } catch (e) {
        debugPrint('Audit log write failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: brandBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Toggle preference ─────────────────────────────────────────────────────────
  Future<void> _updatePreference(String key, bool value) async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .set({key: value}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving preference: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save preference')),
          );
        }
        _loadAllData();
      }
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text('Cancel',
                style:
                    TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuditLogService().logEvent(
        action: 'logout',
        severity: 'safe',
        description: 'User logged out from account screen',
      );
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

  // ── Build ─────────────────────────────────────────────────────────────────────
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
          'Account',
          style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.4),
        ),
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
            color: textPrimary,
            iconSize: 20,
          ),
        ),
      ),
      // ── Sticky bottom action bar ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: cardWhite,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            // Save Changes
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Logout
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dangerRed.withOpacity(0.08),
                  foregroundColor: dangerRed,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: dangerRed),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: dangerRed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // ── Scrollable body ───────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + role ───────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brandBlue.withOpacity(0.1),
                      border: Border.all(color: brandBlue, width: 3),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 44, color: brandBlue),
                  ),
                  const SizedBox(height: 12),
                  if (_role.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: brandBlue,
                            letterSpacing: 1.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── ACCOUNT section ─────────────────────────────────────────────────
            _buildSectionHeader('Profile'),
            const SizedBox(height: 12),
            _buildInputCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Display Name',
                    icon: Icons.person_outline_rounded,
                    isFirst: true,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildReadonlyField(
                    label: 'Email Address',
                    value: _email,
                    icon: Icons.email_outlined,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── PREFERENCES section ─────────────────────────────────────────────
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 12),
            _buildInputCard(
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
            ),

            const SizedBox(height: 28),

            // ── SUPPORT section ──────────────────────────────────────────────────
            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
            _buildInputCard(
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
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 1.5),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary),
        prefixIcon: Icon(icon, color: brandBlue, size: 22),
        border: InputBorder.none,
        filled: true,
        fillColor: cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildReadonlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      style: const TextStyle(color: textSecondary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary),
        prefixIcon: Icon(icon, color: textSecondary, size: 22),
        border: InputBorder.none,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: bgLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: brandBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: brandBlue),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
                decoration: BoxDecoration(
                    color: bgLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: textPrimary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
              ),
              const Icon(Icons.chevron_right_rounded, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
