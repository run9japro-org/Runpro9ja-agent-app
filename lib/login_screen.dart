import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
// REMOVED: import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'representative/professional_orders_screen.dart';
import 'Other_screens/forget_password.dart';

class AgentLoginPage extends StatefulWidget {
  const AgentLoginPage({super.key});

  @override
  State<AgentLoginPage> createState() => _AgentLoginPageState();
}

class _AgentLoginPageState extends State<AgentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final LocalAuthentication _localAuth = LocalAuthentication();
  // REMOVED: final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _canCheckBiometrics = false;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final prefs = await SharedPreferences.getInstance();
      final hasCredentials = prefs.containsKey('agent_email') && prefs.containsKey('agent_password');

      setState(() {
        _canCheckBiometrics = canAuthenticate;
        _hasStoredCredentials = hasCredentials;
      });

      print("🔐 Biometric available: $_canCheckBiometrics");
      print("📦 Stored credentials: $_hasStoredCredentials");
    } catch (e) {
      print("❌ Biometric check failed: $e");
    }
  }

  // Decode token to extract role
  String _getUserRoleFromToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      return decodedToken['role']?.toString().toLowerCase() ?? 'agent';
    } catch (e) {
      print("Token decode error: $e");
      return 'agent';
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_canCheckBiometrics || !_hasStoredCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No saved credentials or biometrics unavailable.")),
      );
      return;
    }

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your RunPro 9ja account',
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: false,
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('agent_email');
        final password = prefs.getString('agent_password');

        if (email != null && password != null) {
          _emailController.text = email;
          _passwordController.text = password;
          _loginAgent(fromBiometric: true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication failed")),
        );
      }
    } catch (e) {
      print("❌ Biometric auth error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _loginAgent({bool fromBiometric = false}) async {
    if (!fromBiometric && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("https://runpro9ja-pxqoa.ondigitalocean.app/api/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["token"] != null) {
        final token = data["token"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwtToken", token);

        // Save credentials for biometric login next time
        if (!fromBiometric) {
          await prefs.setString('agent_email', _emailController.text.trim());
          await prefs.setString('agent_password', _passwordController.text.trim());
        }

        final userRole = _getUserRoleFromToken(token);
        if (!mounted) return;

        if (userRole == 'representative') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfessionalOrdersScreen()),
          );
        } else {
          final profileRes = await http.get(
            Uri.parse("https://runpro9ja-pxqoa.ondigitalocean.app/api/agents/me"),
            headers: {"Authorization": "Bearer $token"},
          );

          if (profileRes.statusCode == 200) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pushReplacementNamed(context, '/selection');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Login failed")),
        );
      }
    } catch (e) {
      print("❌ Login error: $e");
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
                Image.asset('assets/img.png', width: 100, height: 100),
                const SizedBox(height: 12),
                Text(
                  "Agent Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 30),

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
                  validator: (value) => value!.isEmpty ? "Enter your email" : null,
                ),
                const SizedBox(height: 16),

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
                  validator: (value) => value!.isEmpty ? "Enter your password" : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                      );
                    },
                    child: const Text("Forgot Password?", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 20),

                // Login button
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
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                        : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // Biometric login button
                if (_canCheckBiometrics && _hasStoredCredentials)
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 48, color: Colors.green),
                    onPressed: _authenticateWithBiometrics,
                  ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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