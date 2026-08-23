class HealthcareServiceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final bool isActive;

  HealthcareServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    this.isActive = true,
  });

  factory HealthcareServiceModel.fromJson(Map<String, dynamic> json) {
    return HealthcareServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      icon: json['icon'] ?? 'activity',
      isActive: json['is_active'] ?? true,
    );
  }
}
