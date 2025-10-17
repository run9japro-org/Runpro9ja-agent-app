import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/order_model.dart';
import 'auth_services.dart';

class OrderService {
  static const String baseUrl = "https://runpro9ja-pxqoa.ondigitalocean.app"
      "";
  final AuthService authService;

  OrderService(this.authService);

  Future<String?> _getToken() async {
    try {
      return await authService.getToken();
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get direct offers to agent
  Future<List<Order>> getDirectOffers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/direct-offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load direct offers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching direct offers: $e');
      rethrow;
    }
  }

  // Get public orders
  Future<List<Order>> getPublicOrders() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/public-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load public orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching public orders: $e');
      rethrow;
    }
  }

  // Get agent's assigned orders
  Future<List<Order>> getAgentOrders() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/agent/my-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load agent orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching agent orders: $e');
      rethrow;
    }
  }

  // Accept direct order
  Future<bool> acceptDirectOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/accept-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting direct order: $e');
      return false;
    }
  }

  // Accept public order
  Future<bool> acceptPublicOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/accept-public'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting public order: $e');
      return false;
    }
  }

  // ✅ NEW: Reject direct order
  Future<bool> rejectDirectOrder(String orderId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final Map<String, dynamic> body = {};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/reject-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting direct order: $e');
      return false;
    }
  }

// ✅ NEW: Reject public order (if agent wants to decline seeing it again)
  Future<bool> declinePublicOrder(String orderId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final Map<String, dynamic> body = {};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      // This would be a custom endpoint you might want to create
      // For now, we'll use the same pattern as reject-direct
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/reject-direct'), // Using same endpoint for now
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error declining public order: $e');
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data['order']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }
}