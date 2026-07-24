class ProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isHead;
  final String entityName;
  final String roleName;

  ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isHead,
    required this.entityName,
    required this.roleName,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final entity = json['entity'] as Map<String, dynamic>? ?? {};
    final role = json['role'] as Map<String, dynamic>? ?? {};
    return ProfileData(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isHead: json['isHead'] == true,
      entityName: (entity['name'] ?? '').toString(),
      roleName: (role['name'] ?? '').toString(),
    );
  }
}
