import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/analytics/providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({
    required this.noticeId,
    super.key,
  });

  final String noticeId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(analyticsProvider.notifier).fetchAnalytics(widget.noticeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final analytics = state.analytics;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engagement analytics'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxW = constraints.maxWidth < 520
              ? constraints.maxWidth
              : 480.0;
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : state.error != null
                        ? _ErrorMessage(message: state.error!)
                        : analytics == null
                            ? const _ErrorMessage(
                                message: 'No analytics data available.',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Card(
                                    elevation: 0,
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.65),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.groups_outlined,
                                            size: 36,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Recipients tracked',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${analytics.totalUsers}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _PercentageCard(
                                    title: 'Read',
                                    subtitle: 'Students who opened the notice',
                                    percentage: analytics.readPercentage,
                                    color: scheme.primary,
                                    icon: Icons.visibility_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _PercentageCard(
                                    title: 'Acknowledged',
                                    subtitle: 'Students who confirmed receipt',
                                    percentage: analytics.acknowledgedPercentage,
                                    color: scheme.tertiary,
                                    icon: Icons.task_alt,
                                  ),
                                ],
                              ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
