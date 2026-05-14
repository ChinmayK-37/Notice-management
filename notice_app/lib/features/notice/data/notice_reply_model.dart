class NoticeReplyModel {
  const NoticeReplyModel({
    required this.id,
    required this.noticeId,
    required this.userName,
    required this.userEmail,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final int noticeId;
  final String userName;
  final String userEmail;
  final String message;
  final DateTime createdAt;

  factory NoticeReplyModel.fromJson(Map<String, dynamic> json) {
    return NoticeReplyModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      noticeId: (json['noticeId'] as num?)?.toInt() ?? 0,
      userName: (json['userName'] ?? 'Student').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
