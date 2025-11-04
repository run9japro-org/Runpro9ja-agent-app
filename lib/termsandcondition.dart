import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms and Conditions"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome to Runpro 9ja! These terms and conditions govern your use of our mobile application/website and services provided by Runpro 9ja located in Lagos, Nigeria. By accessing or using our platform, you agree to be bound by these terms.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 20),

            Text("1. Overview of Services:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "Runpro 9ja offers cleaning and professional services to individuals and businesses. These services include, but are not limited to, home cleaning, errand delivery, maintenance support, fumigation, and other related services.",
            ),
            SizedBox(height: 4),
            Text(
              "All services are requested through our mobile app and carried out by verified and trained third-party contractors.",
            ),
            SizedBox(height: 20),

            Text("2. Eligibility:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("• To use our services, you must:"),
            Text("• Be at least 16 years old"),
            Text("• Provide accurate and current information during registration"),
            Text("• Have a legal capacity to enter into a binding arrangement"),
            SizedBox(height: 20),

            Text("3. Payment Terms:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "• Payment is made via debit card or bank transfer.\n• Prices are displayed before checkout.\n• Additional charges may apply depending on the distance, urgency, and duration of the task."),
            SizedBox(height: 20),

            Text("4. Third-Party Contractors:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "Runpro 9ja partners with independent contractors to carry out tasks. While we verify all background checks and professionalism, we are not liable for any personal negligence or misconduct by these contractors except in cases of gross negligence proven against us."),
            SizedBox(height: 20),

            Text("5. User Responsibility:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "• Provide accurate address and description for delivery/pickup details.\n• Ensure availability for service appointments.\n• Not use the platform for prohibited, illegal, or fraudulent activities."),
            SizedBox(height: 20),

            Text("6. Cancellations and Return Policy:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "• Any order or task within 1 hour of initiation or assignment can be cancelled.\n• Cancellations after a service provider has accepted the task may incur charges.\n• Refunds will be processed within 3–5 business days."),
            SizedBox(height: 20),

            Text("7. Liability Disclaimer:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                "• Runpro 9ja shall not be liable for inaccurate instructions or unforeseen causes of damage during tasks.\n• Drivers must obey traffic safety and should not be held liable for unavoidable delays due to traffic or weather conditions."),
          ],
        ),
      ),
    );
  }
}
