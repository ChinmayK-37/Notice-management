class NotificationModel {
  final int id;
  final String message;
  final String type; // NORMAL / REMINDER
  final bool isRead;
  final bool isAcknowledged;
  final DateTime createdAt;
  final int? noticeId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.isAcknowledged,
    required this.createdAt,
    this.noticeId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'NORMAL').toString(),
      isRead: json['isRead'] == true,
      isAcknowledged: json['isAcknowledged'] == true,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      noticeId: json['noticeId'] is int
          ? json['noticeId'] as int
          : int.tryParse((json['noticeId'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'type': type,
      'isRead': isRead,
      'isAcknowledged': isAcknowledged,
      'createdAt': createdAt.toIso8601String(),
      'noticeId': noticeId,
    };
  }

  NotificationModel copyWith({bool? isRead, bool? isAcknowledged}) {
    return NotificationModel(
      id: id,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      createdAt: createdAt,
      noticeId: noticeId,
    );
  }
}
