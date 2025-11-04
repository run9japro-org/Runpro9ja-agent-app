// lib/services/agent_services.dart - CORRECTED TO MATCH YOUR ROUTES
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/professional_order_model.dart';
import '../auth/auth_services.dart';

class AgentService {
  final AuthService authService;
  static const String baseUrl = "https://runpro9ja-pxqoa.ondigitalocean.app";

  AgentService(this.authService);

  // Get direct offers for agents - CORRECTED ENDPOINT
  Future<List<dynamic>> getDirectOffers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/direct-offers'), // Matches your route
        headers: headers,
      );

      print('🔄 Fetching direct offers from: $baseUrl/api/orders/direct-offers');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        throw Exception('Failed to load direct offers: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting direct offers: $e');
      rethrow;
    }
  }

  // Accept a direct offer - CORRECTED ENDPOINT
  Future<Map<String, dynamic>> acceptDirectOffer(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/accept-direct'), // Matches your route
        headers: headers,
      );

      print('🔄 Accepting direct offer: $baseUrl/api/orders/$orderId/accept-direct');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to accept direct offer: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accepting direct offer: $e');
      rethrow;
    }
  }

  // Reject a direct offer - CORRECTED ENDPOINT
  Future<Map<String, dynamic>> rejectDirectOffer(String orderId, {String? reason}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/reject-direct'), // Matches your route
        headers: headers,
        body: json.encode({'reason': reason ?? 'Not available'}),
      );

      print('🔄 Rejecting direct offer: $baseUrl/api/orders/$orderId/reject-direct');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reject direct offer: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error rejecting direct offer: $e');
      rethrow;
    }
  }

  // Get public orders - CORRECTED ENDPOINT
  Future<List<dynamic>> getPublicOrders({String? serviceType}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/api/orders/public-orders'; // Matches your route
      if (serviceType != null) {
        url += '?serviceType=$serviceType';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🔄 Fetching public orders from: $url');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        throw Exception('Failed to load public orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting public orders: $e');
      rethrow;
    }
  }

  // Accept a public order - CORRECTED ENDPOINT
  Future<Map<String, dynamic>> acceptPublicOrder(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/accept-public'), // Matches your route
        headers: headers,
      );

      print('🔄 Accepting public order: $baseUrl/api/orders/$orderId/accept-public');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to accept public order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accepting public order: $e');
      rethrow;
    }
  }

  // Get agent's accepted orders - CORRECTED ENDPOINT
  Future<List<dynamic>> getMyAcceptedOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/agent/my-orders'), // Matches your route
        headers: headers,
      );

      print('🔄 Fetching accepted orders from: $baseUrl/api/orders/agent/my-orders');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        throw Exception('Failed to load accepted orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting accepted orders: $e');
      rethrow;
    }
  }

  // Get agent service history - CORRECTED ENDPOINT
  Future<List<dynamic>> getAgentServiceHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/agent/history'), // Matches your route
        headers: headers,
      );

      print('🔄 Fetching agent history from: $baseUrl/api/orders/agent/history');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['orders'] ?? [];
      } else {
        throw Exception('Failed to load agent history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting agent history: $e');
      rethrow;
    }
  }

  // Get today's schedule - CORRECTED ENDPOINT
  Future<List<dynamic>> getTodaysSchedule() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/agent/schedule/today'), // Matches your route
        headers: headers,
      );

      print('🔄 Fetching today\'s schedule from: $baseUrl/api/orders/agent/schedule/today');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['schedule'] ?? [];
      } else {
        throw Exception('Failed to load today\'s schedule: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting today\'s schedule: $e');
      rethrow;
    }
  }

  // Update order status - CORRECTED ENDPOINT
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      final headers = await _getHeaders();

      final requestData = {
        'status': status,
        if (note != null) 'note': note,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/status'), // Matches your route
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔄 Updating order status: $baseUrl/api/orders/$orderId/status');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status: ${response.statusCode}');
      }

      print('✅ Order status updated to: $status');
    } catch (e) {
      print('❌ Error updating order status: $e');
      rethrow;
    }
  }

  // Get professional orders for representatives
  Future<List<ProfessionalOrder>> getProfessionalOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/professional'),
        headers: headers,
      );

      print('🔄 Fetching professional orders from: $baseUrl/api/orders/professional');
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ordersData = data['orders'] ?? [];
        print('✅ Found ${ordersData.length} professional orders');

        return ordersData.map((order) => ProfessionalOrder.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load professional orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting professional orders: $e');
      rethrow;
    }
  }

  // Submit quotation for professional order
  Future<void> submitQuotation({
    required String orderId,
    required double quotationAmount,
    required String quotationDetails,
    List<String> recommendedAgents = const [],
  }) async {
    try {
      final headers = await _getHeaders();

      final requestData = {
        'quotationAmount': quotationAmount,
        'quotationDetails': quotationDetails,
        'recommendedAgents': recommendedAgents,
      };

      print('🔄 Submitting quotation for order: $orderId');
      print('📦 Quotation data: $requestData');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/orders/$orderId/submit-quotation'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('📡 Quotation response: ${response.statusCode}');
      print('📡 Quotation body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to submit quotation');
      }

      print('✅ Quotation submitted successfully');
    } catch (e) {
      print('❌ Error submitting quotation: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}