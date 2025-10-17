import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Auth/auth_services.dart';
import '../Model/order_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final AuthService _authService = AuthService();
  DateTime _selectedDate = DateTime.now();
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  List<Order> _todaysOrders = [];
  List<Order> _upcomingOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String _error = '';
  String _activeTab = 'today'; // 'today' or 'upcoming'

  @override
  void initState() {
    super.initState();
    _loadTodaysSchedule();
  }

  Future<void> _loadTodaysSchedule() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
        _activeTab = 'today';
      });

      final response = await _makeApiCall('/orders/agent/schedule/today');
      if (response['success'] == true) {
        final List<dynamic> ordersData = response['orders'] ?? response['data'] ?? [];
        setState(() {
          _todaysOrders = ordersData.map((order) => Order.fromJson(order)).toList();
          _filteredOrders = _todaysOrders;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load today\'s schedule');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load schedule: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingSchedule() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
        _activeTab = 'upcoming';
      });

      final response = await _makeApiCall('/orders/agent/schedule/upcoming');
      if (response['success'] == true) {
        final List<dynamic> ordersData = response['orders'] ?? response['data'] ?? [];
        setState(() {
          _upcomingOrders = ordersData.map((order) => Order.fromJson(order)).toList();
          _filteredOrders = _upcomingOrders;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load upcoming schedule');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load upcoming schedule: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _makeApiCall(String endpoint) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('https://runpro9ja-backend.onrender.com/api$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('API call failed: ${response.statusCode}');
    }
  }

  List<String> get _weekDays => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _getFirstDayOfWeek(int year, int month) {
    DateTime firstDay = DateTime(year, month, 1);
    return firstDay.weekday - 1; // Monday = 0
  }

  bool _hasScheduledOrders(int day) {
    final ordersToCheck = _activeTab == 'today' ? _todaysOrders : _upcomingOrders;
    if (ordersToCheck.isEmpty) return false;

    return ordersToCheck.any((order) {
      final orderDate = order.scheduledDate ?? order.createdAt;
      return orderDate.year == _currentYear &&
          orderDate.month == _currentMonth &&
          orderDate.day == day;
    });
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = _getDaysInMonth(_currentYear, _currentMonth);
    int firstDayOfWeek = _getFirstDayOfWeek(_currentYear, _currentMonth);

    List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of month
    for (int i = 0; i < firstDayOfWeek; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      bool isSelected = day == _selectedDate.day &&
          _currentMonth == _selectedDate.month &&
          _currentYear == _selectedDate.year;

      bool hasOrders = _hasScheduledOrders(day);
      bool isToday = day == DateTime.now().day &&
          _currentMonth == DateTime.now().month &&
          _currentYear == DateTime.now().year;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(_currentYear, _currentMonth, day);
            });
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E7D32) :
              isToday ? Colors.green.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasOrders ? const Color(0xFF2E7D32) :
                isToday ? Colors.green.shade300 : Colors.transparent,
                width: hasOrders ? 2 : (isToday ? 1.5 : 0),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white :
                      isToday ? Colors.green.shade700 : Colors.black,
                      fontWeight: isSelected ? FontWeight.w600 :
                      isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasOrders && !isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 8,
      children: dayWidgets,
    );
  }

  Widget _buildScheduleItem(Order order) {
    final customerName = order.customer?['fullName'] ??
        order.customer?['firstName'] ??
        'Customer ${order.customerId.substring(0, 8)}';

    final scheduledTime = order.scheduledDate ?? order.createdAt;
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE dd MMMM');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showOrderDetails(order);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade100, Colors.green.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.serviceCategory,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${timeFormat.format(scheduledTime)} • ${dateFormat.format(scheduledTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: order.statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.statusIcon,
                        size: 12,
                        color: order.statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: order.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _loadTodaysSchedule,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _activeTab == 'today' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'today' ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _activeTab == 'today' ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _loadUpcomingSchedule,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _activeTab == 'upcoming' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _activeTab == 'upcoming' ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _activeTab == 'upcoming' ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(Order order) {
    final customerName = order.customer?['fullName'] ??
        order.customer?['firstName'] ??
        'Customer ${order.customerId.substring(0, 8)}';
    final customerPhone = order.customer?['phone'] ?? 'Not provided';
    final scheduledTime = order.scheduledDate ?? order.createdAt;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeTab == 'today' ? "Today's Schedule" : 'Upcoming Schedule',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEE, MMM d, y').format(scheduledTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: order.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: order.statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(order.statusIcon, color: order.statusColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            order.statusText,
                            style: TextStyle(
                              color: order.statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.build_circle_outlined, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'Service Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Service Type', order.serviceCategory),
                        _buildDetailRow('Scheduled Time', DateFormat('h:mm a').format(scheduledTime)),
                        _buildDetailRow('Date', DateFormat('EEE, MMM d, y').format(scheduledTime)),
                        _buildDetailRow('Location', order.location),
                        if (order.details.isNotEmpty)
                          _buildDetailRow('Description', order.details),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'Customer Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Name', customerName),
                        if (customerPhone != 'Not provided')
                          _buildDetailRow('Phone', customerPhone),
                        _buildDetailRow('Amount', order.formattedPrice),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _activeTab == 'today'
        ? "You have no services scheduled for today"
        : "You have no upcoming services scheduled";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 50,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _activeTab == 'today' ? 'No Services Today' : 'No Upcoming Services',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _activeTab == 'today' ? _loadTodaysSchedule : _loadUpcomingSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.green.shade700),
            onPressed: _activeTab == 'today' ? _loadTodaysSchedule : _loadUpcomingSchedule,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () {
                        setState(() {
                          if (_currentMonth == 1) {
                            _currentMonth = 12;
                            _currentYear--;
                          } else {
                            _currentMonth--;
                          }
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM y').format(DateTime(_currentYear, _currentMonth)),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () {
                        setState(() {
                          if (_currentMonth == 12) {
                            _currentMonth = 1;
                            _currentYear++;
                          } else {
                            _currentMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays
                      .map((day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildCalendarGrid(),
              ],
            ),
          ),

          // Tab Header
          _buildTabHeader(),

          // Schedule List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _activeTab == 'today' ? "Today's Services" : 'Upcoming Services',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredOrders.length} services',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Schedule List
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Loading schedule...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : _error.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _activeTab == 'today' ? _loadTodaysSchedule : _loadUpcomingSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _activeTab == 'today' ? _loadTodaysSchedule : _loadUpcomingSchedule,
              color: Colors.green,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filteredOrders
                    .map((order) => _buildScheduleItem(order))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}