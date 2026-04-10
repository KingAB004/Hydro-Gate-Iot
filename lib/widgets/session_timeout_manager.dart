import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;

  const SessionTimeoutManager({super.key, required this.child});

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _idleTimer;
  Timer? _warningTimer;
  bool _isWarningDialogVisible = false;

  // Configuration
  static const _idleTimeout = Duration(minutes: 4, seconds: 30);
  static const _warningDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _showWarningDialog);
  }

  void _resetTimer() {
    // Only reset if the warning dialog isn't already visible.
    // If the dialog is visible, the user must explicitly click "Stay Logged In".
    if (!_isWarningDialogVisible) {
      _startIdleTimer();
    }
  }

  void _showWarningDialog() {
    final context = RootApp.navigatorKey.currentContext;
    if (!mounted || context == null || FirebaseAuth.instance.currentUser == null) return;

    setState(() => _isWarningDialogVisible = true);

    // Start the countdown to final logout
    _warningTimer = Timer(_warningDuration, _logout);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _SessionWarningDialog(
          duration: _warningDuration,
          onStay: () {
            Navigator.of(context).pop();
            _cancelWarning();
          },
          onLogout: () {
            Navigator.of(context).pop();
            _logout();
          },
        );
      },
    );
  }

  void _cancelWarning() {
    _warningTimer?.cancel();
    setState(() => _isWarningDialogVisible = false);
    _startIdleTimer();
  }

  Future<void> _logout() async {
    if (!mounted) return;

    // Close dialog if visible
    if (_isWarningDialogVisible) {
      RootApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    await FirebaseAuth.instance.signOut();
    setState(() {
      _isWarningDialogVisible = false;
      _idleTimer?.cancel();
      _warningTimer?.cancel();
    });
    
    // AuthWrapper in main.dart will automatically redirect to WelcomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}

class _SessionWarningDialog extends StatefulWidget {
  final Duration duration;
  final VoidCallback onStay;
  final VoidCallback onLogout;

  const _SessionWarningDialog({
    required this.duration,
    required this.onStay,
    required this.onLogout,
  });

  @override
  State<_SessionWarningDialog> createState() => _SessionWarningDialogState();
}

class _SessionWarningDialogState extends State<_SessionWarningDialog> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.timer_outlined, color: Color(0xFF007EAA)),
          SizedBox(width: 12),
          Text('Session Timeout'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You have been inactive for a while. You will be logged out automatically in:',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            '$_secondsRemaining s',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007EAA),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onLogout,
          child: const Text('Log Out', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: widget.onStay,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007EAA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Stay Logged In'),
        ),
      ],
    );
  }
}
