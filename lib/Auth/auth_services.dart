// auth_services.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl = "https://runpro9ja-pxqoa.ondigitalocean.app";
  User? _currentUser;

  Future<void> initializeCurrentUser() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final userData = await _decodeToken(token);
        _currentUser = User(
          id: userData['userId'] ?? userData['id'] ?? '',
          token: token,
          email: userData['email'] ?? '',
          name: userData['name'] ?? userData['fullName'] ?? 'User',
        );
        print('✅ Current user initialized: ${_currentUser?.id}');
      } catch (e) {
        print('❌ Error initializing current user: $e');
      }
    }
  }
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/auth/register");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    final result = jsonDecode(response.body);

    if (response.statusCode == 200 && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwtToken', result['token']);
      print("Saved token: ${result['token']}");

      // Initialize current user after login
      await initializeCurrentUser();
    }

    return result;
  }

  // Make sure currentUser getter exists
  User? get currentUser {
    return _currentUser;
  }

  // Add this method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }


  Future<Map<String, dynamic>> verifyOtp(String userId, String otp) async {
    final url = Uri.parse("$baseUrl/api/auth/verify-otp");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "code": otp}),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final token = await _getToken();
    final normalizedPath = path.startsWith("/") ? path : "/$path";
    final url = Uri.parse('$baseUrl$normalizedPath');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    print("➡️ GET $url");
    print("➡️ Headers: $headers");

    final res = await http.get(url, headers: headers);

    print("⬅️ Status: ${res.statusCode}");
    print("⬅️ Response: ${res.body}");

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    return {
      'statusCode': res.statusCode,
      'body': body,
    };
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }
// ✅ ADD DELETE METHOD HERE
  Future<Map<String, dynamic>> delete(String path, Map<String, dynamic> data) async {
    final token = await _getToken();
    final normalizedPath = path.startsWith("/") ? path : "/$path";
    final url = Uri.parse('$baseUrl$normalizedPath');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    print("➡️ DELETE $url");
    print("➡️ Headers: $headers");
    print("➡️ Body: $data");

    final res = await http.delete(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print("⬅️ Status: ${res.statusCode}");
    print("⬅️ Response: ${res.body}");

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    return {
      'statusCode': res.statusCode,
      'body': body,
    };
  }
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final token = await _getToken();
    final normalizedPath = path.startsWith("/") ? path : "/$path";
    final url = Uri.parse('$baseUrl$normalizedPath');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    print("➡️ POST $url");
    print("➡️ Headers: $headers");
    print("➡️ Body: $data");

    final res = await http.post(url, headers: headers, body: jsonEncode(data));

    print("⬅️ Status: ${res.statusCode}");
    print("⬅️ Response: ${res.body}");

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    return {
      'statusCode': res.statusCode,
      'body': body,
    };
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/api/agents/upload-profile');

    final request = http.MultipartRequest("POST", url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath("profileImage", imageFile.path));

    print("➡️ Uploading image to $url");
    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    print("⬅️ Status: ${res.statusCode}");
    print("⬅️ Response: ${res.body}");

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    return {
      'statusCode': res.statusCode,
      'body': body,
    };
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return await _decodeToken(token);
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _decodeToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final payload = parts[1];
      String padded = payload;
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      final decoded = utf8.decode(base64Url.decode(padded));
      final Map<String, dynamic> data = json.decode(decoded);
      return data;
    } catch (e) {
      print('Error decoding token: $e');
      return {};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    _currentUser = null;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await get('api/customers/me');
      if (response['statusCode'] == 200) {
        return response['body'];
      } else {
        return {};
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return {};
    }
  }

  // ✅ ADD THIS: Get current user with proper initialization


}

class User {
  final String id;
  final String token;
  final String email;
  final String name;

  User({
    required this.id,
    required this.token,
    required this.email,
    required this.name,
  });
}

class AgentProfileService {
  static const String baseUrl = 'https://runpro9ja-backend.onrender.com/api';

  static Future<Map<String, dynamic>> getAgentProfile() async {
    try {
      // Use GET instead of POST
      final response = await AuthService().get('api/agents/me');
      if (response['statusCode'] == 200) {
        return response['body'];
      } else {
        return {};
      }
    } catch (e) {
      print('Error getting agent profile: $e');
      return {};
    }
  }
  // Create or update agent profile
  static Future<Map<String, dynamic>> createOrUpdateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/agents/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(profileData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      final token = await AuthService().getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/agents/upload-profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage',
        imagePath,
      ));

      var response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}