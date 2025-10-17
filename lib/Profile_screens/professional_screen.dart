// lib/screens/agent/professional_subcategory_screen.dart
import 'package:flutter/material.dart';
import 'forms/professional_profile_form.dart';

class ProfessionalSubCategoryScreen extends StatelessWidget {
  const ProfessionalSubCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subcategories = [
      "Plumber",
      "Electrician",
      "Mechanics",
      "Furniture Building",
      "Painters",
      "Fashion designers",
      "Beauticians"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Professional Services"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: subcategories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FAF96),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfessionalProfileForm(subCategory: subcategories[index]),
                  ),
                );
              },
              child: Text(subcategories[index], style: const TextStyle(fontSize: 16)),
            );
          },
        ),
      ),
    );
  }
}
