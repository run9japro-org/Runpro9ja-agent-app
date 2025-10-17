import 'package:flutter/material.dart';
import '../Auth/order_service.dart';
import '../Model/order_model.dart';

import '../Auth/auth_services.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService(AuthService());

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'active'; // active, completed, all
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final orders = await _orderService.getAgentOrders();

      // Calculate total earnings from completed orders
      final completedEarnings = orders
          .where((order) => order.status == 'completed')
          .fold(0.0, (sum, order) => sum + order.price);

      setState(() {
        _allOrders = orders;
        _totalEarnings = completedEarnings;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
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
        await _loadOrders(); // Refresh the list
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
              // Header with status and actions
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

              // Customer Info if available
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
                      Text(
                        'Customer: ${order.customer!['fullName'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (order.customer!['phone'] != null) ...[
                        SizedBox(width: 12),
                        Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          order.customer!['phone'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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