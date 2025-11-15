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
      print('📨 Fetching conversation with user: $withUserId');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/$withUserId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messagesJson = data['msgs'];

        print('📨 Found ${messagesJson.length} messages');

        final messages = messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

        // Sort by creation date (oldest first)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return messages;
      } else if (response.statusCode == 404) {
        print('💬 No existing conversation found, starting new one');
        return [];
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode} - ${response.body}');
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
      print('📤 Sending message to: $receiverId');
      print('📝 Message: $message');

      final Map<String, dynamic> requestBody = {
        'receiverId': receiverId,
        'message': message,
      };

      if (orderId != null && orderId.isNotEmpty) {
        requestBody['orderId'] = orderId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('🔍 Send message response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['msg'] != null) {
          return ChatMessage.fromJson(data['msg']);
        } else {
          return ChatMessage.fromJson(data);
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Mark single message as read via API
  Future<void> markAsRead(String messageId) async {
    try {
      print('✅ Marking message as read via API: $messageId');

      final response = await http.put(
        Uri.parse('$baseUrl/chat/mark-read/$messageId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Message $messageId marked as read successfully');
      } else {
        print('⚠️ Failed to mark message as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  // Mark multiple messages as read via API
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    try {
      print('✅ Marking ${messageIds.length} messages as read via API');

      final response = await http.put(
        Uri.parse('$baseUrl/chat/mark-read-bulk'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'messageIds': messageIds,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ ${messageIds.length} messages marked as read successfully');
      } else {
        print('⚠️ Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
  // ✅ Fetch customer profile details
  // In ChatService class - ADD THIS METHOD
  Future<Map<String, dynamic>> getCustomerProfile(String customerId) async {
    try {
      print('🔍 Fetching customer profile for ID: $customerId');

      final response = await http.get(
        Uri.parse('https://runpro9ja-pxqoa.ondigitalocean.app/api/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Profile API Response Status: ${response.statusCode}');
      print('📡 Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Customer profile loaded successfully: $data');
        return data;
      } else {
        print('❌ Failed to load customer profile: ${response.statusCode}');
        throw Exception('Failed to load customer profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching customer profile: $e');
      rethrow;
    }
  }
  bool get isConfigured {
    return authToken != null && authToken!.isNotEmpty;
  }
}

