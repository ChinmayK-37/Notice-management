import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notification/data/notification_model.dart';
import 'package:notice_app/features/notification/providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(notificationProvider.notifier).fetchNotifications(),
    );
  }

  Future<void> _onMarkAsRead(NotificationModel notification) async {
    if (notification.isRead) {
      return;
    }

    await ref.read(notificationProvider.notifier).markAsRead(notification.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification marked as read')),
    );
  }

  Future<void> _onAcknowledge(NotificationModel notification) async {
    if (notification.isAcknowledged) {
      return;
    }

    await ref.read(notificationProvider.notifier).acknowledge(notification.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification acknowledged')));
  }

  Future<void> _refresh() {
    return ref.read(notificationProvider.notifier).fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifications = state.notifications;
    final reminders = notifications
        .where((n) => n.type.toUpperCase() == 'REMINDER')
        .toList();
    final updates = notifications
        .where((n) => n.type.toUpperCase() != 'REMINDER')
        .toList();
    final unread = notifications.where((n) => !n.isRead).length;
    final acknowledged = notifications.where((n) => n.isAcknowledged).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification center')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: state.isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && notifications.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  _NotificationEmpty(
                    icon: Icons.cloud_off_outlined,
                    title: 'Notifications unavailable',
                    message: state.error!,
                  ),
                ],
              )
            : notifications.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  _NotificationEmpty(
                    icon: Icons.notifications_none_outlined,
                    title: 'No notifications yet',
                    message:
                        'New notices and deadline reminders will appear here.',
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NotificationSummary(
                            unread: unread,
                            reminders: reminders.length,
                            acknowledged: acknowledged,
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Deadline reminders',
                            subtitle: 'Adaptive local and system reminders',
                            items: reminders,
                          ),
                          _buildSection(
                            title: 'Notice updates',
                            subtitle: 'Published notices and status updates',
                            items: updates,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<NotificationModel> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle, count: items.length),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((entry) {
          return _NotificationTile(
            notification: entry.value,
            index: entry.key,
            onMarkAsRead: () => _onMarkAsRead(entry.value),
            onAcknowledge: () => _onAcknowledge(entry.value),
          );
        }),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.unread,
    required this.reminders,
    required this.acknowledged,
  });

  final int unread;
  final int reminders;
  final int acknowledged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryPill(
              icon: Icons.mark_email_unread_outlined,
              label: '$unread unread',
            ),
            _SummaryPill(
              icon: Icons.alarm_outlined,
              label: '$reminders reminders',
            ),
            _SummaryPill(
              icon: Icons.task_alt_outlined,
              label: '$acknowledged acknowledged',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Chip(label: Text('$count')),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.index,
    required this.onMarkAsRead,
    required this.onAcknowledge,
  });

  final NotificationModel notification;
  final int index;
  final VoidCallback onMarkAsRead;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final isReminder = notification.type.toUpperCase() == 'REMINDER';
    final color = isReminder
        ? Colors.deepOrange.shade700
        : Theme.of(context).colorScheme.primary;
    final muted = notification.isAcknowledged;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + (index * 35)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: notification.isRead ? 0 : 1.5,
        color: notification.isRead ? null : color.withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onMarkAsRead,
          onLongPress: onAcknowledge,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: color.withValues(alpha: 0.12),
                      foregroundColor: color,
                      child: Icon(
                        isReminder
                            ? Icons.alarm_outlined
                            : Icons.notifications_active_outlined,
                        size: 20,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 34,
                      margin: const EdgeInsets.only(top: 8),
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w900,
                                    color: muted
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant
                                        : null,
                                  ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(
                            icon: isReminder
                                ? Icons.alarm_outlined
                                : Icons.campaign_outlined,
                            label: notification.type.toUpperCase(),
                            color: color,
                          ),
                          _StatusChip(
                            icon: Icons.schedule_outlined,
                            label: DateFormat(
                              'dd MMM, hh:mm a',
                            ).format(notification.createdAt),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          _StatusChip(
                            icon: notification.isAcknowledged
                                ? Icons.verified_outlined
                                : notification.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            label: notification.isAcknowledged
                                ? 'ACKNOWLEDGED'
                                : notification.isRead
                                ? 'READ'
                                : 'UNREAD',
                            color: notification.isAcknowledged
                                ? Colors.green.shade700
                                : color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
