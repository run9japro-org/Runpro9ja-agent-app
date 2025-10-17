// lib/screens/representative/professional_orders_screen.dart - UPDATED
import 'package:flutter/material.dart';

import '../../auth/auth_services.dart';
// Use your existing model
import '../Model/professional_order_model.dart';
import '../Services/Agentservice.dart';
import 'quotation_submission_screen.dart';

class ProfessionalOrdersScreen extends StatefulWidget {
  const ProfessionalOrdersScreen({super.key});

  @override
  State<ProfessionalOrdersScreen> createState() => _ProfessionalOrdersScreenState();
}

class _ProfessionalOrdersScreenState extends State<ProfessionalOrdersScreen> {
  final AuthService _authService = AuthService();
  late final AgentService _agentService;
  List<ProfessionalOrder> _professionalOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _agentService = AgentService(_authService);
    _loadProfessionalOrders();
  }

  Future<void> _loadProfessionalOrders() async {
    try {
      print('🔄 Loading professional orders...');
      final orders = await _agentService.getProfessionalOrders();
      setState(() {
        _professionalOrders = orders;
        _isLoading = false;
      });
      print('✅ Loaded ${orders.length} professional orders');
    } catch (e) {
      print('❌ Error loading professional orders: $e');
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToQuotationScreen(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationSubmissionScreen(orderId: orderId),
      ),
    ).then((_) => _loadProfessionalOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Orders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _professionalOrders.isEmpty
          ? const Center(child: Text('No professional orders available'))
          : RefreshIndicator(
        onRefresh: _loadProfessionalOrders,
        child: ListView.builder(
          itemCount: _professionalOrders.length,
          itemBuilder: (context, index) {
            final order = _professionalOrders[index];
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(ProfessionalOrder order) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.engineering, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.serviceCategory,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Location: ${order.location}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            if (order.customerName != null) ...[
              Text(
                'Customer: ${order.customerName}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Description: ${order.description}',
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(order.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (order.status == 'requested')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToQuotationScreen(order.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Quotation'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'quotation_provided':
        return Colors.blue;
      case 'quotation_accepted':
        return Colors.green;
      case 'agent_selected':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}