import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import '../services/audit_log_service.dart';
import '../widgets/custom_text_field.dart';

class LGULoginScreen extends StatefulWidget {
  const LGULoginScreen({super.key});

  @override
  State<LGULoginScreen> createState() => _LGULoginScreenState();
}

class _LGULoginScreenState extends State<LGULoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    // Email domain validation for LGU
    if (!email.toLowerCase().endsWith('@lgu.com')) {
      await AuditLogService().logEvent(
        action: 'login_denied',
        severity: 'warning',
        description: 'LGU login denied due to invalid domain',
        email: email,
        role: 'LGU',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Only @lgu.com accounts are allowed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        await AuditLogService().logEvent(
          action: 'login',
          severity: 'safe',
          description: 'LGU login',
          email: email,
          role: 'LGU',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      await AuditLogService().logEvent(
        action: 'login_failed',
        severity: 'warning',
        description: 'LGU login failed: ${e.code}',
        email: email,
        role: 'LGU',
      );
      if (mounted) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found') {
          message = 'No LGU account found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else {
          message = e.message ?? message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // LGU branding color: Deep Teal
    const lguPrimaryColor = Color(0xFF00695C); 

    return Scaffold(
      backgroundColor: lguPrimaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 120,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'LGU PERSONNEL LOGIN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: lguPrimaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Automated Floodgate & Waterlevel Monitoring System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomTextField(
                            label: 'LGU Email',
                            placeholder: 'username@lgu.com',
                            controller: _emailController,
                            primaryColor: lguPrimaryColor,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Password',
                            placeholder: 'Enter your password',
                            controller: _passwordController,
                            isPassword: true,
                            primaryColor: lguPrimaryColor,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lguPrimaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Login as Personnel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'LGU accounts are created by the system administrator.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Confidential - Personnel Use Only',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
