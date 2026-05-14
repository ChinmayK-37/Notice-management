import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/notice/data/notice_service.dart';
import 'package:notice_app/shared/models/notice_model.dart';

final noticeServiceProvider = Provider<NoticeService>(
  (ref) => NoticeService(apiService: ref.read(apiServiceProvider)),
);

class NoticeState {
  const NoticeState({
    this.notices = const <NoticeModel>[],
    this.isLoading = false,
    this.error,
  });

  final List<NoticeModel> notices;
  final bool isLoading;
  final String? error;

  NoticeState copyWith({
    List<NoticeModel>? notices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NoticeState(
      notices: notices ?? this.notices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NoticeNotifier extends StateNotifier<NoticeState> {
  NoticeNotifier(this._noticeService) : super(const NoticeState());

  final NoticeService _noticeService;

  Future<void> fetchNotices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notices = await _noticeService.getNotices();
      state = state.copyWith(
        isLoading: false,
        notices: notices,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final noticeProvider = StateNotifierProvider<NoticeNotifier, NoticeState>(
  (ref) => NoticeNotifier(ref.read(noticeServiceProvider)),
);
