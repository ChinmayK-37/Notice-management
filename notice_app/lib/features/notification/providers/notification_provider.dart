import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/features/notification/data/notification_service.dart';

import '../data/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(apiService: ref.read(apiServiceProvider)),
);

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService service;

  NotificationNotifier(this.service) : super(const NotificationState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await service.getNotifications();

      state = NotificationState(notifications: data, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getMessage(error),
      );
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await service.markAsRead(id);
      final updated = state.notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (error) {
      state = state.copyWith(error: ErrorHandler.getMessage(error));
    }
  }

  Future<void> acknowledge(int id) async {
    try {
      await service.acknowledge(id);
      final updated = state.notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true, isAcknowledged: true);
        }
        return item;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (error) {
      state = state.copyWith(error: ErrorHandler.getMessage(error));
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final service = ref.read(notificationServiceProvider);
      return NotificationNotifier(service);
    });
