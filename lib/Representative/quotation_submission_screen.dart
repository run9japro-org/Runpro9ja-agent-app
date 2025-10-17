// lib/screens/representative/quotation_submission_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_services.dart';
import '../Services/Agentservice.dart'; // Fixed import path


class QuotationSubmissionScreen extends StatefulWidget {
  final String orderId;

  const QuotationSubmissionScreen({super.key, required this.orderId});

  @override
  State<QuotationSubmissionScreen> createState() => _QuotationSubmissionScreenState();
}

class _QuotationSubmissionScreenState extends State<QuotationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _agentsController = TextEditingController();
  late final AgentService _agentService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _agentService = AgentService(AuthService());
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _agentService.submitQuotation(
        orderId: widget.orderId,
        quotationAmount: double.parse(_amountController.text),
        quotationDetails: _detailsController.text,
        recommendedAgents: _agentsController.text.isNotEmpty
            ? _agentsController.text.split(',').map((e) => e.trim()).toList()
            : [],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quotation submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to orders list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit quotation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Quotation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Quotation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: ${widget.orderId}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quotation Amount (₦)',
                  border: OutlineInputBorder(),
                  prefixText: '₦ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quotation amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Details Field
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Quotation Details',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the work to be done, materials needed, timeline, etc.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide quotation details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recommended Agents Field
              TextFormField(
                controller: _agentsController,
                decoration: const InputDecoration(
                  labelText: 'Recommended Agent IDs (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter agent IDs separated by commas',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Enter agent MongoDB IDs separated by commas if you want to recommend specific agents',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuotation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Submit Quotation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}