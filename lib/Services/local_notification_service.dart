import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:runpro9ja_agent/Model/notification_model.dart' hide NotificationResponse;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Notification channels
  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'general_channel',
    'General Notifications',
    description: 'General notifications channel',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _orderChannel = AndroidNotificationChannel(
    'order_channel',
    'Order Updates',
    description: 'Order and delivery notifications',
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _promotionChannel = AndroidNotificationChannel(
    'promotion_channel',
    'Promotions',
    description: 'Promotional offers and discounts',
    importance: Importance.defaultImportance,
    
    playSound: false,
  );

  // Initialize the notification service
  Future<void> initialize({Function(NotificationResponse)? onNotificationTap}) async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create notification channels
    await _createNotificationChannels();

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap ?? _defaultNotificationTap,
    );
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_generalChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_promotionChannel);
  }

  // Default notification tap handler
  static void _defaultNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can handle navigation based on the payload
    // For example, use GetIt, Navigator, or any state management solution
  }

  // Get the appropriate channel for notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
      case NotificationType.deliveryStatus:
      case NotificationType.agentAssigned:
        return _orderChannel.id;
      case NotificationType.promotion:
        return _promotionChannel.id;
      default:
        return _generalChannel.id;
    }
  }


  // Get the appropriate importance for notification priority
  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.min;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  // Show immediate local notification
  Future<void> showLocalNotification(NotificationModel notification) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelId(notification.type), // Using channel ID as name for simplicity
      channelDescription: 'Notifications for ${notification.type.toString().split('.').last}',
      importance: _getImportance(notification.priority),
      priority: Priority.high,
      playSound: true,
      color: notification.color,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(notification.message),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      threadIdentifier: _getChannelId(notification.type),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.actionUrl ?? notification.type.toString(),
    );
  }

  // Schedule a local notification for future
  Future<void> scheduleLocalNotification(
      NotificationModel notification,
      DateTime scheduledTime,
      ) async {
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelId(notification.type),
      channelDescription: 'Scheduled notifications for ${notification.type.toString().split('.').last}',
      importance: _getImportance(notification.priority),
      priority: Priority.high,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.message,
      tzScheduledTime,
      details,
      payload: notification.actionUrl,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Schedule a recurring notification
  Future<void> scheduleRepeatingNotification(
      NotificationModel notification,
      RepeatInterval interval,
      ) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelId(notification.type),
      channelDescription: 'Repeating notifications for ${notification.type.toString().split('.').last}',
      importance: _getImportance(notification.priority),
      priority: Priority.high,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.periodicallyShow(
      notification.id.hashCode,
      notification.title,
      notification.message,
      interval,
      details,
      payload: notification.actionUrl,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(String notificationId) async {
    await _notificationsPlugin.cancel(notificationId.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Add these methods to your LocalNotificationService class

// Show new order notification
  Future<void> showNewOrderNotification({
    required String orderId,
    required String customerName,
    required String location,
    String? amount,
  }) async {
    final notification = NotificationModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      title: 'New Delivery Order! 🚀',
      message: 'Order #$orderId from $customerName in $location${amount != null ? ' - $amount' : ''}',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.high,
      data: {
        'order_id': orderId,
        'customer_name': customerName,
        'location': location,
        if (amount != null) 'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
      isRead: false,
      actionUrl: '/available-orders',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showLocalNotification(notification);
  }

// Show delivery status update
  Future<void> showDeliveryStatusNotification({
    required String orderId,
    required String status,
    required String customerName,
  }) async {
    final notification = NotificationModel(
      id: 'status_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      title: 'Delivery $status',
      message: 'Order #$orderId for $customerName is now $status',
      type: NotificationType.deliveryStatus,
      priority: NotificationPriority.medium,
      data: {
        'order_id': orderId,
        'status': status,
        'customer_name': customerName,
        'timestamp': DateTime.now().toIso8601String(),
      },
      isRead: false,
      actionUrl: '/my-orders',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showLocalNotification(notification);
  }

// Show payment notification
  Future<void> showPaymentNotification({
    required String amount,
    required String orderId,
  }) async {
    final notification = NotificationModel(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      title: 'Payment Received! 💰',
      message: 'You earned $amount for Order #$orderId',
      type: NotificationType.payment,
      priority: NotificationPriority.medium,
      data: {
        'amount': amount,
        'order_id': orderId,
        'currency': 'NGN',
        'timestamp': DateTime.now().toIso8601String(),
      },
      isRead: false,
      actionUrl: '/profile',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showLocalNotification(notification);
  }

// Show chat notification
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String orderId,
  }) async {
    final notification = NotificationModel(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'system',
      title: 'Message from $senderName',
      message: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      type: NotificationType.chat,
      priority: NotificationPriority.medium,
      data: {
        'sender_name': senderName,
        'order_id': orderId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      },
      isRead: false,
      actionUrl: '/chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showLocalNotification(notification);
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print('❌ Error checking notification permission: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final bool? iosGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return iosGranted ?? true;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }
}