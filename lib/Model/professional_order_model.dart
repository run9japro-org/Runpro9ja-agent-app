// lib/models/professional_order_model.dart
class ProfessionalOrder {
  final String id;
  final String serviceCategory;
  final String description;
  final String location;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final double? quotationAmount;
  final String? quotationDetails;
  final List<dynamic>? recommendedAgents;

  ProfessionalOrder({
    required this.id,
    required this.serviceCategory,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.quotationAmount,
    this.quotationDetails,
    this.recommendedAgents,
  });

  factory ProfessionalOrder.fromJson(Map<String, dynamic> json) {
    return ProfessionalOrder(
      id: json['_id'] ?? json['id'] ?? '',
      serviceCategory: _parseServiceCategory(json['serviceCategory']),
      description: json['details'] ?? json['description'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'requested',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      customerName: json['customer'] is Map ? json['customer']['fullName'] : null,
      quotationAmount: (json['quotationAmount'] ?? 0).toDouble(),
      quotationDetails: json['quotationDetails'],
      recommendedAgents: json['recommendedAgents'],
    );
  }

  static String _parseServiceCategory(dynamic serviceCategory) {
    if (serviceCategory is String) return serviceCategory;
    if (serviceCategory is Map) return serviceCategory['name'] ?? 'Unknown Service';
    return 'Unknown Service';
  }
}