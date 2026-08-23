/// Health vital reading model — BP, Sugar, Heart Rate, Oxygen, Temp, Weight
class HealthVital {
  final int? id;
  final int parentProfileId;
  final String type; // 'bp', 'sugar', 'heart_rate', 'oxygen', 'temperature', 'weight'
  final String value; // primary value, e.g. "120/80" for BP, "105" for sugar
  final String? unit;
  final String? note;
  final DateTime recordedAt;

  HealthVital({
    this.id,
    required this.parentProfileId,
    required this.type,
    required this.value,
    this.unit,
    this.note,
    required this.recordedAt,
  });

  factory HealthVital.fromJson(Map<String, dynamic> json) {
    return HealthVital(
      id: json['id'],
      parentProfileId: json['parent_profile_id'] ?? 0,
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'],
      note: json['note'],
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'parent_profile_id': parentProfileId,
        'type': type,
        'value': value,
        if (unit != null) 'unit': unit,
        if (note != null) 'note': note,
        'recorded_at': recordedAt.toIso8601String(),
      };

  /// Returns human-readable label for this vital type
  String get label {
    switch (type) {
      case 'bp':
        return 'Blood Pressure';
      case 'sugar':
        return 'Blood Sugar';
      case 'heart_rate':
        return 'Heart Rate';
      case 'oxygen':
        return 'Oxygen (SpO₂)';
      case 'temperature':
        return 'Temperature';
      case 'weight':
        return 'Weight';
      default:
        return type.toUpperCase();
    }
  }

  String get displayUnit {
    if (unit != null) return unit!;
    switch (type) {
      case 'bp':
        return 'mmHg';
      case 'sugar':
        return 'mg/dL';
      case 'heart_rate':
        return 'bpm';
      case 'oxygen':
        return '%';
      case 'temperature':
        return '°C';
      case 'weight':
        return 'kg';
      default:
        return '';
    }
  }

  /// Simple normal-range check for status badge
  String get status {
    switch (type) {
      case 'sugar':
        final v = double.tryParse(value) ?? 0;
        if (v < 70 || v > 200) return 'critical';
        if (v > 140) return 'warning';
        return 'normal';
      case 'heart_rate':
        final v = double.tryParse(value) ?? 0;
        if (v < 40 || v > 120) return 'critical';
        if (v < 50 || v > 100) return 'warning';
        return 'normal';
      case 'oxygen':
        final v = double.tryParse(value) ?? 0;
        if (v < 90) return 'critical';
        if (v < 95) return 'warning';
        return 'normal';
      case 'temperature':
        final v = double.tryParse(value) ?? 0;
        if (v > 39.5 || v < 35) return 'critical';
        if (v > 38) return 'warning';
        return 'normal';
      default:
        return 'normal';
    }
  }
}

/// Mock vitals for UI demo when backend is not connected
class MockVitals {
  static List<HealthVital> forParent(int parentProfileId) => [
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'bp',
          value: '128/82',
          recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'sugar',
          value: '145',
          recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'heart_rate',
          value: '78',
          recordedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'oxygen',
          value: '97',
          recordedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'temperature',
          value: '37.1',
          recordedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        HealthVital(
          parentProfileId: parentProfileId,
          type: 'weight',
          value: '68',
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
}
