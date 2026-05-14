import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/shared/models/notice_model.dart';
import 'package:notice_app/shared/widgets/notice_visuals.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = NoticeVisuals.dateOnly(_focusedDay);
    Future<void>.microtask(
      () => ref.read(noticeProvider.notifier).fetchNotices(),
    );
  }

  Map<DateTime, List<NoticeModel>> _groupByExpiryDate(
    List<NoticeModel> notices,
  ) {
    final grouped = <DateTime, List<NoticeModel>>{};
    for (final notice in notices) {
      final expiry = notice.expiryDate;
      if (expiry == null) {
        continue;
      }
      final key = NoticeVisuals.dateOnly(expiry);
      grouped.putIfAbsent(key, () => <NoticeModel>[]).add(notice);
    }
    return grouped;
  }

  List<NoticeModel> _upcoming(List<NoticeModel> notices) {
    final now = DateTime.now();
    final sorted =
        notices
            .where((n) => n.expiryDate != null && n.expiryDate!.isAfter(now))
            .toList()
          ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return sorted.take(4).toList();
  }

  Future<void> _refresh() {
    return ref.read(noticeProvider.notifier).fetchNotices();
  }

  @override
  Widget build(BuildContext context) {
    final noticeState = ref.watch(noticeProvider);
    final notices = noticeState.notices;
    final grouped = _groupByExpiryDate(notices);
    final selectedNotices = grouped[_selectedDay] ?? <NoticeModel>[];
    final upcoming = _upcoming(notices);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: noticeState.isLoading && notices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : noticeState.error != null && notices.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  _EmptyCalendarState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Calendar unavailable',
                    message: noticeState.error!,
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (upcoming.isNotEmpty) ...[
                                _UpcomingSummary(notices: upcoming),
                                const SizedBox(height: 12),
                              ],
                              Card(
                                elevation: 0,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TableCalendar<NoticeModel>(
                                    firstDay: DateTime.utc(2020, 1, 1),
                                    lastDay: DateTime.utc(2100, 12, 31),
                                    focusedDay: _focusedDay,
                                    selectedDayPredicate: (day) =>
                                        isSameDay(day, _selectedDay),
                                    eventLoader: (day) =>
                                        grouped[NoticeVisuals.dateOnly(day)] ??
                                        [],
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = NoticeVisuals.dateOnly(
                                          selectedDay,
                                        );
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                    headerStyle: const HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                    ),
                                    calendarStyle: CalendarStyle(
                                      markersMaxCount: 3,
                                      markerDecoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      todayDecoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.28),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedDecoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SelectedDayHeader(
                                date: _selectedDay,
                                count: selectedNotices.length,
                              ),
                              const SizedBox(height: 10),
                              if (selectedNotices.isEmpty)
                                _EmptyCalendarState(
                                  icon: grouped.isEmpty
                                      ? Icons.event_busy_outlined
                                      : Icons.event_available_outlined,
                                  title: grouped.isEmpty
                                      ? 'No scheduled deadlines'
                                      : 'No notices for this date',
                                  message: grouped.isEmpty
                                      ? 'Notices with expiry dates will populate this academic calendar.'
                                      : 'Select a marked day or pull to refresh for the latest notices.',
                                )
                              else
                                ...selectedNotices.map(
                                  (notice) => _CalendarNoticeTile(
                                    notice: notice,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => NoticeDetailScreen(
                                            notice: notice,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _UpcomingSummary extends StatelessWidget {
  const _UpcomingSummary({required this.notices});

  final List<NoticeModel> notices;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming timeline',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...notices.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: NoticeVisuals.priorityColor(
                          context,
                          notice.priority,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        notice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      NoticeVisuals.deadlineLabel(notice.expiryDate),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final today = NoticeVisuals.dateOnly(DateTime.now());
    final selected = NoticeVisuals.dateOnly(date);
    final label = selected == today
        ? 'Today'
        : selected.isBefore(today)
        ? 'Expired / past'
        : 'Upcoming';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(date),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Chip(
          avatar: const Icon(Icons.event_note_outlined, size: 18),
          label: Text('$count notices'),
        ),
      ],
    );
  }
}

class _CalendarNoticeTile extends StatelessWidget {
  const _CalendarNoticeTile({required this.notice, required this.onTap});

  final NoticeModel notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = NoticeVisuals.priorityColor(context, notice.priority);
    final category = NoticeVisuals.categoryFor(notice);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(NoticeVisuals.categoryIcon(category)),
        ),
        title: Text(
          notice.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${notice.priority.toUpperCase()} - $category - ${notice.department}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          NoticeVisuals.isExpired(notice)
              ? Icons.history_outlined
              : Icons.arrow_forward_ios_rounded,
          size: 18,
        ),
      ),
    );
  }
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState({
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
