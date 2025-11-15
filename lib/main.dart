import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'Auth/notification_service.dart';
import 'Model/notification_model.dart';
import 'Other_screens/available_orders_screen.dart';
import 'Other_screens/my_order_screen.dart';
import 'Other_screens/notification_screen.dart';
import 'services/local_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (context) => NotificationService(context.read<AuthService>())),
        Provider(create: (_) => LocalNotificationService()),
      ],
      child: MaterialApp(
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
        onGenerateRoute: (settings) {
          if (settings.name == '/otp') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => OtpScreen(
                userId: args?['userId'] ?? '',
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) => _errorRoute(settings),
          );
        },
      ),
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
  int _unreadNotifications = 0;
  bool _isLoading = true;

  final List<Widget> _pages = [
    DashboardScreen(),
    MyOrdersScreen(),
    ScheduleScreen(),
    ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
     _initializeNotifications();
     _loadUnreadCount();
    await _checkForNewOrders();
    setState(() {
      _isLoading = false;
    });
  }

  void _initializeNotifications() async {
    final localNotifications = context.read<LocalNotificationService>();

    final areEnabled = await localNotifications.areNotificationsEnabled();
    print('Notifications enabled: $areEnabled');

    if (!areEnabled) {
      final granted = await localNotifications.requestPermissions();
      print('Permission granted: $granted');
    }

    await localNotifications.initialize(
      onNotificationTap: _handleNotificationTap,
    );

    print('Local notifications initialized successfully');
  }

  void _loadUnreadCount() async {
    final notificationService = context.read<NotificationService>();
    try {
      final count = await notificationService.getUnreadCount();
      setState(() {
        _unreadNotifications = count;
      });
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  // REAL NOTIFICATION TRIGGERS ==============================================

  Future<void> _checkForNewOrders() async {
    final notificationService = context.read<NotificationService>();
    final localNotifications = context.read<LocalNotificationService>();

    try {
      // Fetch latest notifications from API
      final response = await notificationService.getNotifications(limit: 5);

      // Check for unread notifications and show them
      final unreadNotifications = response.notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        await localNotifications.showLocalNotification(notification);
        await Future.delayed(Duration(milliseconds: 500)); // Small delay between notifications
      }

      print('Processed ${unreadNotifications.length} unread notifications');
    } catch (e) {
      print('Error checking for new orders: $e');
    }
  }

  // Method to simulate new order assignment (call this when you get real orders)
  Future<void> _simulateNewOrderAssignment() async {
    final localNotifications = context.read<LocalNotificationService>();

    await localNotifications.showNewOrderNotification(
        orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'John Doe',
        location: 'Lagos Mainland',
        amount: '₦2,500'
    );
  }

  // Method to simulate order status update
  Future<void> _simulateOrderStatusUpdate() async {
    final localNotifications = context.read<LocalNotificationService>();

    await localNotifications.showDeliveryStatusNotification(
        orderId: 'ORD12345',
        status: 'Picked Up',
        customerName: 'Jane Smith'
    );
  }

  // Method to simulate payment received
  Future<void> _simulatePaymentReceived() async {
    final localNotifications = context.read<LocalNotificationService>();

    await localNotifications.showPaymentNotification(
        amount: '3,500',
        orderId: 'ORD12345'
    );
  }

  // Method to simulate chat message
  Future<void> _simulateChatMessage() async {
    final localNotifications = context.read<LocalNotificationService>();

    await localNotifications.showChatNotification(
        senderName: 'Customer Support',
        message: 'Hello! We have an update on your recent delivery.',
        orderId: 'ORD12345'
    );
  }

  void _handleNotificationTap(flutter_notifications.NotificationResponse response) {
    final payload = response.payload;
    print('Notification tapped with payload: $payload');

    if (payload != null) {
      _handleNotificationPayload(payload);
    } else {
      Navigator.pushNamed(context, '/notifications');
    }
  }

  void _handleNotificationPayload(String payload) {
    String? actionUrl;

    try {
      final payloadData = json.decode(payload) as Map<String, dynamic>;
      actionUrl = payloadData['actionUrl'] as String?;
      print('Parsed actionUrl from JSON: $actionUrl');
    } catch (e) {
      actionUrl = _extractRouteFromString(payload);
    }

    if (actionUrl != null && _isValidRoute(actionUrl)) {
      Navigator.pushNamed(context, actionUrl);
    } else {
      Navigator.pushNamed(context, '/notifications');
    }
  }

  String? _extractRouteFromString(String payload) {
    final routes = [
      '/available-orders', '/my-orders', '/notifications',
      '/profile', '/schedule', '/earnings', '/chat'
    ];

    for (final route in routes) {
      if (payload.contains(route)) return route;
    }

    if (payload.startsWith('/')) return payload;
    return null;
  }

  bool _isValidRoute(String route) {
    final validRoutes = [
      '/available-orders', '/my-orders', '/notifications',
      '/profile', '/schedule', '/earnings', '/chat'
    ];
    return validRoutes.contains(route);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

     _loadUnreadCount();
    await _checkForNewOrders();

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "My Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.person),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Test Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildNotificationOption(
              'New Order',
              'Simulate new order assignment',
              _simulateNewOrderAssignment,
            ),
            _buildNotificationOption(
              'Order Status',
              'Simulate order status update',
              _simulateOrderStatusUpdate,
            ),
            _buildNotificationOption(
              'Payment',
              'Simulate payment received',
              _simulatePaymentReceived,
            ),
            _buildNotificationOption(
              'Chat Message',
              'Simulate new chat message',
              _simulateChatMessage,
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.notifications, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          Navigator.pop(context);
          onTap();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title notification sent!')),
          );
        },
      ),
    );
  }
}