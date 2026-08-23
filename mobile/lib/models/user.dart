class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'child', 'parent', 'doctor', 'admin'
  final String? linkedUserId;
  final String? bio;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.linkedUserId,
    this.bio,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'parent',
      linkedUserId: json['linked_user_id']?.toString(),
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'linked_user_id': linkedUserId,
        'bio': bio,
      };

  bool get isChild => role == 'child';
  bool get isParent => role == 'parent';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';
}
