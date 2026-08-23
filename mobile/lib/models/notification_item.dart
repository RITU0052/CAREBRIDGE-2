class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'medicine', 'health', 'appointment', 'emergency', 'ai'
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'info',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}

class MockNotifications {
  static List<NotificationItem> sample() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: '1',
        title: '⚠️ Medicine Missed',
        body: 'Mom missed her evening Metformin dose.',
        type: 'medicine',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationItem(
        id: '2',
        title: '📊 Blood Sugar Alert',
        body: 'Dad\'s sugar reading is 205 mg/dL — slightly high.',
        type: 'health',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: '📅 Appointment Tomorrow',
        body: 'Dr. Priya Sharma at Apollo Hospital — 10:00 AM',
        type: 'appointment',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: '🤖 AI Health Summary',
        body: 'Mom\'s weekly health score improved by 12%. Great progress!',
        type: 'ai',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: '💊 Medicine Taken ✓',
        body: 'Dad confirmed taking morning medicines.',
        type: 'medicine',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true,
      ),
    ];
  }
}
