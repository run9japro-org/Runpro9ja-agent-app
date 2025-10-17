import 'package:flutter/material.dart';
import 'dart:async';

class VerifiedPage extends StatefulWidget {
  const VerifiedPage({super.key});

  @override
  State<VerifiedPage> createState() => _VerifiedPageState();
}

class _VerifiedPageState extends State<VerifiedPage> {
  @override
  void initState() {
    super.initState();

    // ⏳ Wait 2 seconds then redirect to Main Page
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/selection');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.check, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 20),

              const Text(
                "Verified!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text(
                "You are all set to enjoy the experience.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              const CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
