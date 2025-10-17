import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Profile_screens/professional_screen.dart';
import 'forms/errand_services_form_screen.dart';
import 'forms/babysitting_profile_form.dart';
import 'forms/cleaning_profile_form.dart';
import 'forms/personal_assistance_profile_form.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  void _navigate(BuildContext context, String service) {
    if (service == "Professional service") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalSubCategoryScreen()));
    } else if (service == "Errand Service") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrandProfileForm()));
    } else if (service == "Babysitting") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BabysittingProfileForm()));
    } else if (service == "Cleaning and laundry service") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CleaningProfileForm()));
    } else if (service == "Personal assistance") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAssistanceProfileForm()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      "Errand Service",
      "Babysitting",
      "Professional service",
      "Cleaning and laundry service",
      "Personal assistance"
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Service"),
        backgroundColor: const Color(0xFF6FAF96),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What service are you trying to render?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Expanded so ListView can scroll
            Expanded(
              child: ListView.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FAF96),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _navigate(context, services[index]),
                    child: Text(
                      services[index],
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
