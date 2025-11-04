// screens/support_chat_screen.dart
import 'package:flutter/material.dart';

import '../Model/chat_message.dart';
import '../Services/sockect_service.dart';
import '../Services/support_service.dart';

class SupportChatScreen extends StatefulWidget {
  final String authToken;
  final String currentUserId;

  const SupportChatScreen({
    super.key,
    required this.authToken,
    required this.currentUserId,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();
  late final SupportService _supportService;

  bool _isLoading = false;
  bool _isSending = false;
  bool _isConnected = false;
  String _supportAgentId = 'support_team';

  @override
  void initState() {
    super.initState();
    _supportService = SupportService(widget.authToken);
    _initializeSupportChat();
  }

  void _initializeSupportChat() async {
    setState(() => _isLoading = true);

    try {
      // Start support chat session using SupportService
      final chatResponse = await _supportService.startSupportChat();
      print('✅ Support chat started: $chatResponse');

      // Connect to socket for real-time messaging
      _socketService.connect(widget.authToken, widget.currentUserId);
      _socketService.onNewMessage = _handleNewMessage;
      _socketService.onConnected = _onSocketConnected;
      _socketService.onDisconnected = _onSocketDisconnected;

      // Add welcome message
      _addWelcomeMessage();

      _scrollToBottom();
    } catch (e) {
      print('❌ Error initializing support chat: $e');
      _showError('Failed to connect to support: $e');
      // Still add welcome message even if connection fails
      _addWelcomeMessage();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSocketConnected() {
    setState(() => _isConnected = true);
    print('✅ Connected to support chat');
  }

  void _onSocketDisconnected() {
    setState(() => _isConnected = false);
    print('❌ Disconnected from support chat');
  }

  void _handleNewMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _supportAgentId,
      receiverId: widget.currentUserId,
      message: 'Hello! Welcome to RunPro 9ja Support. My name is Sarah, and I\'m here to help you. How can I assist you today?',
      orderId: null,
      createdAt: DateTime.now(),
      read: true,
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      // Create temporary message
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: widget.currentUserId,
        receiverId: _supportAgentId,
        message: messageText,
        orderId: null,
        createdAt: DateTime.now(),
        read: false,
      );

      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();

      // Send message using SupportService
      await _supportService.sendSupportMessage(messageText);

      // Replace with real message
      final realMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.currentUserId,
        receiverId: _supportAgentId,
        message: messageText,
        orderId: null,
        createdAt: DateTime.now(),
        read: true,
      );

      setState(() {
        _messages.remove(tempMessage);
        _messages.add(realMessage);
      });

      // Simulate support agent response
      _simulateSupportResponse(messageText);

    } catch (e) {
      _showError('Failed to send message: $e');
      _messageController.text = messageText;
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _simulateSupportResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    String response;

    if (lowerMessage.contains('order') || lowerMessage.contains('booking')) {
      response = "I can help you with your order. Could you please share your order ID or tell me more about the issue?";
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('money')) {
      response = "I understand you have payment concerns. Let me check this for you. Could you provide more details about the payment issue?";
    } else if (lowerMessage.contains('refund') || lowerMessage.contains('cancel')) {
      response = "For cancellations and refunds, I'll connect you with our billing department. Please share your order details.";
    } else if (lowerMessage.contains('agent') || lowerMessage.contains('professional')) {
      response = "I can help you with agent-related issues. Are you experiencing problems with a specific service professional?";
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      response = "You're welcome! Is there anything else I can help you with today?";
    } else if (lowerMessage.contains('bye') || lowerMessage.contains('goodbye')) {
      response = "Thank you for contacting RunPro 9ja Support! Have a great day!";
    } else {
      final responses = [
        "I understand. Let me help you with that.",
        "Thanks for sharing. Let me look into this for you.",
        "I appreciate you bringing this to our attention. Let me get the right information.",
        "I can definitely help with that. Could you provide more details?",
        "That's a great question. Let me check our resources for the best solution.",
      ];
      response = responses[DateTime.now().millisecond % responses.length];
    }

    Future.delayed(const Duration(seconds: 2), () {
      final supportMessage = ChatMessage(
        id: 'support_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _supportAgentId,
        receiverId: widget.currentUserId,
        message: response,
        orderId: null,
        createdAt: DateTime.now(),
        read: false,
      );

      if (mounted) {
        setState(() {
          _messages.add(supportMessage);
        });
        _scrollToBottom();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Support info banner
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.support_agent, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isConnected
                        ? 'Connected to RunPro Support Team'
                        : 'Connecting to support...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'RunPro Support',
              style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'We\'re here to help you 24/7',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.currentUserId;

        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final isSupport = message.senderId == _supportAgentId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.support_agent, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blue[500]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSupport) ...[
                    Text(
                      'RunPro Support',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[600], size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'How can we help you today?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _messageController.text.trim().isEmpty ? Colors.grey : Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}