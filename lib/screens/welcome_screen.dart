import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'hydrogate_logo.png',
                  height: 170,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007EAA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF007EAA),
                        size: 82,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Control the Flow, Secure Tomorrow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF003249),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Smart floodgate operations and water-level monitoring in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5C7680),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007EAA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Emergency: 911',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A9097),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Marikina Rescue: 161',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A9097),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
