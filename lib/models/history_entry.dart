class HistoryEntry {
  final int? id;
  final String city;
  final String state;
  final DateTime timestamp;
  final List<String> keywords;
  final String? culturalSummary;

  HistoryEntry({
    this.id,
    required this.city,
    required this.state,
    required this.timestamp,
    required this.keywords,
    this.culturalSummary,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      city: json['city'],
      state: json['state'],
      timestamp: DateTime.parse(json['timestamp']),
      keywords: List<String>.from(json['keywords']),
      culturalSummary: json['culturalSummary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city,
      'state': state,
      'timestamp': timestamp.toIso8601String(),
      'keywords': keywords,
      'culturalSummary': culturalSummary,
    };
  }
}