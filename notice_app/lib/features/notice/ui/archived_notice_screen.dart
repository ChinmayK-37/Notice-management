import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/shared/models/notice_model.dart';
import 'package:notice_app/shared/widgets/notice_visuals.dart';

class ArchivedNoticeScreen extends ConsumerStatefulWidget {
  const ArchivedNoticeScreen({super.key});

  @override
  ConsumerState<ArchivedNoticeScreen> createState() =>
      _ArchivedNoticeScreenState();
}

class _ArchivedNoticeScreenState extends ConsumerState<ArchivedNoticeScreen> {
  List<NoticeModel> _notices = const <NoticeModel>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notices = await ref
          .read(noticeServiceProvider)
          .getArchivedNotices();
      if (!mounted) {
        return;
      }
      setState(() {
        _notices = notices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _restore(NoticeModel notice) async {
    try {
      await ref.read(noticeServiceProvider).restoreNotice(notice.id);
      await ref.read(noticeProvider.notifier).fetchNotices();
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notice restored')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived notices')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ArchiveHeader(count: _notices.length),
                          const SizedBox(height: 14),
                          if (_error != null)
                            _ArchiveState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Archive unavailable',
                              message: _error!,
                            )
                          else if (_notices.isEmpty)
                            const _ArchiveState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No archived notices',
                              message:
                                  'Expired notices older than 15 days will be retained here for audit and analytics.',
                            )
                          else
                            ..._notices.map(
                              (notice) => _ArchivedNoticeTile(
                                notice: notice,
                                onOpen: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        NoticeDetailScreen(notice: notice),
                                  ),
                                ),
                                onRestore: () => _restore(notice),
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

class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
            child: const Icon(Icons.archive_outlined),
          ),
          Text(
            '$count archived notices',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ArchivedNoticeTile extends StatelessWidget {
  const _ArchivedNoticeTile({
    required this.notice,
    required this.onOpen,
    required this.onRestore,
  });

  final NoticeModel notice;
  final VoidCallback onOpen;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final color = NoticeVisuals.priorityColor(context, notice.priority);
    final expiry = notice.expiryDate;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.archive_outlined,
                      color: color,
                      size: 18,
                    ),
                    label: const Text('ARCHIVED'),
                  ),
                  Chip(label: Text(notice.priority.toUpperCase())),
                  if (expiry != null)
                    Chip(label: Text(DateFormat('dd MMM yyyy').format(expiry))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                notice.department,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Restore'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveState extends StatelessWidget {
  const _ArchiveState({
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
