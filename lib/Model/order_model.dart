import 'package:flutter/material.dart';
class Order {
  final String id;
  final String customerId;
  final String? agentId;
  final String serviceCategory;
  final String details;
  final double price;
  final String location;
  final String status;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? agent;
  final List<dynamic> timeline;

  Order({
    required this.id,
    required this.customerId,
    this.agentId,
    required this.serviceCategory,
    required this.details,
    required this.price,
    required this.location,
    required this.status,
    required this.createdAt,
    this.scheduledDate,
    this.scheduledTime,
    this.customer,
    this.agent,
    required this.timeline,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('🔄 PARSING ORDER JSON:');
    print('   - Order ID: ${json['_id']}');

    // Log ALL fields for debugging
    print('   - All JSON keys: ${json.keys.toList()}');

    // Handle id field
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? 'unknown_id';

    // Handle customerId field
    final customerId = _parseCustomerId(json);

    // Handle serviceCategory field
    final serviceCategory = _parseServiceCategory(json);

    // Handle details field
    final details = json['details']?.toString() ??
        json['itemsDescription']?.toString() ??
        json['specialInstructions']?.toString() ??
        'No details provided';

    // **IMPORTANT: Parse price with debugging**
    final price = _parsePrice(json);

    // Handle location field
    final location = _parseLocation(json);

    // Handle status field
    final status = json['status']?.toString() ?? 'requested';

    // Handle createdAt field
    final createdAt = _parseCreatedAt(json);

    // Handle scheduledDate field
    final scheduledDate = _parseScheduledDate(json);

    // Handle timeline field
    final timeline = json['timeline'] is List ? json['timeline'] : [];

    print('✅ ORDER PARSED SUCCESSFULLY:');
    print('   - ID: $id');
    print('   - Service: $serviceCategory');
    print('   - Price: ₦$price');
    print('   - Location: $location');
    print('   - Status: $status');
    print('   - Created: $createdAt');

    return Order(
      id: id,
      customerId: customerId,
      agentId: _parseAgentId(json),
      serviceCategory: serviceCategory,
      details: details,
      price: price,
      location: location,
      status: status,
      createdAt: createdAt,
      scheduledDate: scheduledDate,
      scheduledTime: json['scheduledTime']?.toString(),
      customer: _parseCustomer(json),
      agent: _parseAgent(json),
      timeline: timeline,
    );
  }

  // Helper methods for parsing
  static String _parseCustomerId(Map<String, dynamic> json) {
    if (json['customer'] is String) {
      return json['customer'];
    } else if (json['customer'] is Map && json['customer']['_id'] != null) {
      return json['customer']['_id'].toString();
    } else if (json['customerId'] != null) {
      return json['customerId'].toString();
    }
    return 'unknown_customer';
  }

  static String? _parseAgentId(Map<String, dynamic> json) {
    if (json['agent'] is String) {
      return json['agent'];
    } else if (json['agent'] is Map && json['agent']['_id'] != null) {
      return json['agent']['_id'].toString();
    } else if (json['agentId'] != null) {
      return json['agentId'].toString();
    } else if (json['assignedAgent'] != null) {
      return json['assignedAgent'].toString();
    }
    return null;
  }

  static String _parseServiceCategory(Map<String, dynamic> json) {
    if (json['serviceCategory'] is String) {
      return json['serviceCategory'];
    } else if (json['serviceCategory'] is Map && json['serviceCategory']['name'] != null) {
      return json['serviceCategory']['name'].toString();
    } else if (json['serviceType'] != null) {
      return json['serviceType'].toString();
    } else if (json['errandType'] != null) {
      return json['errandType'].toString();
    }
    return 'General Service';
  }

  static double _parsePrice(Map<String, dynamic> json) {
    print('💰 PRICE PARSING DEBUG:');

    // **FIXED: Check ALL possible price fields more thoroughly**
    final priceFields = [
      'price', 'totalAmount', 'amount', 'quotationAmount', 'orderAmount',
      'servicePrice', 'estimatedPrice', 'itemTotal', 'deliveryFee', 'total',
      'cost', 'fee', 'paymentAmount', 'quotedPrice', 'serviceFee'
    ];

    // **DEBUG: Log all price-related fields and their values**
    print('   - Checking all price fields:');
    for (final field in priceFields) {
      final value = json[field];
      if (value != null) {
        print('     - $field: $value (type: ${value.runtimeType})');
      }
    }

    // **FIXED: Try each field with better parsing**
    for (final field in priceFields) {
      final value = json[field];
      if (value != null) {
        print('   - Attempting to parse field "$field": $value');

        double parsedValue = 0.0;

        if (value is int) {
          parsedValue = value.toDouble();
        } else if (value is double) {
          parsedValue = value;
        } else if (value is String) {
          parsedValue = double.tryParse(value) ?? 0.0;
        } else if (value is Map) {
          // Handle MongoDB formats
          if (value['\$numberDouble'] != null) {
            parsedValue = double.tryParse(value['\$numberDouble'].toString()) ?? 0.0;
          } else if (value['\$numberInt'] != null) {
            parsedValue = double.tryParse(value['\$numberInt'].toString()) ?? 0.0;
          } else {
            // Try to parse the map as a number
            parsedValue = double.tryParse(value.toString()) ?? 0.0;
          }
        }

        if (parsedValue > 0) {
          print('   ✅ SUCCESS: Using $field = ₦$parsedValue');
          return parsedValue;
        }
      }
    }

    // **FIXED: Only calculate dynamic price if no price fields found**
    print('   - No valid price fields found, calculating dynamic price');
    final serviceCategory = _parseServiceCategory(json);
    final details = json['details']?.toString() ?? '';
    final calculatedPrice = _calculateDynamicPrice(serviceCategory, details);

    print('   - Calculated dynamic price: ₦$calculatedPrice for "$serviceCategory"');
    print('   - Details used for calculation: $details');

    return calculatedPrice;
  }

  static double _calculateDynamicPrice(String serviceCategory, String details) {
    final service = serviceCategory.toLowerCase();
    final detailsLower = details.toLowerCase();

    // Professional services - higher pricing
    if (service.contains('plumbing') || detailsLower.contains('plumbing')) {
      return 8000.0 + _getComplexityBonus(details);
    }
    if (service.contains('electrical') || detailsLower.contains('electrical')) {
      return 7500.0 + _getComplexityBonus(details);
    }
    if (service.contains('carpentry') || detailsLower.contains('carpentry')) {
      return 7000.0 + _getComplexityBonus(details);
    }
    if (service.contains('painting') || detailsLower.contains('painting')) {
      return 9000.0 + _getComplexityBonus(details);
    }

    // Moving services - based on scale
    if (service.contains('moving') || service.contains('movers')) {
      if (detailsLower.contains('large') || detailsLower.contains('truck')) return 20000.0;
      if (detailsLower.contains('medium')) return 15000.0;
      return 12000.0;
    }

    // Delivery services
    if (service.contains('delivery') || detailsLower.contains('delivery')) {
      if (detailsLower.contains('express') || detailsLower.contains('urgent')) return 5000.0;
      return 3500.0;
    }

    // Errand services
    if (service.contains('errand') || detailsLower.contains('errand')) {
      return 3000.0 + _getItemsCountBonus(details);
    }

    // Grocery services
    if (service.contains('grocery') || detailsLower.contains('grocery') || detailsLower.contains('shopping')) {
      return 4000.0 + _getItemsCountBonus(details);
    }

    // Cleaning services
    if (service.contains('cleaning') || detailsLower.contains('cleaning')) {
      if (detailsLower.contains('deep') || detailsLower.contains('full')) return 8000.0;
      return 5000.0;
    }

    // Laundry services
    if (service.contains('laundry') || detailsLower.contains('laundry')) {
      return 4500.0;
    }

    // Babysitting services
    if (service.contains('babysitting') || detailsLower.contains('baby') || detailsLower.contains('child')) {
      return 6000.0;
    }

    // Default pricing for unknown services
    return 4000.0;
  }

  static double _getComplexityBonus(String details) {
    final detailsLower = details.toLowerCase();
    double bonus = 0.0;

    if (detailsLower.contains('complex') || detailsLower.contains('complicated')) bonus += 3000.0;
    if (detailsLower.contains('emergency') || detailsLower.contains('urgent')) bonus += 2000.0;
    if (detailsLower.contains('install') || detailsLower.contains('repair')) bonus += 2500.0;
    if (detailsLower.contains('multiple') || detailsLower.contains('several')) bonus += 4000.0;

    return bonus;
  }

  static double _getItemsCountBonus(String details) {
    final detailsLower = details.toLowerCase();
    double bonus = 0.0;

    if (detailsLower.contains('multiple') || detailsLower.contains('several')) bonus += 2000.0;
    if (detailsLower.contains('many') || detailsLower.contains('lots')) bonus += 3000.0;
    if (detailsLower.contains('bulk') || detailsLower.contains('large')) bonus += 4000.0;

    // Count rough item estimates
    final itemCount = RegExp(r'\d+').allMatches(detailsLower).length;
    bonus += itemCount * 500.0;

    return bonus;
  }

  static String _parseLocation(Map<String, dynamic> json) {
    if (json['location'] is String) {
      return json['location'];
    } else if (json['pickup'] is String) {
      return json['pickup'];
    } else if (json['fromAddress'] is String) {
      return json['fromAddress'];
    } else if (json['pickup'] is Map && json['pickup']['addressLine'] != null) {
      return json['pickup']['addressLine'].toString();
    }
    return 'Location not specified';
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> json) {
    try {
      if (json['createdAt'] != null) {
        return DateTime.parse(json['createdAt'].toString()).toLocal();
      }
    } catch (e) {
      print('Error parsing createdAt: $e');
    }
    return DateTime.now();
  }

  static DateTime? _parseScheduledDate(Map<String, dynamic> json) {
    try {
      if (json['scheduledDate'] != null) {
        return DateTime.parse(json['scheduledDate'].toString()).toLocal();
      }
    } catch (e) {
      print('Error parsing scheduledDate: $e');
    }
    return null;
  }

  static Map<String, dynamic>? _parseCustomer(Map<String, dynamic> json) {
    if (json['customer'] is Map) {
      return Map<String, dynamic>.from(json['customer']);
    }
    return null;
  }

  static Map<String, dynamic>? _parseAgent(Map<String, dynamic> json) {
    if (json['agent'] is Map) {
      return Map<String, dynamic>.from(json['agent']);
    }
    return null;
  }

  // Add these properties for your UI
  bool get isPublic => status == 'public' || status == 'pending_agent_response';

  String get statusText {
    switch (status) {
      case 'pending_agent_response':
        return 'Waiting for Response';
      case 'public':
        return 'Available';
      case 'accepted':
        return 'Accepted';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_agent_response':
        return Colors.orange;
      case 'public':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.grey;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending_agent_response':
        return Icons.access_time;
      case 'public':
        return Icons.public;
      case 'accepted':
        return Icons.check_circle;
      case 'in-progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.verified;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String get formattedPrice {
    return '₦${price.toStringAsFixed(2)}';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}