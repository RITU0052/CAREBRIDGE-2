import 'medicine.dart';

class ParentProfile {
  final int parentProfileId;
  final String name;
  final String email;
  final String? phone;
  final int? age;
  final String? bloodGroup;
  final String? medicalHistory;
  final String medicineSummary;
  final List<Medicine> medicinesToday;

  ParentProfile({
    required this.parentProfileId,
    required this.name,
    required this.email,
    this.phone,
    this.age,
    this.bloodGroup,
    this.medicalHistory,
    this.medicineSummary = '',
    this.medicinesToday = const [],
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    final rawProfileId = json['parent_profile_id'] ?? json['id'];
    return ParentProfile(
      parentProfileId: rawProfileId is int
          ? rawProfileId
          : int.parse(rawProfileId.toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      age: json['age'],
      bloodGroup: json['blood_group'],
      medicalHistory: json['medical_history'],
      medicineSummary: json['medicine_summary'] ?? '',
      medicinesToday: (json['medicines_today'] as List<dynamic>? ?? [])
          .map((m) => Medicine.fromJson(m))
          .toList(),
    );
  }
}
