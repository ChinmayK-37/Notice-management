import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/analytics/ui/analytics_screen.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notification/providers/notification_provider.dart';
import 'package:notice_app/shared/models/notice_model.dart';
import 'package:notice_app/shared/widgets/notice_visuals.dart';

class NoticeDetailScreen extends ConsumerStatefulWidget {
  const NoticeDetailScreen({required this.notice, super.key});

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
      _showMessage('No notification available for this notice');
      return;
    }

    if (_isRead || _isMarkReadLoading) {
      return;
    }

    setState(() {
      _isMarkReadLoading = true;
    });

    try {
      await ref.read(notificationServiceProvider).markAsRead(notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRead = true;
      });
      _showMessage('Marked as read');
      await ref.read(noticeProvider.notifier).fetchNotices();
      await ref.read(notificationProvider.notifier).fetchNotifications();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
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
      _showMessage('No notification available for this notice');
      return;
    }

    if (_isAcknowledged || _isAcknowledgeLoading) {
      return;
    }

    setState(() {
      _isAcknowledgeLoading = true;
    });

    try {
      await ref.read(notificationServiceProvider).acknowledge(notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isAcknowledged = true;
      });
      _showMessage('Notice acknowledged');
      await ref.read(noticeProvider.notifier).fetchNotices();
      await ref.read(notificationProvider.notifier).fetchNotifications();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isAcknowledgeLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final category = NoticeVisuals.categoryFor(widget.notice);
    final priorityColor = NoticeVisuals.priorityColor(
      context,
      widget.notice.priority,
    );
    final expiry = widget.notice.expiryDate;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notice details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                            icon: NoticeVisuals.priorityIcon(
                              widget.notice.priority,
                            ),
                            label: widget.notice.priority.toUpperCase(),
                            color: priorityColor,
                          ),
                          _DetailChip(
                            icon: NoticeVisuals.categoryIcon(category),
                            label: category,
                            color: scheme.primary,
                          ),
                          _DetailChip(
                            icon: Icons.schedule_outlined,
                            label: NoticeVisuals.deadlineLabel(expiry),
                            color: NoticeVisuals.isDueSoon(widget.notice)
                                ? Colors.deepOrange.shade700
                                : scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.notice.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _summaryText(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _InfoGrid(
                  items: [
                    _InfoItem(
                      icon: Icons.groups_outlined,
                      label: 'Audience',
                      value: widget.notice.department,
                    ),
                    _InfoItem(
                      icon: Icons.event_outlined,
                      label: 'Deadline',
                      value: expiry == null
                          ? 'No expiry date'
                          : DateFormat('dd MMM yyyy').format(expiry),
                    ),
                    _InfoItem(
                      icon: _isAcknowledged
                          ? Icons.verified_outlined
                          : _isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      label: 'Your status',
                      value: _isAcknowledged
                          ? 'Acknowledged'
                          : _isRead
                          ? 'Read'
                          : 'Unread',
                    ),
                    _InfoItem(
                      icon: Icons.person_outline,
                      label: 'Posted by',
                      value: (widget.notice.createdBy ?? '').trim().isEmpty
                          ? 'Admin'
                          : widget.notice.createdBy!,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notice content',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.notice.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Attachments ready - files can be linked with this notice when enabled.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (authState.isAdmin)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AnalyticsScreen(noticeId: widget.notice.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('View engagement analytics'),
                  )
                else ...[
                  if (!_hasNotification)
                    _NoticeWarning(
                      message:
                          'No notification record is attached to this notice yet.',
                    ),
                  FilledButton.icon(
                    onPressed:
                        (!_hasNotification || _isRead || _isMarkReadLoading)
                        ? null
                        : _markAsRead,
                    icon: _isMarkReadLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(_isRead ? 'Marked as read' : 'Mark as read'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed:
                        (!_hasNotification ||
                            _isAcknowledged ||
                            _isAcknowledgeLoading)
                        ? null
                        : _acknowledge,
                    icon: _isAcknowledgeLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.task_alt_outlined),
                    label: Text(
                      _isAcknowledged ? 'Acknowledged' : 'Acknowledge notice',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 3.2 : 4.4,
          ),
          itemBuilder: (context, index) => _InfoCard(item: items[index]),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(item.icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeWarning extends StatelessWidget {
  const _NoticeWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
