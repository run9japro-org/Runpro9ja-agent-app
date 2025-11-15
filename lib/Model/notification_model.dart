// models/notification_model.dart
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? actionUrl;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.data,
    required this.isRead,
    this.actionUrl,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] is String ? json['user'] : json['user']?['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      priority: _parseNotificationPriority(json['priority']),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['isRead'] ?? false,
      actionUrl: json['actionUrl'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'title': title,
      'message': message,
      'type': _convertNotificationTypeToString(type),
      'priority': _convertNotificationPriorityToString(priority),
      'data': data,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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

  IconData get icon {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.shopping_bag_outlined;
      case NotificationType.payment:
        return Icons.payment_outlined;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.agentAssigned:
        return Icons.person_outline;
      case NotificationType.deliveryStatus:
        return Icons.delivery_dining_outlined;
      case NotificationType.chat:
        return Icons.chat_outlined;
      case NotificationType.review:
        return Icons.star_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.agentAssigned:
        return Colors.teal;
      case NotificationType.deliveryStatus:
        return Colors.cyan;
      case NotificationType.chat:
        return Colors.pink;
      case NotificationType.review:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'order_update': return NotificationType.orderUpdate;
      case 'payment': return NotificationType.payment;
      case 'system': return NotificationType.system;
      case 'promotion': return NotificationType.promotion;
      case 'agent_assigned': return NotificationType.agentAssigned;
      case 'delivery_status': return NotificationType.deliveryStatus;
      case 'chat': return NotificationType.chat;
      case 'review': return NotificationType.review;
      default: return NotificationType.system;
    }
  }

  static String _convertNotificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate: return 'order_update';
      case NotificationType.payment: return 'payment';
      case NotificationType.system: return 'system';
      case NotificationType.promotion: return 'promotion';
      case NotificationType.agentAssigned: return 'agent_assigned';
      case NotificationType.deliveryStatus: return 'delivery_status';
      case NotificationType.chat: return 'chat';
      case NotificationType.review: return 'review';
    }
  }

  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority) {
      case 'low': return NotificationPriority.low;
      case 'medium': return NotificationPriority.medium;
      case 'high': return NotificationPriority.high;
      case 'urgent': return NotificationPriority.urgent;
      default: return NotificationPriority.medium;
    }
  }

  static String _convertNotificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low: return 'low';
      case NotificationPriority.medium: return 'medium';
      case NotificationPriority.high: return 'high';
      case NotificationPriority.urgent: return 'urgent';
    }
  }
}

enum NotificationType {
  orderUpdate,
  payment,
  system,
  promotion,
  agentAssigned,
  deliveryStatus,
  chat,
  review,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int currentPage;
  final int totalPages;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List? ?? [])
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
      total: json['pagination']?['total'] ?? 0,
      currentPage: json['pagination']?['current'] ?? 1,
      totalPages: json['pagination']?['pages'] ?? 1,
      unreadCount: json['pagination']?['unreadCount'] ?? 0,
    );
  }
}