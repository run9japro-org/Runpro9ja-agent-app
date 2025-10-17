// lib/screens/agent/forms/errand_profile_form.dart
import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Profile_screens/forms/uploading_img_screen.dart';
import '../../Auth/auth_services.dart';

class ErrandProfileForm extends StatefulWidget {
  const ErrandProfileForm({super.key});

  @override
  State<ErrandProfileForm> createState() => _ErrandProfileFormState();
}

class _ErrandProfileFormState extends State<ErrandProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _years = TextEditingController();
  final _services = TextEditingController();
  final _expertise = TextEditingController();
  final _availability = TextEditingController();
  final _summary = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      "serviceType": "Errand Service",
      "yearsOfExperience": _years.text.trim(),
      "servicesOffered": _services.text.trim(),
      "areasOfExpertise": _expertise.text.trim(),
      "availability": _availability.text.trim(),
      "summary": _summary.text.trim(),
    };
    final res = await AuthService().post('/api/agents/me', data);
    setState(() => _loading = false);

    if (res['statusCode'] == 200 || res['statusCode'] == 201) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profile created")));

      // ✅ fetch token
      final token = await AuthService().getToken();
      Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => UploadImageScreen(token: token ?? ''),
      ),

      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['body']['message'] ?? 'Error')));
    }
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Errand Service Profile"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Tell us about your experience 📝",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "This helps customers understand your skills and availability.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _years,
                decoration: _inputDecoration(
                  "Years of Experience",
                  "How many years have you been providing errand services?",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _services,
                decoration: _inputDecoration(
                  "Specific Services Offered",
                  "E.g. grocery shopping, delivery, running errands",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expertise,
                decoration: _inputDecoration(
                  "Areas of Expertise",
                  "E.g. time management, reliability, local knowledge",
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availability,
                decoration: _inputDecoration(
                  "Availability",
                  "E.g. weekdays, weekends, evenings",
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summary,
                decoration: _inputDecoration(
                  "Brief Summary",
                  "Write a short description about yourself",
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue",
                    style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
