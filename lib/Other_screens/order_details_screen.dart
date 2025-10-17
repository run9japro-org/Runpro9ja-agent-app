import 'package:flutter/material.dart';
import '../Auth/order_service.dart';
import '../Model/order_model.dart';
import '../Auth/auth_services.dart';
import 'customer_agent_chats_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService(AuthService());
  final AuthService _authService = AuthService();
  late Order _order;
  bool _isLoading = false;
  String? _authToken;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadAuthData();
    _loadOrderDetails();
  }

  Future<void> _loadAuthData() async {
    try {
      _authToken = await _authService.getToken();
      final userData = await _authService.getUserData();
      if (userData != null) {
        _currentUserId = userData['id']?.toString();
      }
    } catch (e) {
      print('Error loading auth data: $e');
    }
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final updatedOrder = await _orderService.getOrderById(_order.id);
      if (updatedOrder != null) {
        setState(() {
          _order = updatedOrder;
        });
      }
    } catch (e) {
      print('Error loading order details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final success = await _orderService.updateOrderStatus(_order.id, newStatus);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showStatusUpdateDialog() {
    final availableStatuses = _getAvailableStatuses(_order.status);

    if (availableStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No status updates available for this order'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) => ListTile(
            leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
            title: Text(_getStatusText(status)),
            subtitle: Text(_getStatusDescription(status)),
            onTap: () {
              Navigator.pop(context);
              _updateOrderStatus(status);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return ['in-progress', 'completed'];
      case 'in-progress':
        return ['completed'];
      default:
        return [];
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'in-progress': return Icons.directions_car;
      case 'completed': return Icons.verified;
      default: return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in-progress': return Colors.purple;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in-progress': return 'In Progress';
      case 'completed': return 'Completed';
      default: return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'in-progress': return 'Start working on this order';
      case 'completed': return 'Mark this order as finished';
      default: return '';
    }
  }

  void _contactCustomer() {
    if (_order.customer?['phone'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer phone number not available'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${_order.customer!['fullName'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('Phone: ${_order.customer!['phone']}'),
            SizedBox(height: 16),
            Text('How would you like to contact them?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${_order.customer!['phone']}'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text('Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openChatScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Chat'),
          ),
        ],
      ),
    );
  }

  void _openChatScreen() {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User information not available. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customerId = _order.customer?['id']?.toString() ?? _order.customerId?.toString();
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentCustomerChatScreen(
          customerId: customerId,
          customerName: _order.customer?['fullName'] ?? 'Customer',
          customerImage: _order.customer?['image'] ?? 'https://via.placeholder.com/150',
          orderId: _order.id,
          authToken: _authToken!,
          currentUserId: _currentUserId!,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _order.formattedPrice,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_order.statusIcon, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  _order.statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF2E7D32), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    if (_order.customer == null) {
      return SizedBox();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.person, color: Colors.white, size: 20),
                radius: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order.customer!['fullName'] ?? 'Unknown Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_order.customer!['phone'] != null)
                      Text(
                        _order.customer!['phone'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    if (_order.customer!['email'] != null)
                      Text(
                        _order.customer!['email'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (_order.customer!['phone'] != null)
                IconButton(
                  onPressed: _contactCustomer,
                  icon: Icon(Icons.phone, color: Color(0xFF2E7D32)),
                  tooltip: 'Contact Customer',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    if (_order.timeline.isEmpty) {
      return SizedBox();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          ..._order.timeline.map((timelineItem) => _buildTimelineItem(timelineItem)).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(dynamic timelineItem) {
    final status = timelineItem['status'] ?? '';
    final note = timelineItem['note'] ?? '';
    final timestamp = timelineItem['timestamp'] != null
        ? DateTime.parse(timelineItem['timestamp']).toLocal()
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimelineStatusText(status),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                if (note.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  _formatDateTime(timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimelineStatusText(String status) {
    switch (status) {
      case 'requested': return 'Order Requested';
      case 'accepted': return 'Order Accepted by Agent';
      case 'in-progress': return 'Order In Progress';
      case 'completed': return 'Order Completed';
      case 'rejected': return 'Order Rejected';
      default: return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} • ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _buildActionButtons() {
    final availableStatuses = _getAvailableStatuses(_order.status);

    if (availableStatuses.isEmpty) {
      return SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _showStatusUpdateDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update, size: 20),
                  SizedBox(width: 8),
                  Text('Update Status'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    'Service Type',
                    _order.serviceCategory,
                    Icons.category,
                  ),
                  _buildInfoSection(
                    'Order Details',
                    _order.details,
                    Icons.description,
                  ),
                  _buildInfoSection(
                    'Location',
                    _order.location,
                    Icons.location_on,
                  ),
                  _buildInfoSection(
                    'Order Created',
                    _order.timeAgo,
                    Icons.access_time,
                  ),
                  SizedBox(height: 8),
                  _buildCustomerSection(),
                  _buildTimelineSection(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }
}