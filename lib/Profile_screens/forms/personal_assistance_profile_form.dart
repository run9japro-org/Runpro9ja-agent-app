// lib/screens/agent/forms/personal_assistance_profile_form.dart
import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Profile_screens/forms/uploading_img_screen.dart';
import '../../Auth/auth_services.dart';

class PersonalAssistanceProfileForm extends StatefulWidget {
  const PersonalAssistanceProfileForm({super.key});

  @override
  State<PersonalAssistanceProfileForm> createState() => _PersonalAssistanceProfileFormState();
}

class _PersonalAssistanceProfileFormState extends State<PersonalAssistanceProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _years = TextEditingController();
  final _tasks = TextEditingController();
  final _skills = TextEditingController();
  final _availability = TextEditingController();
  final _summary = TextEditingController();

  bool _loading = false;

  // ✅ Consistent styling
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      "serviceType": "Personal Assistance",
      "yearsOfExperience": _years.text.trim(),
      "tasksHandled": _tasks.text.trim(),
      "skills": _skills.text.trim(),
      "availability": _availability.text.trim(),
      "summary": _summary.text.trim(),
    };

    final res = await AuthService().post('/api/agents/me', data);
    setState(() => _loading = false);

    if (res['statusCode'] == 200 || res['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile created")));
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
      appBar: AppBar(
        title: const Text("Personal Assistance Profile"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ Introductory text
              const Text(
                "Tell us about your assistance experience 💼",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Help clients understand how you can support their daily needs.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _years,
                decoration: _inputDecoration(
                    "Years of Experience",
                    "How many years have you been assisting people?"
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tasks,
                decoration: _inputDecoration(
                    "Tasks Handled",
                    "E.g., scheduling, errands, travel booking"
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skills,
                decoration: _inputDecoration(
                    "Skills",
                    "E.g., multitasking, communication, organization"
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availability,
                decoration: _inputDecoration(
                    "Availability",
                    "E.g., weekdays, weekends, evenings"
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summary,
                decoration: _inputDecoration(
                    "Brief Summary",
                    "Write a short profile about yourself"
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
                      borderRadius: BorderRadius.circular(12)
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}