class Medicine {
  final String medicineId;
  final String medicineName;
  final String? dose;
  final String? doseUnit;
  final String? timeOfDay;
  final String? foodInstruction;
  final String? diseaseCondition;
  final String? frequency;
  final String? startDate;
  final String? endDate;
  String status; // 'pending' | 'taken' | 'skipped' | 'snoozed'

  Medicine({
    required this.medicineId,
    required this.medicineName,
    this.dose,
    this.doseUnit,
    this.timeOfDay,
    this.foodInstruction,
    this.diseaseCondition,
    this.frequency,
    this.startDate,
    this.endDate,
    this.status = 'pending',
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['medicine_id'] ?? '';
    return Medicine(
      medicineId: rawId.toString(),
      medicineName: json['medicine_name'] ?? '',
      dose: json['dose']?.toString(),
      doseUnit: json['dose_unit']?.toString() ?? 'tablet',
      timeOfDay: json['time_of_day']?.toString(),
      foodInstruction: json['food_instruction']?.toString() ?? 'After Food',
      diseaseCondition: json['disease_condition']?.toString(),
      frequency: json['frequency']?.toString() ?? 'Once a day',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      status: json['today_status'] ?? json['status'] ?? 'pending',
    );
  }
}
