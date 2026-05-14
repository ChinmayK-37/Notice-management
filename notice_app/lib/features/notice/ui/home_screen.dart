import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/shared/models/notice_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(noticeProvider.notifier).fetchNotices(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noticeState = ref.watch(noticeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        actions: [
          IconButton(
            tooltip: 'Calendar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Calendar from bottom tabs')),
              );
            },
            icon: const Icon(Icons.calendar_today_outlined),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Open Notifications from bottom tabs'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(noticeProvider.notifier).fetchNotices(),
        child: Builder(
          builder: (context) {
            if (noticeState.isLoading && noticeState.notices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (noticeState.error != null && noticeState.notices.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(noticeState.error!)),
                ],
              );
            }

            if (noticeState.notices.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No notices found.')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: noticeState.notices.length,
              itemBuilder: (context, index) {
                final notice = noticeState.notices[index];

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 70)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _NoticeCard(
                    notice: notice,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NoticeDetailScreen(notice: notice),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      )
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.onTap,
  });

  final NoticeModel notice;
  final VoidCallback onTap;

  Color _priorityColor(BuildContext context) {
    switch (notice.priority.toUpperCase()) {
      case 'HIGH':
        return Colors.red.shade700;
      case 'MEDIUM':
        return Colors.orange.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _expiryText() {
    final expiry = notice.expiryDate;
    if (expiry == null) {
      return 'No expiry';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final daysLeft = expiryDay.difference(today).inDays;

    if (daysLeft <= 0) {
      return 'Expires today';
    }
    if (daysLeft == 1) {
      return '1 day left';
    }
    return '$daysLeft days left';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(context);
    final expiry = notice.expiryDate;
    final String expiryChipText = expiry == null
        ? 'No expiry date'
        : '${_expiryText()} • ${DateFormat('dd MMM yyyy').format(expiry)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                notice.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notice.priority.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: priorityColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expiryChipText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Audience: ${notice.department}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
