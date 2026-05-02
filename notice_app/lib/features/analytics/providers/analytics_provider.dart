import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/features/analytics/data/analytics_model.dart';
import 'package:notice_app/features/analytics/data/analytics_service.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    apiService: ref.read(apiServiceProvider),
  ),
);

class AnalyticsState {
  const AnalyticsState({
    this.analytics,
    this.isLoading = false,
    this.error,
  });

  final AnalyticsModel? analytics;
  final bool isLoading;
  final String? error;

  AnalyticsState copyWith({
    AnalyticsModel? analytics,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this._service) : super(const AnalyticsState());

  final AnalyticsService _service;

  Future<void> fetchAnalytics(String noticeId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final analytics = await _service.getAnalytics(noticeId);
      state = state.copyWith(
        isLoading: false,
        analytics: analytics,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getMessage(error),
      );
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref.read(analyticsServiceProvider)),
);
