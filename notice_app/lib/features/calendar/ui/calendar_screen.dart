import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/shared/models/notice_model.dart';
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
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );

    Future<void>.microtask(
      () => ref.read(noticeProvider.notifier).fetchNotices(),
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<DateTime, List<NoticeModel>> _groupByExpiryDate(List<NoticeModel> notices) {
    final grouped = <DateTime, List<NoticeModel>>{};
    for (final notice in notices) {
      final key = _dateOnly(notice.expiryDate);
      grouped.putIfAbsent(key, () => <NoticeModel>[]);
      grouped[key]!.add(notice);
    }
    return grouped;
  }

  bool _isExpired(NoticeModel notice) {
    final today = _dateOnly(DateTime.now());
    return _dateOnly(notice.expiryDate).isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final noticeState = ref.watch(noticeProvider);
    final grouped = _groupByExpiryDate(noticeState.notices);
    final selectedNotices = grouped[_selectedDay] ?? <NoticeModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: noticeState.isLoading && noticeState.notices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : noticeState.error != null && noticeState.notices.isEmpty
              ? Center(child: Text(noticeState.error!))
              : Column(
                  children: [
                    TableCalendar<NoticeModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      eventLoader: (day) => grouped[_dateOnly(day)] ?? [],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = _dateOnly(selectedDay);
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: selectedNotices.isEmpty
                          ? const Center(
                              child: Text('No notices for selected date.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: selectedNotices.length,
                              itemBuilder: (context, index) {
                                final notice = selectedNotices[index];
                                final expired = _isExpired(notice);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration:
                                        Duration(milliseconds: 220 + (index * 50)),
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
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => NoticeDetailScreen(
                                                  notice: notice),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          notice.title,
                                          style: TextStyle(
                                            color: expired ? Colors.red : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${notice.department} • ${DateFormat('dd MMM yyyy').format(notice.expiryDate)}',
                                          style: TextStyle(
                                            color: expired
                                                ? Colors.grey.shade700
                                                : null,
                                          ),
                                        ),
                                        trailing: expired
                                            ? const Text(
                                                'Expired',
                                                style:
                                                    TextStyle(color: Colors.red),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
