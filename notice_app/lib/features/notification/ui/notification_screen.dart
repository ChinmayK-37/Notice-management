import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../data/notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
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

    await ref
        .read(notificationProvider.notifier)
        .acknowledge(notification.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification acknowledged')),
    );
  }

  Widget _buildSection({
    required String title,
    required List<NotificationModel> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + (index * 50)),
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
            child: _buildNotificationTile(item),
          );
        }),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final textStyle = TextStyle(
      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
      color: notification.isAcknowledged
          ? Theme.of(context).colorScheme.outline
          : null,
    );

    return Dismissible(
      key: ValueKey<int>(notification.id),
      direction: notification.isRead
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _onMarkAsRead(notification);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Mark as read'),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onLongPress: () => _onAcknowledge(notification),
            title: Text(notification.message, style: textStyle),
            subtitle: Text(
              '${notification.type} • ${DateFormat('dd MMM, hh:mm a').format(notification.createdAt)}',
              style: TextStyle(
                color: notification.isAcknowledged
                    ? Theme.of(context).colorScheme.outline
                    : null,
              ),
            ),
            trailing: notification.isAcknowledged
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final reminders = state.notifications
        .where((n) => n.type.toUpperCase() == 'REMINDER')
        .toList();
    final others = state.notifications
        .where((n) => n.type.toUpperCase() != 'REMINDER')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Builder(
        builder: (_) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          if (state.notifications.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
            child: ListView(
              children: [
                _buildSection(title: 'Reminders', items: reminders),
                _buildSection(title: 'Other Notifications', items: others),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}