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
    return Order(
      id: json['_id'] ?? json['id'],
      customerId: json['customer'] is String ? json['customer'] : json['customer']?['_id'],
      agentId: json['agent'] is String ? json['agent'] : json['agent']?['_id'],
      serviceCategory: json['serviceCategory'] is String
          ? json['serviceCategory']
          : json['serviceCategory']?['name'] ?? 'Service',
      details: json['details'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      status: json['status'] ?? 'requested',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      scheduledTime: json['scheduledTime'],
      customer: json['customer'] is Map ? Map<String, dynamic>.from(json['customer']) : null,
      agent: json['agent'] is Map ? Map<String, dynamic>.from(json['agent']) : null,
      timeline: json['timeline'] ?? [],
    );
  }

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