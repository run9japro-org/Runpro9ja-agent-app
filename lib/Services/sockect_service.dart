// services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Model/chat_message.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  Function(ChatMessage)? onNewMessage;
  Function(String)? onMessageRead;
  Function(List<String>)? onMessagesRead;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String agentId, double lat, double lng)? onAgentLocationUpdate;
  Function(String userId, String status)? onUserStatusChanged;

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
        print('✅ Socket connected: ${_socket!.id}');

        // Join user's personal room using the correct event name
        _socket!.emit('join_user_room', userId);

        // Set user online
        _socket!.emit('user_online', userId);

        if (onConnected != null) onConnected!();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket disconnected');

        // Set user offline
        _socket?.emit('user_offline', userId);

        if (onDisconnected != null) onDisconnected!();
      });

      // 📨 Handle new private messages
      _socket!.on('new_message', (data) {
        print('📨 New message received via socket: $data');
        if (onNewMessage != null) {
          try {
            final messageData = Map<String, dynamic>.from(data);
            final message = ChatMessage.fromJson(messageData);
            onNewMessage!(message);
          } catch (e) {
            print('❌ Error parsing new message: $e');
          }
        }
      });

      // ✅ Handle single message read receipt
      _socket!.on('message_read', (data) {
        print('✅ Message read receipt: $data');
        if (onMessageRead != null) {
          final messageId = data['messageId'] as String;
          onMessageRead!(messageId);
        }
      });

      // ✅ Handle multiple messages read receipt
      _socket!.on('messages_read', (data) {
        print('✅ Multiple messages read receipt: $data');
        if (onMessagesRead != null) {
          final messageIds = List<String>.from(data['messageIds']);
          onMessagesRead!(messageIds);
        }
      });

      // ⚡️ Real-time agent location updates
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

      // 👤 User online/offline status
      _socket!.on('user_status_changed', (data) {
        print('👤 User status changed: $data');
        if (onUserStatusChanged != null) {
          final userId = data['userId'] as String;
          final status = data['status'] as String;
          onUserStatusChanged!(userId, status);
        }
      });

      // Support messages (if needed)
      _socket!.on('new_support_message', (data) {
        print('🆘 New support message: $data');
        // Handle support messages if needed
      });

      _socket!.on('error', (data) => print('❌ Socket error: $data'));
      _socket!.onConnectError((data) => print('❌ Connection error: $data'));
    } catch (e) {
      print('❌ Socket connection failed: $e');
    }
  }

  // 💬 Send private message to another user
  void sendMessage(ChatMessage message) {
    if (_isConnected && _socket != null) {
      print('📤 Sending message via socket: ${message.message}');
      _socket!.emit('private_message', {
        'to': message.receiverId,
        'from': message.senderId,
        'message': message.message,
        'messageId': message.id,
        'orderId': message.orderId,
      });
    } else {
      print('❌ Cannot send message - socket not connected');
    }
  }

  // ✅ Mark single message as read
  void markAsRead(String messageId, String senderId, String currentUserId) {
    if (_isConnected && _socket != null) {
      print('✅ Marking message as read: $messageId');
      _socket!.emit('mark_message_read', {
        'messageId': messageId,
        'readBy': currentUserId,
        'senderId': senderId,
      });
    }
  }

  // ✅ Mark multiple messages as read
  void markMessagesAsRead(List<String> messageIds, String senderId, String currentUserId) {
    if (_isConnected && _socket != null) {
      print('✅ Marking ${messageIds.length} messages as read');
      _socket!.emit('mark_messages_read', {
        'messageIds': messageIds,
        'readBy': currentUserId,
        'senderId': senderId,
      });
    }
  }

  // 🧭 Send agent location update
  void sendAgentLocation(double lat, double lng, {String? agentId}) {
    if (_isConnected && _socket != null) {
      print('📤 Sending agent location: $lat, $lng');
      final locationData = {
        'lat': lat,
        'lng': lng,
      };

      if (agentId != null) {
        locationData['agentId'] = agentId as double;
      }

      _socket!.emit('updateAgentLocation', locationData);
    }
  }

  // Join specific chat room for one-on-one conversations
  void joinChatRoom(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_chat_room', chatId);
      print('🔗 Joined chat room: $chatId');
    }
  }

  // Order tracking
  void joinOrderRoom(String orderId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('subscribeOrder', orderId);
      print('📦 Subscribed to order: $orderId');
    }
  }

  void leaveOrderRoom(String orderId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('unsubscribeOrder', orderId);
      print('📦 Unsubscribed from order: $orderId');
    }
  }

  // Support functionality
  void joinSupportRoom(String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_support', userId);
      print('🆘 Joined support room for user: $userId');
    }
  }

  void joinSupportAgentRoom(String agentId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_support_agent', agentId);
      print('🆘 Joined support agent room: $agentId');
    }
  }

  void sendSupportMessage(String to, String message, String from) {
    if (_isConnected && _socket != null) {
      _socket!.emit('support_message', {
        'to': to,
        'message': message,
        'from': from,
      });
    }
  }

  // User status management
  void setUserOnline(String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('user_online', userId);
    }
  }

  void setUserOffline(String userId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('user_offline', userId);
    }
  }

  void disconnect() {
    print('🔌 Disconnecting socket...');
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}