import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'weather_screen.dart';
import 'alerts_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  MainHomeScreenState createState() => MainHomeScreenState();
}

class MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    AlertsScreen(),
    WeatherScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // Method to navigate to home tab from child screens
  void navigateToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern bgLight
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF0EA5E9).withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0EA5E9)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.notifications_rounded, color: Color(0xFF0EA5E9)),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_queue_rounded, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.cloud_rounded, color: Color(0xFF0EA5E9)),
              label: 'Weather',
            ),
          ],
        ),
      ),
    );
  }
}
