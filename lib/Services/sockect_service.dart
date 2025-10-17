// services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Model/chat_message.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // 🔹 Existing callbacks
  Function(ChatMessage)? onNewMessage;
  Function(String)? onMessageRead;
  Function()? onConnected;
  Function()? onDisconnected;

  // 🔹 New callbacks for location updates
  Function(String agentId, double lat, double lng)? onAgentLocationUpdate;

  void connect(String token, String userId) {
    try {
      _socket = IO.io(
        'https://runpro9ja-pxqoa.ondigitalocean.app',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket connected');

        // Join user's personal room
        _socket!.emit('join_user', userId);

        if (onConnected != null) onConnected!();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket disconnected');
        if (onDisconnected != null) onDisconnected!();
      });

      // 📨 Existing events
      _socket!.on('new_message', (data) {
        print('📨 New message: $data');
        if (onNewMessage != null) {
          try {
            final message = ChatMessage.fromJson(data);
            onNewMessage!(message);
          } catch (e) {
            print('❌ Error parsing new message: $e');
          }
        }
      });

      _socket!.on('message_read', (data) {
        if (onMessageRead != null) {
          onMessageRead!(data['messageId']);
        }
      });

      // ⚡️ New: Real-time agent location updates
      _socket!.on('agentLocationUpdate', (data) {
        print('📍 Agent location update received: $data');
        if (onAgentLocationUpdate != null) {
          try {
            final lat = (data['lat'] as num).toDouble();
            final lng = (data['lng'] as num).toDouble();
            final agentId = data['agentId'] as String;
            onAgentLocationUpdate!(agentId, lat, lng);
          } catch (e) {
            print('❌ Error handling agent location update: $e');
          }
        }
      });

      _socket!.on('error', (data) => print('❌ Socket error: $data'));
      _socket!.onConnectError((data) => print('❌ Connection error: $data'));
    } catch (e) {
      print('❌ Socket connection failed: $e');
    }
  }

  // 🧭 New: Method for agent to send location
  void sendAgentLocation(double lat, double lng) {
    if (_isConnected && _socket != null) {
      print('📤 Sending agent location: $lat, $lng');
      _socket!.emit('updateAgentLocation', {
        'lat': lat,
        'lng': lng,
      });
    }
  }

  void sendMessage(ChatMessage message) {
    if (_isConnected && _socket != null) {
      _socket!.emit('send_message', message.toJson());
    }
  }

  void markAsRead(String messageId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('mark_read', {'messageId': messageId});
    }
  }

  void joinOrderRoom(String orderId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('subscribeOrder', orderId);
    }
  }

  void leaveOrderRoom(String orderId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('unsubscribeOrder', orderId);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}
