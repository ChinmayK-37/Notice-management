import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/analytics/ui/analytics_screen.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notification/providers/notification_provider.dart';
import 'package:notice_app/shared/models/notice_model.dart';

class NoticeDetailScreen extends ConsumerStatefulWidget {
  const NoticeDetailScreen({
    required this.notice,
    super.key,
  });

  final NoticeModel notice;

  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  late bool _isRead;
  late bool _isAcknowledged;
  bool _isMarkReadLoading = false;
  bool _isAcknowledgeLoading = false;

  bool get _hasNotification => widget.notice.notificationId != null;

  @override
  void initState() {
    super.initState();
    _isRead = widget.notice.isRead || widget.notice.readStatus;
    _isAcknowledged = widget.notice.isAcknowledged;
  }

  Color _priorityColor(BuildContext context) {
    switch (widget.notice.priority.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.yellow.shade700;
      case 'LOW':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _summaryText() {
    final lines = widget.notice.description
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return 'No summary available.';
    }

    return lines.take(3).join(' ');
  }

  Future<void> _markAsRead() async {
    final notificationId = widget.notice.notificationId;
    if (notificationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No notification available for this notice'),
          ),
        );
      }
      return;
    }

    if (_isRead || _isMarkReadLoading) {
      return;
    }

    setState(() {
      _isMarkReadLoading = true;
    });

    try {
      await ref
          .read(notificationServiceProvider)
          .markAsRead(notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRead = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read')),
      );
      await ref.read(noticeProvider.notifier).fetchNotices();
      await ref.read(notificationProvider.notifier).fetchNotifications();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkReadLoading = false;
        });
      }
    }
  }

  Future<void> _acknowledge() async {
    final notificationId = widget.notice.notificationId;
    if (notificationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No notification available for this notice'),
          ),
        );
      }
      return;
    }

    if (_isAcknowledged || _isAcknowledgeLoading) {
      return;
    }

    setState(() {
      _isAcknowledgeLoading = true;
    });

    try {
      await ref
          .read(notificationServiceProvider)
          .acknowledge(notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isAcknowledged = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice acknowledged')),
      );
      await ref.read(noticeProvider.notifier).fetchNotices();
      await ref.read(notificationProvider.notifier).fetchNotifications();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAcknowledgeLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.notice.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.notice.priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _summaryText(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Audience: ${widget.notice.department}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.notice.createdBy != null &&
                widget.notice.createdBy!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Posted by: ${widget.notice.createdBy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              widget.notice.expiryDate == null
                  ? 'Expiry: none'
                  : 'Expiry: ${DateFormat('dd MMM yyyy').format(widget.notice.expiryDate!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.notice.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            if (authState.isAdmin)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AnalyticsScreen(noticeId: widget.notice.id),
                      ),
                    );
                  },
                  child: const Text('View Analytics'),
                ),
              ),
            const SizedBox(height: 32),
            if (!_hasNotification)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No notification available for this notice',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!_hasNotification || _isRead || _isMarkReadLoading)
                    ? null
                    : _markAsRead,
                child: _isMarkReadLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRead ? 'Marked as Read' : 'Mark as Read'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (!_hasNotification ||
                        _isAcknowledged ||
                        _isAcknowledgeLoading)
                    ? null
                    : _acknowledge,
                child: _isAcknowledgeLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isAcknowledged ? 'Acknowledged' : 'Acknowledge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
