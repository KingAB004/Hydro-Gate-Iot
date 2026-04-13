import 'package:flutter/material.dart';
import 'package:afwms_flutter/services/auth_service.dart';
import 'package:afwms_flutter/screens/welcome_screen.dart';

class InactiveAccountScreen extends StatelessWidget {
  const InactiveAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandTeal = Color(0xFF00897B);
    const Color dangerRed = Color(0xFFEF4444);
    const Color textPrimary = Color(0xFF0F172A);
    const Color textSecondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: dangerRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: dangerRed,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Account Deactivated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your access to the HydroGate system has been suspended by the administrator. Please contact your local LGU office for reactivation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Back to Sign In',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
