class ActivityItemModel {
  const ActivityItemModel({
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.noticeId,
  });

  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final int? noticeId;

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityItemModel(
      type: (json['type'] ?? 'ACTIVITY').toString(),
      title: (json['title'] ?? 'Activity').toString(),
      message: (json['message'] ?? '').toString(),
      noticeId: (json['noticeId'] as num?)?.toInt(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
