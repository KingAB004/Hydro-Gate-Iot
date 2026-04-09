import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'weather_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';
import 'audit_logs_screen.dart';
import '../widgets/assistive_touch.dart';
import '../services/auth_service.dart';
import '../services/audit_log_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  MainHomeScreenState createState() => MainHomeScreenState();
}

class MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 1; // Default to Home (Center)
  late PageController _pageController;

  // Modern Color Palette
  static const Color brandBlue = Color(0xFF007EAA);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color cardWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const AlertsScreen(),
    const DashboardScreen(),
    const WeatherScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  // Method to navigate to home tab from child screens
  void navigateToHome() {
    _onItemTapped(1);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF007EAA);
    const inactiveColor = Color(0xFF94A3B8);

    return AssistiveTouch(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: _buildDrawer(),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          physics: const BouncingScrollPhysics(),
          children: _widgetOptions,
        ),
        bottomNavigationBar: Container(
          height: 110,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Alerts', primaryColor, inactiveColor),
                _buildNavItem(1, Icons.home_outlined, Icons.home_rounded, 'Home', primaryColor, inactiveColor),
                _buildNavItem(2, Icons.cloud_outlined, Icons.cloud_rounded, 'Weather', primaryColor, inactiveColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color primaryColor, Color inactiveColor) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SHARED DRAWER (SIDEBAR)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardWhite,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(icon: Icons.manage_accounts_rounded, title: 'Account', onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: const Divider()),
                _buildDrawerItem(icon: Icons.logout_rounded, title: 'Logout', onTap: () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                       final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                       final role = snapshot.data()?['role'] ?? 'User';
                       await AuditLogService().logEvent(
                        action: 'logout',
                        severity: 'safe',
                        description: 'User logged out',
                        role: role,
                      );
                    } catch (e) { print('Logout log failed: $e'); }
                  }
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                }, isDestructive: true),
                
                // Audit Logs (Only for Admin/LGU)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null 
                      ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                      : null,
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    if (data != null && (data['role'] == 'Admin' || data['role'] == 'LGU')) {
                      return _buildDrawerItem(icon: Icons.receipt_long_rounded, title: 'Audit Logs', onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                        );
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String username = 'User';
        String role = 'User';
        final String email = user.email ?? '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            username = data['username'] ?? 'User';
            role = data['role'] ?? 'User';
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          color: const Color(0xFF0F172A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: brandBlue, width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 34, color: brandBlue),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? dangerRed : textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDestructive ? dangerRed.withOpacity(0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDestructive ? dangerRed.withOpacity(0.18) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDestructive ? dangerRed.withOpacity(0.12) : brandBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                ),
                Icon(Icons.chevron_right_rounded, color: textSecondary.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
