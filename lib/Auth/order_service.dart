import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/order_model.dart';
import 'auth_services.dart';

class OrderService {
  static const String baseUrl = "https://runpro9ja-pxqoa.ondigitalocean.app/api"; // ✅ FIXED: Added /api
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

  // Get direct offers to agent - WITH COMPREHENSIVE DEBUGGING
  Future<List<Order>> getDirectOffers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/direct-offers'; // ✅ FIXED: Removed /api from URL since it's in baseUrl now
      print('🔍 Fetching direct offers from: $url');
      print('🔑 Token available: ${token.isNotEmpty}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Direct offers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Direct offers response body: ${response.body}');

        // Debug the response structure
        print('🔍 Direct offers data structure:');
        print('   - data type: ${data.runtimeType}');
        print('   - data keys: ${data.keys}');

        List<dynamic> ordersList = [];

        if (data['orders'] != null && data['orders'] is List) {
          ordersList = data['orders'];
          print('   - Found orders in "orders" key: ${ordersList.length}');
        } else if (data['data'] != null && data['data']['orders'] != null && data['data']['orders'] is List) {
          ordersList = data['data']['orders'];
          print('   - Found orders in "data.orders" key: ${ordersList.length}');
        } else if (data is List) {
          ordersList = data;
          print('   - Data is direct list: ${ordersList.length}');
        } else {
          print('   - No orders found in expected keys');
          print('   - Available keys: ${data.keys}');
        }

        if (ordersList.isEmpty) {
          print('⚠️ No direct offers found in response');
          return [];
        }

        // Debug each order
        for (var order in ordersList) {
          print('   - Order: ${order['_id']}');
          print('     serviceCategory: ${order['serviceCategory']}');
          print('     requestedAgent: ${order['requestedAgent']}');
          print('     isDirectOffer: ${order['isDirectOffer']}');
          print('     status: ${order['status']}');
        }

        final orders = ordersList.map((order) {
          try {
            return Order.fromJson(order);
          } catch (e) {
            print('❌ Error parsing order: $e');
            print('❌ Problematic order data: $order');
            return null;
          }
        }).where((order) => order != null).cast<Order>().toList();

        print('✅ Successfully parsed ${orders.length} direct offers');
        return orders;
      } else {
        print('❌ Failed to load direct offers: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load direct offers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error fetching direct offers: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Get public orders - WITH COMPREHENSIVE DEBUGGING
  Future<List<Order>> getPublicOrders() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/public-orders'; // ✅ FIXED: Removed /api from URL
      print('🔍 Fetching public orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Public orders response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Public orders response body: ${response.body}');

        // Debug the response structure
        print('🔍 Public orders data structure:');
        print('   - data type: ${data.runtimeType}');
        print('   - data keys: ${data.keys}');

        List<dynamic> ordersList = [];

        if (data['orders'] != null && data['orders'] is List) {
          ordersList = data['orders'];
          print('   - Found orders in "orders" key: ${ordersList.length}');
        } else if (data['data'] != null && data['data']['orders'] != null && data['data']['orders'] is List) {
          ordersList = data['data']['orders'];
          print('   - Found orders in "data.orders" key: ${ordersList.length}');
        } else if (data is List) {
          ordersList = data;
          print('   - Data is direct list: ${ordersList.length}');
        } else {
          print('   - No orders found in expected keys');
          print('   - Available keys: ${data.keys}');
        }

        if (ordersList.isEmpty) {
          print('⚠️ No public orders found in response');
          return [];
        }

        // Debug each order
        for (var order in ordersList) {
          print('   - Order: ${order['_id']}');
          print('     serviceCategory: ${order['serviceCategory']}');
          print('     status: ${order['status']}');
        }

        final orders = ordersList.map((order) {
          try {
            return Order.fromJson(order);
          } catch (e) {
            print('❌ Error parsing order: $e');
            print('❌ Problematic order data: $order');
            return null;
          }
        }).where((order) => order != null).cast<Order>().toList();

        print('✅ Successfully parsed ${orders.length} public orders');
        return orders;
      } else {
        print('❌ Failed to load public orders: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load public orders: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error fetching public orders: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Get agent's assigned orders
  Future<List<Order>> getAgentOrders() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/agent/my-orders'; // ✅ FIXED: Removed /api from URL
      print('🔍 Fetching agent orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Agent orders response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Agent orders response body: ${response.body}');

        List<dynamic> ordersList = [];

        if (data['orders'] != null && data['orders'] is List) {
          ordersList = data['orders'];
        } else if (data['data'] != null && data['data']['orders'] != null && data['data']['orders'] is List) {
          ordersList = data['data']['orders'];
        } else if (data is List) {
          ordersList = data;
        }

        if (ordersList.isEmpty) {
          print('⚠️ No agent orders found');
          return [];
        }

        final orders = ordersList.map((order) {
          try {
            return Order.fromJson(order);
          } catch (e) {
            print('❌ Error parsing order: $e');
            return null;
          }
        }).where((order) => order != null).cast<Order>().toList();

        print('✅ Successfully parsed ${orders.length} agent orders');
        return orders;
      } else {
        print('❌ Failed to load agent orders: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load agent orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching agent orders: $e');
      rethrow;
    }
  }

  // Accept direct order - WITH DEBUGGING
  Future<bool> acceptDirectOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId/accept-direct'; // ✅ FIXED: Removed /api from URL
      print('✅ Accepting direct order: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Accept direct order response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error accepting direct order: $e');
      return false;
    }
  }

  // Accept public order - WITH DEBUGGING
  Future<bool> acceptPublicOrder(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId/accept-public'; // ✅ FIXED: Removed /api from URL
      print('✅ Accepting public order: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Accept public order response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error accepting public order: $e');
      return false;
    }
  }

  // Reject direct order - WITH DEBUGGING
  Future<bool> rejectDirectOrder(String orderId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId/reject-direct'; // ✅ FIXED: Removed /api from URL
      print('❌ Rejecting direct order: $url');
      print('   - Reason: $reason');

      final Map<String, dynamic> body = {};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📥 Reject direct order response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error rejecting direct order: $e');
      return false;
    }
  }

  // Reject public order - WITH DEBUGGING
  Future<bool> declinePublicOrder(String orderId, {String? reason}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId/decline-public'; // ✅ FIXED: Removed /api from URL
      print('❌ Declining public order: $url');
      print('   - Reason: $reason');

      final Map<String, dynamic> body = {};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📥 Decline public order response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error declining public order: $e');
      return false;
    }
  }

  // Update order status - WITH DEBUGGING
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId/status'; // ✅ FIXED: Removed /api from URL
      print('🔄 Updating order status: $url');
      print('   - New status: $status');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      print('📥 Update status response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  // Get order by ID - WITH DEBUGGING
  Future<Order?> getOrderById(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '$baseUrl/orders/$orderId'; // ✅ FIXED: Removed /api from URL
      print('🔍 Fetching order by ID: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Get order by ID response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Order data: ${response.body}');
        return Order.fromJson(data['order'] ?? data);
      } else {
        print('❌ Failed to fetch order: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching order: $e');
      return null;
    }
  }
}