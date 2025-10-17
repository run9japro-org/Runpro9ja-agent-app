// lib/services/agent_services.dart - UPDATED
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/professional_order_model.dart';
import '../auth/auth_services.dart'; // Use your existing model

class AgentService {
  final AuthService authService;
  static const String baseUrl = "https://runpro9ja-backend.onrender.com";

  AgentService(this.authService);

  // Get professional orders for representatives
  Future<List<ProfessionalOrder>> getProfessionalOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/professional'),
        headers: headers,
      );

      print('🔄 Fetching professional orders...');
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