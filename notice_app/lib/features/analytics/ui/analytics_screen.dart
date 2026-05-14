import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/analytics/providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({required this.noticeId, super.key});

  final String noticeId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(analyticsProvider.notifier).fetchAnalytics(widget.noticeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final analytics = state.analytics;
    final scheme = Theme.of(context).colorScheme;

    final readCount = analytics?.readCount ?? 0;
    final ackCount = analytics?.acknowledgedCount ?? 0;
    final unreadCount = analytics?.unreadCount ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Engagement analytics')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(analyticsProvider.notifier)
                .fetchAnalytics(widget.noticeId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (state.isLoading && analytics == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 96),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && analytics == null)
                  _StatePanel(
                    icon: Icons.cloud_off_outlined,
                    title: 'Analytics unavailable',
                    message: state.error!,
                  )
                else if (analytics == null)
                  const _StatePanel(
                    icon: Icons.insights_outlined,
                    title: 'No analytics yet',
                    message:
                        'Engagement data appears once notifications are created.',
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          child: const Icon(Icons.insights_outlined),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notice engagement',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                              Text(
                                '${analytics.totalUsers} targeted recipients',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MetricGrid(
                    metrics: [
                      _MetricData(
                        label: 'Reads',
                        value: '$readCount',
                        icon: Icons.visibility_outlined,
                        color: scheme.primary,
                      ),
                      _MetricData(
                        label: 'Unread',
                        value: '$unreadCount',
                        icon: Icons.mark_email_unread_outlined,
                        color: Colors.orange.shade700,
                      ),
                      _MetricData(
                        label: 'Acknowledged',
                        value: '$ackCount',
                        icon: Icons.task_alt_outlined,
                        color: Colors.green.shade700,
                      ),
                      _MetricData(
                        label: 'Pending ack',
                        value: '${analytics.totalUsers - ackCount}',
                        icon: Icons.pending_actions_outlined,
                        color: Colors.blueGrey.shade700,
                      ),
                      _MetricData(
                        label: 'Views',
                        value: '${analytics.viewCount}',
                        icon: Icons.remove_red_eye_outlined,
                        color: Colors.indigo.shade700,
                      ),
                      _MetricData(
                        label: 'Replies',
                        value: '${analytics.replyCount}',
                        icon: Icons.forum_outlined,
                        color: Colors.deepPurple.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PercentageCard(
                    title: 'Read rate',
                    subtitle: 'Students who opened the notice',
                    percentage: analytics.readPercentage,
                    color: scheme.primary,
                    icon: Icons.visibility_outlined,
                  ),
                  const SizedBox(height: 12),
                  _PercentageCard(
                    title: 'Acknowledgement rate',
                    subtitle: 'Students who confirmed receipt',
                    percentage: analytics.acknowledgedPercentage,
                    color: Colors.green.shade700,
                    icon: Icons.task_alt,
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

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 2.2 : 1.65,
          ),
          itemBuilder: (context, index) => _MetricCard(data: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _PercentageCard extends StatelessWidget {
  const _PercentageCard({
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double percentage;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (percentage / 100).clamp(0.0, 1.0);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
                minHeight: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
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
