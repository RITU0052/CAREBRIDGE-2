class AppointmentModel {
  final String id;
  final String parentId;
  final String doctorId;
  final String? serviceId;
  final String appointmentDate;
  final String timeSlot;
  final String appointmentType;
  final String patientName;
  final String? patientPhone;
  final String? patientNotes;
  final String status; // 'scheduled', 'completed', 'cancelled', 'rescheduled'
  final String? previousDateTime;
  final String? rescheduleReason;
  final int? reminderTimeMinutes;
  final String? virtualLink;
  final double fee;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorImage;

  AppointmentModel({
    required this.id,
    required this.parentId,
    required this.doctorId,
    this.serviceId,
    required this.appointmentDate,
    required this.timeSlot,
    this.appointmentType = 'In-person',
    required this.patientName,
    this.patientPhone,
    this.patientNotes,
    this.status = 'scheduled',
    this.previousDateTime,
    this.rescheduleReason,
    this.reminderTimeMinutes,
    this.virtualLink,
    required this.fee,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorImage,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      parentId: json['parent_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString(),
      appointmentDate: json['appointment_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      appointmentType: json['appointment_type'] ?? 'In-person',
      patientName: json['patient_name'] ?? 'Patient',
      patientPhone: json['patient_phone'],
      patientNotes: json['patient_notes'],
      status: json['status'] ?? 'scheduled',
      previousDateTime: json['previous_date_time'],
      rescheduleReason: json['reschedule_reason'],
      reminderTimeMinutes: json['reminder_time_minutes'],
      virtualLink: json['virtual_link'],
      fee: (json['fee'] is num) ? (json['fee'] as num).toDouble() : 50.0,
      doctorName: json['doctor_name'] ?? 'Doctor',
      doctorSpecialty: json['doctor_specialty'] ?? 'General Physician',
      doctorImage: json['doctor_image'],
    );
  }

  bool get isScheduled => status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'rescheduled';
  bool get isRescheduled => status.toLowerCase() == 'rescheduled';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isVirtual => appointmentType.toLowerCase() == 'virtual';
}
