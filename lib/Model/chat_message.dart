// models/chat_message.dart
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String? orderId;
  final DateTime createdAt;
  final bool read;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.orderId,
    required this.createdAt,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'],
      senderId: json['sender'] is String ? json['sender'] : json['sender']['_id'],
      receiverId: json['receiver'] is String ? json['receiver'] : json['receiver']['_id'],
      message: json['message'],
      orderId: json['order'],
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'message': message,
      'orderId': orderId,
    };
  }
}

// models/conversation.dart
class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? orderId;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.orderId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? json['id'],
      otherUserId: json['otherUser']['_id'],
      otherUserName: json['otherUser']['name'],
      otherUserImage: json['otherUser']['profileImage'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      orderId: json['orderId'],
    );
  }
}