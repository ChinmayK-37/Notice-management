class NoticeModel {
  const NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.department,
    required this.priority,
    required this.pinned,
    required this.state,
    required this.viewCount,
    required this.replyCount,
    this.attachmentFileName,
    this.expiryDate,
    this.createdBy,
    required this.readStatus,
    this.notificationId,
    required this.isRead,
    required this.isAcknowledged,
  });

  final String id;
  final String title;
  final String description;
  final String category;

  /// Audience summary from API `targets` (or legacy `department`), e.g. "All students".
  final String department;
  final String priority;
  final bool pinned;
  final String state;
  final int viewCount;
  final int replyCount;
  final String? attachmentFileName;
  final DateTime? expiryDate;
  final String? createdBy;
  final bool readStatus;
  final int? notificationId;
  final bool isRead;
  final bool isAcknowledged;

  static String _audienceFromJson(Map<String, dynamic> json) {
    final dynamic direct = json['department'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final dynamic targets = json['targets'];
    if (targets is! List || targets.isEmpty) {
      return 'All students';
    }
    final parts = <String>[];
    for (final item in targets) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final d = (item['department'] ?? '').toString().trim();
      final y = item['year'];
      final division = (item['division'] ?? '').toString().trim();
      final batch = (item['batch'] ?? '').toString().trim();
      if (d.isEmpty) {
        continue;
      }
      final refinements = <String>[
        if (division.isNotEmpty) 'Div $division',
        if (batch.isNotEmpty) 'Batch $batch',
      ];
      final suffix = refinements.isEmpty ? '' : ' (${refinements.join(', ')})';
      if (y is num) {
        parts.add('$d - Year ${y.toInt()}$suffix');
      } else if (y != null) {
        parts.add('$d - Year $y$suffix');
      } else {
        parts.add('$d$suffix');
      }
    }
    return parts.isEmpty ? 'All students' : parts.join('; ');
  }

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawExpiry = json['expiryDate'];
    DateTime? expiry;
    if (rawExpiry != null) {
      final parsed = DateTime.tryParse(rawExpiry.toString());
      expiry = parsed?.isUtc == true ? parsed!.toLocal() : parsed;
    }

    return NoticeModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      department: _audienceFromJson(json),
      priority: (json['priority'] ?? 'LOW').toString(),
      pinned: json['pinned'] == true || json['isPinned'] == true,
      state: (json['state'] ?? 'ACTIVE').toString(),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      attachmentFileName: json['attachmentFileName']?.toString(),
      expiryDate: expiry,
      createdBy: json['createdBy']?.toString(),
      readStatus: json['readStatus'] == true,
      notificationId: json['notificationId'] is int
          ? json['notificationId'] as int
          : int.tryParse((json['notificationId'] ?? '').toString()),
      isRead: json['isRead'] == true || json['readStatus'] == true,
      isAcknowledged: json['isAcknowledged'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'department': department,
      'priority': priority,
      'pinned': pinned,
      'state': state,
      'viewCount': viewCount,
      'replyCount': replyCount,
      'attachmentFileName': attachmentFileName,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdBy': createdBy,
      'readStatus': readStatus,
      'notificationId': notificationId,
      'isRead': isRead,
      'isAcknowledged': isAcknowledged,
    };
  }
}
