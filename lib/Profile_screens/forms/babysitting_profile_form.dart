// lib/screens/agent/forms/babysitting_profile_form.dart
import 'package:flutter/material.dart';
import '../../Auth/auth_services.dart';

import 'package:runpro9ja_agent/Profile_screens/forms/uploading_img_screen.dart';
class BabysittingProfileForm extends StatefulWidget {
  const BabysittingProfileForm({super.key});

  @override
  State<BabysittingProfileForm> createState() => _BabysittingProfileFormState();
}

class _BabysittingProfileFormState extends State<BabysittingProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _years = TextEditingController();
  final _ageRange = TextEditingController();
  final _skills = TextEditingController();
  final _availability = TextEditingController();
  final _summary = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      "serviceType": "Babysitting",
      "yearsOfExperience": _years.text.trim(),
      "ageRange": _ageRange.text.trim(),
      "skills": _skills.text.trim(),
      "availability": _availability.text.trim(),
      "summary": _summary.text.trim(),
    };

    final res = await AuthService().post('/api/agents/me', data);
    setState(() => _loading = false);

    if (res['statusCode'] == 200 || res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile created")),
      );
      final token = await AuthService().getToken();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadImageScreen(token: token ?? ''),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['body']['message'] ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Babysitting Profile"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _years, decoration: const InputDecoration(labelText: "Years of Experience", hintText: "How many years have you been babysitting?"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 12),
              TextFormField(controller: _ageRange, decoration: const InputDecoration(labelText: "Age Range", hintText: "What age range of children do you care for?"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 12),
              TextFormField(controller: _skills, decoration: const InputDecoration(labelText: "Skills", hintText: "E.g., CPR, first aid, cooking, tutoring")),
              const SizedBox(height: 12),
              TextFormField(controller: _availability, decoration: const InputDecoration(labelText: "Availability", hintText: "E.g., weekdays, weekends, evenings")),
              const SizedBox(height: 12),
              TextFormField(controller: _summary, decoration: const InputDecoration(labelText: "Brief Summary", hintText: "Write a short profile about yourself"), maxLines: 4),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Continue"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
