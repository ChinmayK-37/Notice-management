class AnalyticsModel {
  const AnalyticsModel({
    required this.totalUsers,
    required this.readPercentage,
    required this.acknowledgedPercentage,
  });

  final int totalUsers;
  final double readPercentage;
  final double acknowledgedPercentage;

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final int total = (json['totalUsers'] as num?)?.toInt() ?? 0;

    final double? readPct = (json['readPercentage'] as num?)?.toDouble();
    final double? ackPct = (json['acknowledgedPercentage'] as num?)?.toDouble();
    if (readPct != null || ackPct != null) {
      return AnalyticsModel(
        totalUsers: total,
        readPercentage: readPct ?? 0,
        acknowledgedPercentage: ackPct ?? 0,
      );
    }

    // Legacy: counts only (approximate percentages).
    final int readCount = (json['readCount'] as num?)?.toInt() ?? 0;
    final int acknowledgedCount =
        (json['acknowledgedCount'] as num?)?.toInt() ?? 0;
    return AnalyticsModel(
      totalUsers: total,
      readPercentage: total == 0 ? 0 : (readCount * 100.0) / total,
      acknowledgedPercentage: total == 0
          ? 0
          : (acknowledgedCount * 100.0) / total,
    );
  }
}
