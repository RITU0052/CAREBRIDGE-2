class DoctorModel {
  final String id;
  final String? userId;
  final String name;
  final String specialty;
  final int experienceYears;
  final String qualifications;
  final String languages;
  final double consultationFee;
  final String location;
  final String bio;
  final String consultationType; // 'In-person', 'Virtual', 'Both'
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String? profileImage;
  final String availableDays;

  DoctorModel({
    required this.id,
    this.userId,
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.qualifications,
    required this.languages,
    required this.consultationFee,
    required this.location,
    required this.bio,
    this.consultationType = 'Both',
    this.isVerified = true,
    this.rating = 4.9,
    this.reviewCount = 12,
    this.profileImage,
    this.availableDays = 'Mon,Tue,Wed,Thu,Fri',
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? 'General Physician',
      experienceYears: json['experience_years'] ?? 5,
      qualifications: json['qualifications'] ?? 'MD, MBBS',
      languages: json['languages'] ?? 'English',
      consultationFee: (json['consultation_fee'] is num) ? (json['consultation_fee'] as num).toDouble() : 50.0,
      location: json['location'] ?? 'CareBridge Clinic',
      bio: json['bio'] ?? '',
      consultationType: json['consultation_type'] ?? 'Both',
      isVerified: json['is_verified'] ?? true,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.9,
      reviewCount: json['review_count'] ?? 12,
      profileImage: json['profile_image'],
      availableDays: json['available_days'] ?? 'Mon,Tue,Wed,Thu,Fri',
    );
  }
}
