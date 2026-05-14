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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(child: Text(state.error!))
                : analytics == null
                    ? const Center(child: Text('No analytics data available.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PercentageCard(
                            title: 'Read',
                            percentage: analytics.readPercentage,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _PercentageCard(
                            title: 'Acknowledged',
                            percentage: analytics.acknowledgedPercentage,
                            color: Colors.green,
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
    required this.percentage,
    required this.color,
  });

  final String title;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title: ${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}
