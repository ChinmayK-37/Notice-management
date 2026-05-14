import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/notice/data/activity_item_model.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/create_notice_screen.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/features/notification/providers/notification_provider.dart';
import 'package:notice_app/shared/models/notice_model.dart';
import 'package:notice_app/shared/widgets/notice_visuals.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _priorityFilter = 'ALL';
  List<ActivityItemModel> _activity = const <ActivityItemModel>[];
  bool _activityLoading = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(noticeProvider.notifier).fetchNotices();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final isAdmin = ref.read(authProvider).isAdmin;
    await Future.wait<void>([
      ref.read(noticeProvider.notifier).fetchNotices(),
      ref.read(notificationProvider.notifier).fetchNotifications(),
      if (isAdmin) _loadActivity(),
    ]);
  }

  Future<void> _loadActivity() async {
    if (_activityLoading) {
      return;
    }
    setState(() => _activityLoading = true);
    try {
      final activity = await ref
          .read(noticeServiceProvider)
          .getRecentActivity();
      if (!mounted) {
        return;
      }
      setState(() {
        _activity = activity;
        _activityLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _activityLoading = false);
      }
    }
  }

  List<NoticeModel> _filtered(List<NoticeModel> notices) {
    final q = _searchController.text.trim().toLowerCase();
    return notices.where((notice) {
      final matchesSearch =
          q.isEmpty ||
          notice.title.toLowerCase().contains(q) ||
          notice.description.toLowerCase().contains(q) ||
          NoticeVisuals.categoryFor(notice).toLowerCase().contains(q);
      final matchesPriority =
          _priorityFilter == 'ALL' ||
          notice.priority.toUpperCase() == _priorityFilter;
      return matchesSearch && matchesPriority;
    }).toList();
  }

  void _openNotice(NoticeModel notice) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoticeDetailScreen(notice: notice),
      ),
    );
  }

  Future<void> _openCreateNotice() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateNoticeScreen()),
    );
    if (created == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticeState = ref.watch(noticeProvider);
    final notificationState = ref.watch(notificationProvider);
    final isAdmin = ref.watch(authProvider).isAdmin;
    if (isAdmin && _activity.isEmpty && !_activityLoading) {
      Future<void>.microtask(_loadActivity);
    }
    final notices = noticeState.notices;
    final displayed = _filtered(notices);
    final highPriority = notices
        .where((n) => n.priority.toUpperCase() == 'HIGH')
        .take(4)
        .toList();
    final dueSoon = notices.where(NoticeVisuals.isDueSoon).take(4).toList();
    final unreadCount = notificationState.notifications
        .where((n) => !n.isRead)
        .length;
    final totalViews = notices.fold<int>(
      0,
      (sum, notice) => sum + notice.viewCount,
    );
    final totalReplies = notices.fold<int>(
      0,
      (sum, notice) => sum + notice.replyCount,
    );
    final categories = notices.map(NoticeVisuals.categoryFor).toSet().toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'Student Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardHeader(
                          isAdmin: isAdmin,
                          totalNotices: notices.length,
                          unreadCount: isAdmin ? totalReplies : unreadCount,
                          dueSoonCount: notices
                              .where(NoticeVisuals.isDueSoon)
                              .length,
                        ),
                        const SizedBox(height: 14),
                        _StatsGrid(
                          stats: isAdmin
                              ? [
                                  _StatData(
                                    label: 'Published',
                                    value: '${notices.length}',
                                    icon: Icons.campaign_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  _StatData(
                                    label: 'Categories',
                                    value: '${categories.length}',
                                    icon: Icons.category_outlined,
                                    color: Colors.teal.shade700,
                                  ),
                                  _StatData(
                                    label: 'Views',
                                    value: '$totalViews',
                                    icon: Icons.visibility_outlined,
                                    color: Colors.orange.shade700,
                                  ),
                                  _StatData(
                                    label: 'Replies',
                                    value: '$totalReplies',
                                    icon: Icons.forum_outlined,
                                    color: Colors.green.shade700,
                                  ),
                                ]
                              : [
                                  _StatData(
                                    label: 'My notices',
                                    value: '${notices.length}',
                                    icon: Icons.campaign_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  _StatData(
                                    label: 'Due soon',
                                    value:
                                        '${notices.where(NoticeVisuals.isDueSoon).length}',
                                    icon: Icons.alarm_outlined,
                                    color: Colors.deepOrange.shade700,
                                  ),
                                  _StatData(
                                    label: 'Unread',
                                    value: '$unreadCount',
                                    icon: Icons.mark_email_unread_outlined,
                                    color: Colors.orange.shade700,
                                  ),
                                  _StatData(
                                    label: 'High priority',
                                    value: '${highPriority.length}',
                                    icon: Icons.priority_high_rounded,
                                    color: Colors.red.shade700,
                                  ),
                                ],
                        ),
                        const SizedBox(height: 18),
                        if (noticeState.isLoading && notices.isEmpty)
                          const _LoadingPanel()
                        else if (noticeState.error != null && notices.isEmpty)
                          _StatePanel(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load notices',
                            message: noticeState.error!,
                          )
                        else if (notices.isEmpty)
                          const _StatePanel(
                            icon: Icons.inbox_outlined,
                            title: 'No notices yet',
                            message:
                                'Published academic notices will appear here.',
                          )
                        else ...[
                          if (dueSoon.isNotEmpty) ...[
                            _SectionHeader(
                              title: isAdmin
                                  ? 'Deadline watch'
                                  : 'Upcoming deadlines',
                              actionLabel: '${dueSoon.length} active',
                            ),
                            const SizedBox(height: 10),
                            _HorizontalNoticeRail(
                              notices: dueSoon,
                              onTap: _openNotice,
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (highPriority.isNotEmpty) ...[
                            const _SectionHeader(
                              title: 'Important notices',
                              actionLabel: 'High priority',
                            ),
                            const SizedBox(height: 10),
                            ...highPriority.map(
                              (notice) => _NoticeCard(
                                notice: notice,
                                compact: true,
                                onTap: () => _openNotice(notice),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (isAdmin && _activity.isNotEmpty) ...[
                            const _SectionHeader(
                              title: 'Recent activity',
                              actionLabel: 'Live snapshot',
                            ),
                            const SizedBox(height: 10),
                            _ActivityFeed(items: _activity),
                            const SizedBox(height: 18),
                          ],
                          _SearchAndFilters(
                            controller: _searchController,
                            selectedPriority: _priorityFilter,
                            onSearchChanged: () => setState(() {}),
                            onPriorityChanged: (value) {
                              setState(() => _priorityFilter = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _SectionHeader(
                            title: isAdmin
                                ? 'Recent notice activity'
                                : 'Notice feed',
                            actionLabel: '${displayed.length} shown',
                          ),
                          const SizedBox(height: 10),
                          if (displayed.isEmpty)
                            const _StatePanel(
                              icon: Icons.search_off_outlined,
                              title: 'No matching notices',
                              message:
                                  'Try changing the search text or priority filter.',
                            )
                          else
                            ...displayed.map(
                              (notice) => _NoticeCard(
                                notice: notice,
                                onTap: () => _openNotice(notice),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openCreateNotice,
              icon: const Icon(Icons.add),
              label: const Text('Create Notice'),
            )
          : null,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isAdmin,
    required this.totalNotices,
    required this.unreadCount,
    required this.dueSoonCount,
  });

  final bool isAdmin;
  final int totalNotices;
  final int unreadCount;
  final int dueSoonCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greeting = _greeting();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.school,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      isAdmin
                          ? 'Manage academic communication with confidence'
                          : 'Your academic updates, deadlines, and alerts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                icon: Icons.campaign_outlined,
                label: '$totalNotices notices',
              ),
              _HeaderChip(
                icon: isAdmin
                    ? Icons.forum_outlined
                    : Icons.mark_email_unread_outlined,
                label: isAdmin ? '$unreadCount replies' : '$unreadCount unread',
              ),
              _HeaderChip(
                icon: Icons.alarm_outlined,
                label: '$dueSoonCount due soon',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 2.35 : 1.72,
          ),
          itemBuilder: (context, index) => _StatCard(data: stats[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.13),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          actionLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HorizontalNoticeRail extends StatelessWidget {
  const _HorizontalNoticeRail({required this.notices, required this.onTap});

  final List<NoticeModel> notices;
  final ValueChanged<NoticeModel> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: notices.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final notice = notices[index];
          final color = NoticeVisuals.priorityColor(context, notice.priority);
          return SizedBox(
            width: 250,
            child: Card(
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTap(notice),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alarm_outlined, size: 18, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              NoticeVisuals.deadlineLabel(notice.expiryDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        NoticeVisuals.categoryFor(notice),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.items});

  final List<ActivityItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final item in items.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _activityColor(
                        context,
                        item.type,
                      ).withValues(alpha: 0.12),
                      foregroundColor: _activityColor(context, item.type),
                      child: Icon(_activityIcon(item.type), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM').format(item.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  IconData _activityIcon(String type) {
    switch (type.toUpperCase()) {
      case 'REPLY':
        return Icons.forum_outlined;
      case 'ACKNOWLEDGEMENT':
        return Icons.task_alt_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _activityColor(BuildContext context, String type) {
    switch (type.toUpperCase()) {
      case 'REPLY':
        return Colors.indigo.shade700;
      case 'ACKNOWLEDGEMENT':
        return Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.selectedPriority,
    required this.onSearchChanged,
    required this.onPriorityChanged,
  });

  final TextEditingController controller;
  final String selectedPriority;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              onChanged: (_) => onSearchChanged(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, content, or category',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onSearchChanged();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const ['ALL', 'HIGH', 'MEDIUM', 'LOW'])
                  ChoiceChip(
                    label: Text(value == 'ALL' ? 'All priorities' : value),
                    selected: selectedPriority == value,
                    onSelected: (_) => onPriorityChanged(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.onTap,
    this.compact = false,
  });

  final NoticeModel notice;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final priorityColor = NoticeVisuals.priorityColor(context, notice.priority);
    final category = NoticeVisuals.categoryFor(notice);
    final isUrgent = notice.priority.toUpperCase() == 'HIGH';
    final expiry = notice.expiryDate;

    return Card(
      elevation: isUrgent ? 2 : 1,
      margin: EdgeInsets.only(bottom: compact ? 10 : 12),
      shadowColor: priorityColor.withValues(alpha: isUrgent ? 0.25 : 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (notice.pinned)
                            _MetaChip(
                              icon: Icons.push_pin_outlined,
                              label: 'PINNED',
                              color: Colors.indigo.shade700,
                            ),
                          _MetaChip(
                            icon: NoticeVisuals.priorityIcon(notice.priority),
                            label: notice.priority.toUpperCase(),
                            color: priorityColor,
                          ),
                          _MetaChip(
                            icon: NoticeVisuals.categoryIcon(category),
                            label: category,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: NoticeVisuals.deadlineLabel(expiry),
                            color: NoticeVisuals.isDueSoon(notice)
                                ? Colors.deepOrange.shade700
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 7),
                        Text(
                          notice.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _InlineMeta(
                            icon: Icons.groups_outlined,
                            text: notice.department,
                          ),
                          if (expiry != null)
                            _InlineMeta(
                              icon: Icons.event_outlined,
                              text: DateFormat('dd MMM yyyy').format(expiry),
                            ),
                          _InlineMeta(
                            icon: notice.isAcknowledged
                                ? Icons.verified_outlined
                                : notice.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            text: notice.isAcknowledged
                                ? 'Acknowledged'
                                : notice.isRead
                                ? 'Read'
                                : 'Unread',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
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

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 36, color: scheme.primary),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
