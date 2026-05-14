class NoticeModel {
  const NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.priority,
    required this.expiryDate,
    required this.readStatus,
    this.notificationId,
    required this.isRead,
    required this.isAcknowledged,
  });

  final String id;
  final String title;
  final String description;
  final String department;
  final String priority;
  final DateTime expiryDate;
  final bool readStatus;
  final int? notificationId;
  final bool isRead;
  final bool isAcknowledged;

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      priority: (json['priority'] ?? 'LOW').toString(),
      expiryDate: DateTime.tryParse((json['expiryDate'] ?? '').toString()) ??
          DateTime.now(),
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
      'department': department,
      'priority': priority,
      'expiryDate': expiryDate.toIso8601String(),
      'readStatus': readStatus,
      'notificationId': notificationId,
      'isRead': isRead,
      'isAcknowledged': isAcknowledged,
    };
  }
}
