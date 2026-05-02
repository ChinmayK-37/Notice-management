class AnalyticsModel {
  const AnalyticsModel({
    required this.totalUsers,
    required this.readCount,
    required this.acknowledgedCount,
  });

  final int totalUsers;
  final int readCount;
  final int acknowledgedCount;

  double get readPercentage {
    if (totalUsers == 0) {
      return 0;
    }
    return (readCount / totalUsers) * 100;
  }

  double get acknowledgedPercentage {
    if (totalUsers == 0) {
      return 0;
    }
    return (acknowledgedCount / totalUsers) * 100;
  }

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      acknowledgedCount: (json['acknowledgedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
