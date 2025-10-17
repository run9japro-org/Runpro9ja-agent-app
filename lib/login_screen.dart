import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package

// Import your screens
import 'Representative/professional_orders_screen.dart';
import 'representative/professional_orders_screen.dart' hide ProfessionalOrdersScreen; // Add this import

class AgentLoginPage extends StatefulWidget {
  const AgentLoginPage({super.key});

  @override
  State<AgentLoginPage> createState() => _AgentLoginPageState();
}

class _AgentLoginPageState extends State<AgentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Function to decode JWT and get user role
  String _getUserRoleFromToken(String token) {
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['role']?.toString() ?? 'agent';
    } catch (e) {
      print('Error decoding token: $e');
      return 'agent';
    }
  }

  // Function to get user data from token
  Map<String, dynamic> _getUserDataFromToken(String token) {
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return {
        'id': decodedToken['id']?.toString(),
        'role': decodedToken['role']?.toString() ?? 'agent',
        'fullName': decodedToken['fullName']?.toString(),
        'email': decodedToken['email']?.toString(),
      };
    } catch (e) {
      print('Error decoding user data: $e');
      return {};
    }
  }

  Future<void> _loginAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("https://runpro9ja-pxqoa.ondigitalocean.app/api/auth/login");

      print('🌐 Making request to: $url');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["token"] != null) {
        final token = data["token"];

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwtToken", token);
        print("✅ Token saved successfully");

        // Get user role from token
        final userRole = _getUserRoleFromToken(token);
        final userData = _getUserDataFromToken(token);

        print('👤 User Role: $userRole');
        print('👤 User Data: $userData');

        if (!mounted) return;

        // 🔥 REPRESENTATIVE REDIRECT LOGIC
        if (userRole == 'representative') {
          print('🎯 Representative detected - redirecting to Professional Orders');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalOrdersScreen(),
            ),
          );
          return; // Important: Stop further execution
        }

        // 🔥 REGULAR AGENT LOGIC (existing flow)
        print('🎯 Regular agent - checking profile completion');

        // Check if profile/service is completed
        final profileRes = await http.get(
          Uri.parse("https://runpro9ja-backend.onrender.com/api/agents/me"),
          headers: {"Authorization": "Bearer $token"},
        );

        print('📊 Profile check status: ${profileRes.statusCode}');

        if (profileRes.statusCode == 200) {
          // ✅ Profile exists → Dashboard
          print('✅ Profile exists - redirecting to main dashboard');
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          // ❌ No profile yet → Service Selection
          print('❌ No profile - redirecting to service selection');
          Navigator.pushReplacementNamed(context, '/selection');
        }

      } else {
        // Login failed - show specific error message
        String errorMessage = data["message"] ?? "Login failed";
        if (response.statusCode == 404) {
          errorMessage = "User not found";
        } else if (response.statusCode == 401) {
          errorMessage = "Invalid password";
        } else if (response.statusCode == 403) {
          errorMessage = "Account not verified";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('❌ Full error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset('assets/img.png', width: 100, height: 100),
                const SizedBox(height: 12),

                // Welcome Text
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter your email" : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                  value!.isEmpty ? "Enter your password" : null,
                ),
                const SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?",
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                    onPressed: _isLoading ? null : _loginAgent,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Signup Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}