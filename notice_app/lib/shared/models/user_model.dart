class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.year,
    this.division,
    this.batch,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String department;
  final int year;
  final String? division;
  final String? batch;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'STUDENT').toString(),
      department: (json['department'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? 1,
      division: json['division']?.toString(),
      batch: json['batch']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'year': year,
      'division': division,
      'batch': batch,
    };
  }
}
