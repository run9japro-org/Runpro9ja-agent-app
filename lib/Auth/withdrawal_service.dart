import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:runpro9ja_agent/Auth/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/withdrawal_model.dart';

class WithdrawalService {
  final String baseUrl = AuthService().baseUrl; // e.g., https://your-backend.com/api

  // 🔹 Request a withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required String token,
    required double amount,
    required String bankCode,
    required String accountNumber,
  }) async {
    final url = Uri.parse('$baseUrl/api/withdrawals/request');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'bankCode': bankCode,
        'accountNumber': accountNumber,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Withdrawal failed');
    }
  }

  // 🔹 Fetch all my withdrawals
  Future<List<WithdrawalModel>> getMyWithdrawals(String token) async {
    final url = Uri.parse('$baseUrl/withdrawals/my');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => WithdrawalModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch withdrawals');
    }
  }
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  Future<Map<String, dynamic>> addBankAccount(Map<String, dynamic> bankData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/api/agents/add-bank');

      print('🔐 Token being used: ${token.substring(0, 20)}...');
      print('📤 Bank Data: $bankData');
      print('🌐 URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bankData),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Bank account added successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? responseData['message'] ?? 'Failed to add bank account',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in addBankAccount: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get bank accounts list
  Future<Map<String, dynamic>> getBankAccounts() async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/api/agents/banks');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch bank accounts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
