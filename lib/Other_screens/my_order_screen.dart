// my_orders_screen.dart
import 'package:flutter/material.dart';
import '../Auth/order_service.dart';
import '../Model/order_model.dart';
import '../Auth/auth_services.dart';
import 'customer_agent_chats_screen.dart';
import 'order_details_screen.dart';// Make sure to import your chat screen

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService(AuthService());
  final AuthService _authService = AuthService();

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'active';
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final orders = await _orderService.getAgentOrders();

      // **DEBUG: Check all orders and their prices**
      print('🔄 LOADING ORDERS DEBUG:');
      print('   - Total orders fetched: ${orders.length}');

      // Calculate total earnings from completed orders - FIXED VERSION
      double completedEarnings = 0.0;
      int completedCount = 0;

      for (var order in orders) {
        print('   - Order ${order.id}: status=${order.status}, price=${order.price} (type: ${order.price.runtimeType})');

        if (order.status == 'completed') {
          completedCount++;

          // **FIXED: Ensure we're using the correct price**
          double orderPrice;
          if (order.price is int) {
            orderPrice = (order.price as int).toDouble();
          } else if (order.price is double) {
            orderPrice = order.price;
          } else if (order.price is String) {
            orderPrice = double.tryParse(order.price as String) ?? 0.0;
          } else {
            orderPrice = 0.0;
          }

          completedEarnings += orderPrice;
          print('     ✅ COMPLETED ORDER: Adding ₦$orderPrice (Total: ₦$completedEarnings)');
        }
      }

      print('💰 FINAL EARNINGS CALCULATION:');
      print('   - Completed orders: $completedCount');
      print('   - Total earnings: ₦$completedEarnings');

      setState(() {
        _allOrders = orders;
        _totalEarnings = completedEarnings;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR loading orders: $e');
      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'active':
        _filteredOrders = _allOrders.where((order) =>
        order.status == 'accepted' || order.status == 'in-progress'
        ).toList();
        break;
      case 'completed':
        _filteredOrders = _allOrders.where((order) =>
        order.status == 'completed'
        ).toList();
        break;
      case 'all':
      default:
        _filteredOrders = _allOrders;
        break;
    }
    _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  Future<void> _initializeAuth() async {
    await _authService.initializeCurrentUser();
    _checkAuthStatus(); // Debug info
  }
  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      final success = await _orderService.updateOrderStatus(order.id, newStatus);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadOrders();
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
  void _checkAuthStatus() {
    final currentUser = _authService.currentUser;
    final token = _authService.getToken();

    print('🔐 AUTH STATUS IN MY ORDERS:');
    print('   - Current user: ${currentUser?.id}');
    print('   - Current user name: ${currentUser?.name}');
    print('   - Token available: ${token != null}');
  }
  // ✅ ADD THIS: Method to open chat with customer
  // In MyOrdersScreen - update the _openChatWithCustomer method
  Future<void> _openChatWithCustomer(Order order) async {
    // Debug order info
    print('💬 CHAT DEBUG - Order Info:');
    print('   - Customer ID: ${order.customerId}');
    print('   - Customer Data: ${order.customer}');
    print('   - Customer Image: ${order.customer?['profileImage']}');
    print('   - Customer Image Type: ${order.customer?['profileImage'].runtimeType}');
    print('   - Order Status: ${order.status}');

    if (order.customer == null || order.customerId == 'unknown_customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer information not available'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check authentication using multiple methods
    final isLoggedIn = await _authService.isLoggedIn();
    final currentUser = _authService.currentUser;
    final token = await _authService.getToken();

    print('🔐 AUTH CHECK FOR CHAT:');
    print('   - Is logged in: $isLoggedIn');
    print('   - Current user: ${currentUser?.id}');
    print('   - Token available: ${token != null && token.isNotEmpty}');

    if (!isLoggedIn || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If currentUser is null but we have a token, try to get user data from token
    String userId;
    if (currentUser != null) {
      userId = currentUser.id;
    } else {
      final userData = await _authService.getUserData();
      userId = userData?['userId'] ?? userData?['id'] ?? '';

      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get user information. Please login again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // ✅ FIXED: Handle null customer image properly
    String customerImage = '';
    if (order.customer?['profileImage'] != null) {
      customerImage = order.customer!['profileImage'].toString();
      print('🖼️ Using customer profile image: $customerImage');
    } else {
      print('🖼️ No customer profile image found, using generated avatar');
    }

    print('🚀 OPENING CHAT:');
    print('   - User ID: $userId');
    print('   - Customer ID: ${order.customerId}');
    print('   - Customer Name: ${order.customer?['fullName']}');
    print('   - Customer Image: $customerImage');
    print('   - Order ID: ${order.id}');

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentCustomerChatScreen(
          customerId: order.customerId,
          customerName: order.customer?['fullName'] ?? 'Customer',
          customerImage: customerImage, // Use the processed image
          orderId: order.id,
          authToken: token,
          currentUserId: userId,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(Order order) {
    final availableStatuses = _getAvailableStatuses(order.status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) => ListTile(
            leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
            title: Text(_getStatusText(status)),
            onTap: () {
              Navigator.pop(context);
              _updateOrderStatus(order, status);
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
      case 'in-progress': return 'Mark as In Progress';
      case 'completed': return 'Mark as Completed';
      default: return status;
    }
  }

  Widget _buildStatsCard() {
    final activeOrders = _allOrders.where((order) =>
    order.status == 'accepted' || order.status == 'in-progress'
    ).length;

    final completedOrders = _allOrders.where((order) =>
    order.status == 'completed'
    ).length;

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatItem('Active', activeOrders.toString(), Colors.blue),
            _buildStatItem('Completed', completedOrders.toString(), Colors.green),
            _buildStatItem('Earnings', '₦${_totalEarnings.toStringAsFixed(0)}', Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and actions - UPDATED
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: order.statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(order.statusIcon, size: 14, color: order.statusColor),
                        SizedBox(width: 4),
                        Text(
                          order.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: order.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // **ADDED: Chat Button - Only show for active orders**
                      if ((order.status == 'accepted' || order.status == 'in-progress') && order.customerId != 'unknown_customer')
                        IconButton(
                          onPressed: () => _openChatWithCustomer(order),
                          icon: Icon(Icons.chat_outlined, size: 18),
                          tooltip: 'Chat with Customer',
                          color: Colors.blue,
                        ),
                      if (order.status == 'accepted' || order.status == 'in-progress')
                        IconButton(
                          onPressed: () => _showStatusUpdateDialog(order),
                          icon: Icon(Icons.edit, size: 18),
                          tooltip: 'Update Status',
                          color: Colors.grey[600],
                        ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                        icon: Icon(Icons.visibility_outlined, size: 20),
                        tooltip: 'View Details',
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Service Type and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.serviceCategory,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    order.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Order Details
              Text(
                order.details,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),

              // Location and Time
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    order.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),

              // Customer Info if available - UPDATED with chat hint
              if (order.customer != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Customer: ${order.customer!['fullName'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      if (order.customer!['phone'] != null) ...[
                        SizedBox(width: 8),
                        Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          order.customer!['phone'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                      // **ADDED: Chat hint for active orders**
                      if (order.status == 'accepted' || order.status == 'in-progress') ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat, size: 10, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Chat available',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Active', 'active'),
            SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
            SizedBox(width: 8),
            _buildFilterChip('All Orders', 'all'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      selectedColor: Color(0xFF2E7D32),
      labelStyle: TextStyle(
        color: _selectedFilter == value ? Colors.white : Colors.grey[700],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              _selectedFilter == 'active'
                  ? 'No Active Orders'
                  : _selectedFilter == 'completed'
                  ? 'No Completed Orders'
                  : 'No Orders Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _selectedFilter == 'active'
                  ? 'Accepted orders will appear here'
                  : 'Start accepting orders to build your history',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      backgroundColor: Colors.white,
      color: Color(0xFF2E7D32),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 8),
        children: _filteredOrders.map((order) => _buildOrderCard(order)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text(
              'Loading your orders...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Orders',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildStatsCard(),
          SizedBox(height: 8),
          _buildFilterChips(),
          SizedBox(height: 16),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }
}