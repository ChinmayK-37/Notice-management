import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';
import 'package:notice_app/features/notice/ui/notice_detail_screen.dart';
import 'package:notice_app/shared/models/notice_model.dart';

class NoticeRouteScreen extends ConsumerStatefulWidget {
  const NoticeRouteScreen({required this.noticeId, super.key});

  final String noticeId;

  @override
  ConsumerState<NoticeRouteScreen> createState() => _NoticeRouteScreenState();
}

class _NoticeRouteScreenState extends ConsumerState<NoticeRouteScreen> {
  NoticeModel? _notice;
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
      final notice = await ref
          .read(noticeServiceProvider)
          .getNoticeById(widget.noticeId);
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = notice;
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

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice != null) {
      return NoticeDetailScreen(notice: notice);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notice details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not open notice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error ?? 'The notice may no longer be active.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
