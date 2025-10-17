// services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/chat_message.dart';

class ChatService {
  final String baseUrl = 'https://runpro9ja-pxqoa.ondigitalocean.app/api';
  final String? authToken;

  ChatService(this.authToken);

  Future<List<ChatMessage>> getConversation(String withUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$withUserId'), // Changed from '/chat/conversation/$withUserId'
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messagesJson = data['msgs'];
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting conversation: $e');
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    String? orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'), // This is correct
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'message': message,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data['msg']);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Remove or update this method since you don't have this route in your backend
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations'), // This route doesn't exist in your backend
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> conversationsJson = data['conversations'];
        return conversationsJson.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting conversations: $e');
      rethrow;
    }
  }

  // Remove or update this method since you don't have this route in your backend
  Future<void> markAsRead(String messageId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/chat/mark-read/$messageId'), // This route doesn't exist in your backend
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }
}