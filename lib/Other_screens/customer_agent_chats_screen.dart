// screens/agent_customer_chat_screen.dart
import 'package:flutter/material.dart';

import '../Model/chat_message.dart';
import '../Services/chat_service.dart';
import '../Services/sockect_service.dart';

class AgentCustomerChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerImage;
  final String orderId;
  final String authToken;
  final String currentUserId;

  const AgentCustomerChatScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerImage,
    required this.orderId,
    required this.authToken,
    required this.currentUserId,
  });

  @override
  State<AgentCustomerChatScreen> createState() => _AgentCustomerChatScreenState();
}

class _AgentCustomerChatScreenState extends State<AgentCustomerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();
  late final ChatService _chatService;

  bool _isLoading = false;
  bool _isSending = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.authToken);
    _initializeChat();
  }

  void _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      // Load conversation with this customer
      final messages = await _chatService.getConversation(widget.customerId);
      setState(() {
        _messages.addAll(messages);
      });

      // Connect socket
      _socketService.connect(widget.authToken, widget.currentUserId);
      _socketService.onNewMessage = _handleNewMessage;
      _socketService.onConnected = _onSocketConnected;
      _socketService.onDisconnected = _onSocketDisconnected;

      // Mark unread messages as read
      _markUnreadMessagesAsRead();

      _scrollToBottom();
    } catch (e) {
      _showError('Failed to load messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSocketConnected() {
    setState(() => _isConnected = true);
    print('✅ Connected to chat with ${widget.customerName}');
  }

  void _onSocketDisconnected() {
    setState(() => _isConnected = false);
    print('❌ Disconnected from chat');
  }

  void _handleNewMessage(ChatMessage message) {
    if (message.senderId == widget.customerId || message.receiverId == widget.customerId) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
      _socketService.markAsRead(message.id);
    }
  }

  void _markUnreadMessagesAsRead() {
    for (final message in _messages) {
      if (!message.read && message.senderId == widget.customerId) {
        _chatService.markAsRead(message.id);
        _socketService.markAsRead(message.id);
      }
    }
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

    final text = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: widget.currentUserId,
        receiverId: widget.customerId,
        message: text,
        orderId: widget.orderId,
        createdAt: DateTime.now(),
        read: false,
      );

      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();

      // Send actual message
      final message = await _chatService.sendMessage(
        receiverId: widget.customerId,
        message: text,
        orderId: widget.orderId,
      );

      setState(() {
        _messages.remove(tempMessage);
        _messages.add(message);
      });
    } catch (e) {
      _showError('Failed to send message: $e');
      _messageController.text = text;
      setState(() {
        _messages.removeWhere((m) => m.id.startsWith('temp_'));
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
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
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.customerImage),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'Online' : 'Connecting...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(Icons.assignment, color: Colors.green[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order: ${widget.orderId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
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
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Start a conversation with your customer',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == widget.currentUserId;
        return _buildMessageBubble(msg, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final isTemp = msg.id.startsWith('temp_');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.customerImage),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? (isTemp ? Colors.green[300] : Colors.green[500])
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe && !isTemp) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.read ? Icons.done_all : Icons.done,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green[100],
              radius: 16,
              child: Icon(Icons.person, color: Colors.green[600], size: 18),
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
                hintText: 'Type a message...',
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
              color: _messageController.text.trim().isEmpty
                  ? Colors.grey
                  : Colors.green,
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
              onPressed:
              _messageController.text.trim().isEmpty ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
