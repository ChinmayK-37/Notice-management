import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/core/notifications/local_reminder_service.dart';
import 'package:notice_app/core/services/router.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<String>? _noticeTapSubscription;

  @override
  void initState() {
    super.initState();
    _noticeTapSubscription = LocalReminderService.instance.noticeTapStream
        .listen((noticeId) {
          if (!mounted) {
            return;
          }
          ref.read(appRouterProvider).go('/notice/$noticeId');
        });
  }

  @override
  void dispose() {
    _noticeTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NoticeState>(noticeProvider, (previous, next) {
      if (!next.isLoading && next.error == null) {
        unawaited(LocalReminderService.instance.syncFromNotices(next.notices));
      }
    });

    ref.listen<AuthState>(authProvider, (previous, next) {
      final bool loggedOut =
          (previous?.isLoggedIn ?? false) && !next.isLoggedIn;
      if (loggedOut) {
        unawaited(LocalReminderService.instance.cancelAll());
      }
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Notice Circular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457C5)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFF7F8FC),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E7F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2457C5), width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
