class ExpenseModel {
  final int? id;
  final int? parentProfileId;
  final double amount;
  final String category; // 'hospital', 'pharmacy', 'lab', 'insurance', 'ambulance', 'other'
  final String? description;
  final DateTime date;

  ExpenseModel({
    this.id,
    this.parentProfileId,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      parentProfileId: json['parent_profile_id'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'other',
      description: json['description'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'hospital':
        return 'Hospital';
      case 'pharmacy':
        return 'Pharmacy';
      case 'lab':
        return 'Lab Tests';
      case 'insurance':
        return 'Insurance';
      case 'ambulance':
        return 'Ambulance';
      default:
        return 'Other';
    }
  }
}

class MockExpenses {
  static List<ExpenseModel> sample() {
    final now = DateTime.now();
    return [
      ExpenseModel(amount: 2500, category: 'hospital', description: 'Dr. Sharma consultation', date: now.subtract(const Duration(days: 2))),
      ExpenseModel(amount: 850, category: 'pharmacy', description: 'Metformin, Amlodipine', date: now.subtract(const Duration(days: 5))),
      ExpenseModel(amount: 1200, category: 'lab', description: 'HbA1c + CBC', date: now.subtract(const Duration(days: 8))),
      ExpenseModel(amount: 3500, category: 'hospital', description: 'Emergency visit', date: now.subtract(const Duration(days: 12))),
      ExpenseModel(amount: 600, category: 'pharmacy', description: 'Vitamins & supplements', date: now.subtract(const Duration(days: 15))),
      ExpenseModel(amount: 5000, category: 'insurance', description: 'Monthly premium', date: now.subtract(const Duration(days: 20))),
    ];
  }

  static Map<String, double> categoryTotals(List<ExpenseModel> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
