// lib/screens/agent/forms/professional_profile_form.dart
import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Auth/auth_services.dart';
import 'package:runpro9ja_agent/Profile_screens/forms/uploading_img_screen.dart';
class ProfessionalProfileForm extends StatefulWidget {
  final String subCategory;
  const ProfessionalProfileForm({super.key, required this.subCategory});

  @override
  State<ProfessionalProfileForm> createState() => _ProfessionalProfileFormState();
}

class _ProfessionalProfileFormState extends State<ProfessionalProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _years = TextEditingController();
  final _services = TextEditingController();
  final _availability = TextEditingController();
  final _certification = TextEditingController();
  final _summary = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      "serviceType": "Professional service",
      "subCategory": widget.subCategory,
      "yearsOfExperience": _years.text.trim(),
      "servicesOffered": _services.text.trim(),
      "availability": _availability.text.trim(),
      "certification": _certification.text.trim(),
      "summary": _summary.text.trim(),
    };

    final res = await AuthService().post('/api/agents/me', data);
    setState(() => _loading = false);

    if (res['statusCode'] == 200 || res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile created")));

      // ✅ fetch token
      final token = await AuthService().getToken();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadImageScreen(token: token ?? ''),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['body']['message'] ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Profile - ${widget.subCategory}"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _years, decoration: const InputDecoration(labelText: "Years of Experience"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 12),
              TextFormField(controller: _services, decoration: const InputDecoration(labelText: "Specific services offered"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 12),
              TextFormField(controller: _availability, decoration: const InputDecoration(labelText: "Availability")),
              const SizedBox(height: 12),
              TextFormField(controller: _certification, decoration: const InputDecoration(labelText: "Relevant Certification(s)")),
              const SizedBox(height: 12),
              TextFormField(controller: _summary, decoration: const InputDecoration(labelText: "Brief Summary"), maxLines: 4),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
