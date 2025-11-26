import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Auth/auth_services.dart';
import '../termsandcondition.dart';
import 'otp_screen.dart';
import 'package:flutter/gestures.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedCountryCode = '+234'; // Default to Nigeria

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'dob': TextEditingController(),
    'location': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  // Popular country codes
  final List<Map<String, String>> _countryCodes = [
    {'code': '+234', 'country': 'Nigeria', 'flag': '🇳🇬'},
    {'code': '+1', 'country': 'USA/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+233', 'country': 'Ghana', 'flag': '🇬🇭'},
    {'code': '+254', 'country': 'Kenya', 'flag': '🇰🇪'},
    {'code': '+27', 'country': 'South Africa', 'flag': '🇿🇦'},
  ];

  // Popular Nigerian cities for autocomplete
  final List<String> _nigerianCities = [
    'Lagos',
    'Abuja',
    'Kano',
    'Ibadan',
    'Port Harcourt',
    'Benin City',
    'Kaduna',
    'Enugu',
    'Abeokuta',
    'Jos',
    'Ilorin',
    'Warri',
    'Aba',
    'Calabar',
    'Onitsha',
  ];

  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    // Add listener to phone controller to format input
    _controllers['phone']!.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Format phone number to remove leading 0 and ensure proper format
  void _formatPhoneNumber() {
    final text = _controllers['phone']!.text;

    if (text.isNotEmpty) {
      // Remove any non-digit characters
      String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

      // Remove leading 0 if present
      if (digitsOnly.startsWith('0')) {
        digitsOnly = digitsOnly.substring(1);
      }

      // Limit to 10 digits
      if (digitsOnly.length > 10) {
        digitsOnly = digitsOnly.substring(0, 10);
      }

      // Update the controller if the text has changed
      if (digitsOnly != text) {
        _controllers['phone']!.value = TextEditingValue(
          text: digitsOnly,
          selection: TextSelection.collapsed(offset: digitsOnly.length),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = AuthService();

    try {
      // Convert date from DD/MM/YYYY to YYYY-MM-DD format
      final dobText = _controllers['dob']!.text.trim();
      final dobParts = dobText.split('/');
      final formattedDob = '${dobParts[2]}-${dobParts[1]}-${dobParts[0]}';

      // Get the cleaned phone number (without leading 0)
      final phoneDigits = _controllers['phone']!.text.trim();

      // Combine country code with phone number
      final fullPhoneNumber = '$_selectedCountryCode$phoneDigits';

      final data = {
        "role": "agents",
        "fullName": _controllers['name']!.text.trim(),
        "email": _controllers['email']!.text.trim(),
        "phone": fullPhoneNumber, // Full international number
        "password": _controllers['password']!.text.trim(),
        "location": _controllers['location']!.text.trim(),
        "dob": formattedDob,
      };

      print('Sending data: $data');

      final response = await authService.register(data);

      if (response['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(userId: response['userId']),
          ),
        ).then((_) {
          _controllers.forEach((_, controller) => controller.clear());
        });

        if (!mounted) return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Signup failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Fill in your details to get started",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _controllers['name']!,
                        hint: "First name, last name",
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['dob']!,
                        hint: "Date of birth (DD/MM/YYYY)",
                        prefixIcon: Icons.calendar_today,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      _buildLocationField(),
                      const SizedBox(height: 16),
                      _buildPhoneField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['email']!,
                        hint: "Email address",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['password']!,
                        hint: "Password",
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    children: [
                      const TextSpan(
                          text: "By clicking continue, you are agreeing to our "),
                      TextSpan(
                        text: "Terms of Service",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const TermsAndConditionsScreen(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Phone field with country code selector
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country code info
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                "Selected: $_selectedCountryCode",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Format: ${_selectedCountryCode}XXXXXXXXXX",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code dropdown
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: _countryCodes.map((country) {
                  return DropdownMenuItem<String>(
                    value: country['code'],
                    child: Row(
                      children: [
                        Text(
                          country['flag']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          country['code']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Phone number input
            Expanded(
              child: TextFormField(
                controller: _controllers['phone']!,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter phone number";
                  }
                  if (value.length < 10) {
                    return "Phone number must be 10 digits (without 0)";
                  }
                  // Check if user tried to enter with leading 0
                  if (value.startsWith('0')) {
                    return "Do not include leading 0. Enter 10 digits only";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Enter 10-digit number",
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green[700]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  // Helper text to show the full number format
                  suffixIcon: _controllers['phone']!.text.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '→ $_selectedCountryCode${_controllers['phone']!.text}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : null,
                ),
              ),
            ),
          ],
        ),
        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Enter your 10-digit phone number without the leading 0",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  // Location field with autocomplete
  Widget _buildLocationField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _nigerianCities.where((String city) {
          return city.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _controllers['location']!.text = selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        // Sync the autocomplete controller with our main controller
        fieldTextEditingController.text = _controllers['location']!.text;
        fieldTextEditingController.addListener(() {
          _controllers['location']!.text = fieldTextEditingController.text;
        });

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter location";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Location (e.g Lagos)",
            prefixIcon:
            const Icon(Icons.location_on_outlined, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter ${hint.toLowerCase()}";
        }
        if (hint.toLowerCase().contains('email') &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return "Please enter a valid email address";
        }
        if (hint.toLowerCase().contains('password') && value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[700]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700]!,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      _controllers['dob']!.text = formattedDate;
    }
  }
}