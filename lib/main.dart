import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Profile_screens/dashboard_screen.dart';
import 'package:runpro9ja_agent/Profile_screens/profile_screen.dart';
import 'package:runpro9ja_agent/Profile_screens/service_selection_screen.dart';
import 'package:runpro9ja_agent/login_screen.dart';
import 'package:runpro9ja_agent/schedule_screen.dart';
import 'package:runpro9ja_agent/Profile_screens/service_history_screen.dart';
import 'package:runpro9ja_agent/signup_screen.dart';
import 'package:runpro9ja_agent/splash_screen.dart';
import 'package:runpro9ja_agent/verified_screen.dart';
import 'package:runpro9ja_agent/welcome_screen.dart';
import 'package:runpro9ja_agent/otp_screen.dart';

import 'Auth/auth_services.dart';
import 'Other_screens/available_orders_screen.dart';
import 'Other_screens/my_order_screen.dart';
import 'Other_screens/notification_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomePage(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => AgentLoginPage(),
        '/verified': (context) => VerifiedPage(),
        '/selection': (context) => ServiceSelectionScreen(),
        '/main': (context) => const HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/available-orders': (context) => AvailableOrdersScreen(),
        '/my-orders': (context) => MyOrdersScreen(),
        '/service-history': (context) => ServiceHistoryScreen(),
      },
      // Add this to handle routes with parameters
      onGenerateRoute: (settings) {
        // Handle OTP screen with userId parameter
        if (settings.name == '/otp') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => OtpScreen(
              userId: args?['userId'] ?? '',
            ),
          );
        }

        // Default to named routes
        return MaterialPageRoute(
          builder: (context) => _errorRoute(settings),
        );
      },
    );
  }

  static Widget _errorRoute(RouteSettings settings) {
    return Scaffold(
      body: Center(
        child: Text('No route defined for ${settings.name}'),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    MyOrdersScreen(),
    ScheduleScreen(),
    ProfileScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Service History"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}