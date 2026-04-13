import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:afwms_flutter/screens/welcome_screen.dart';
import 'package:afwms_flutter/screens/main_home_screen.dart';
import 'package:afwms_flutter/screens/lgu_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afwms_flutter/screens/inactive_account_screen.dart';
import 'package:afwms_flutter/screens/splash_screen.dart';
import 'dart:async';

import 'package:afwms_flutter/widgets/startup_widgets.dart';
import 'package:afwms_flutter/widgets/session_timeout_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initData();
  }

  Future<void> _initData() async {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Error loading .env file: $e");
    }
    
    // Initialize Firebase if not already initialized
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
  }

  void _retry() {
    setState(() {
      _initialization = _initData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: StartupErrorView(
                error: snapshot.error.toString(),
                onRetry: _retry,
              ),
            );
          }
          return const MyApp();
        }

        // Show a basic material app with a loading view while initializing
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: StartupLoadingView(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: RootApp.navigatorKey,
      title: 'AFWMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007EAA)),
        useMaterial3: true,
      ),
      builder: (context, child) => SessionTimeoutManager(child: child!),
      home: SplashScreen(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _authUser;
  String? _role;
  String? _status;
  bool _isLoading = true;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToAuth() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      
      setState(() {
        _authUser = user;
        _isLoading = true;
      });

      if (user != null) {
        _performHandshake(user);
      } else {
        setState(() {
          _role = null;
          _status = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performHandshake(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _role = data?['role']?.toString() ?? 'Homeowner';
          _status = data?['status']?.toString().toLowerCase() ?? 'active';
          _isLoading = false;
        });
      } else {
        setState(() {
          _role = 'Homeowner';
          _status = 'active';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in Auth Handshake: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (_authUser == null) {
      return const WelcomeScreen();
    }

    if (_status != 'active') {
      return const InactiveAccountScreen();
    }

    final roleTag = (_role ?? 'Homeowner').trim().toUpperCase();
    if (roleTag == 'LGU' || roleTag == 'ADMIN') {
      return const LGUDashboardScreen();
    }

    return const MainHomeScreen();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
