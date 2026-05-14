import 'package:flutter/material.dart';
import 'package:notice_app/shared/models/notice_model.dart';

class NoticeVisuals {
  const NoticeVisuals._();

  static Color priorityColor(BuildContext context, String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFC62828);
      case 'MEDIUM':
        return const Color(0xFFEF6C00);
      case 'LOW':
        return const Color(0xFF2E7D32);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static IconData priorityIcon(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return Icons.priority_high_rounded;
      case 'MEDIUM':
        return Icons.schedule_rounded;
      case 'LOW':
        return Icons.info_outline_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  static String categoryFor(NoticeModel notice) {
    if (notice.category.trim().isNotEmpty) {
      return _titleCase(notice.category.trim());
    }
    final text = '${notice.title} ${notice.description}'.toLowerCase();
    if (text.contains('exam') || text.contains('hall ticket')) {
      return 'Exam';
    }
    if (text.contains('assignment') || text.contains('submission')) {
      return 'Assignment';
    }
    if (text.contains('placement') || text.contains('interview')) {
      return 'Placement';
    }
    if (text.contains('fee') || text.contains('scholarship')) {
      return 'Finance';
    }
    if (text.contains('workshop') || text.contains('seminar')) {
      return 'Workshop';
    }
    if (text.contains('holiday') || text.contains('closed')) {
      return 'Holiday';
    }
    if (text.contains('visit') || text.contains('sports')) {
      return 'Event';
    }
    return 'Notice';
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'Exam':
        return Icons.school_outlined;
      case 'Assignment':
        return Icons.assignment_outlined;
      case 'Placement':
        return Icons.business_center_outlined;
      case 'Finance':
        return Icons.account_balance_wallet_outlined;
      case 'Workshop':
        return Icons.computer_outlined;
      case 'Holiday':
        return Icons.beach_access_outlined;
      case 'Event':
        return Icons.event_available_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int? daysUntil(DateTime? expiry) {
    if (expiry == null) {
      return null;
    }
    return dateOnly(expiry).difference(dateOnly(DateTime.now())).inDays;
  }

  static bool isExpired(NoticeModel notice) {
    final days = daysUntil(notice.expiryDate);
    return days != null && days < 0;
  }

  static bool isDueSoon(NoticeModel notice) {
    final days = daysUntil(notice.expiryDate);
    return days != null && days >= 0 && days <= 3;
  }

  static String deadlineLabel(DateTime? expiry) {
    final days = daysUntil(expiry);
    if (days == null) {
      return 'No deadline';
    }
    if (days < 0) {
      return 'Expired';
    }
    if (days == 0) {
      return 'Due today';
    }
    if (days == 1) {
      return 'Due tomorrow';
    }
    return '$days days left';
  }
}
