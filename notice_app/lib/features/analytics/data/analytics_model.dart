class AnalyticsModel {
  const AnalyticsModel({
    required this.totalUsers,
    required this.readCount,
    required this.unreadCount,
    required this.acknowledgedCount,
    required this.viewCount,
    required this.replyCount,
    required this.readPercentage,
    required this.acknowledgedPercentage,
  });

  final int totalUsers;
  final int readCount;
  final int unreadCount;
  final int acknowledgedCount;
  final int viewCount;
  final int replyCount;
  final double readPercentage;
  final double acknowledgedPercentage;

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final int total = (json['totalUsers'] as num?)?.toInt() ?? 0;
    final int readCount = (json['readCount'] as num?)?.toInt() ?? 0;
    final int unreadCount =
        (json['unreadCount'] as num?)?.toInt() ??
        (total - readCount).clamp(0, total);
    final int acknowledgedCount =
        (json['acknowledgedCount'] as num?)?.toInt() ?? 0;
    final int viewCount = (json['viewCount'] as num?)?.toInt() ?? 0;
    final int replyCount = (json['replyCount'] as num?)?.toInt() ?? 0;

    final double? readPct = (json['readPercentage'] as num?)?.toDouble();
    final double? ackPct = (json['acknowledgedPercentage'] as num?)?.toDouble();
    if (readPct != null || ackPct != null) {
      return AnalyticsModel(
        totalUsers: total,
        readCount: readCount,
        unreadCount: unreadCount,
        acknowledgedCount: acknowledgedCount,
        viewCount: viewCount,
        replyCount: replyCount,
        readPercentage: readPct ?? 0,
        acknowledgedPercentage: ackPct ?? 0,
      );
    }

    // Legacy: counts only (approximate percentages).
    return AnalyticsModel(
      totalUsers: total,
      readCount: readCount,
      unreadCount: unreadCount,
      acknowledgedCount: acknowledgedCount,
      viewCount: viewCount,
      replyCount: replyCount,
      readPercentage: total == 0 ? 0 : (readCount * 100.0) / total,
      acknowledgedPercentage: total == 0
          ? 0
          : (acknowledgedCount * 100.0) / total,
    );
  }
}
