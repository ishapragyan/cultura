class CityInfo {
  final String cityName;
  final String state;
  final String? culturalInfo;
  final String? cuisine;
  final String? festivals;
  final String? language;
  final String? history;
  final DateTime lastUpdated;

  CityInfo({
    required this.cityName,
    required this.state,
    this.culturalInfo,
    this.cuisine,
    this.festivals,
    this.language,
    this.history,
    required this.lastUpdated,
  });

  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      cityName: json['cityName'],
      state: json['state'],
      culturalInfo: json['culturalInfo'],
      cuisine: json['cuisine'],
      festivals: json['festivals'],
      language: json['language'],
      history: json['history'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'state': state,
      'culturalInfo': culturalInfo,
      'cuisine': cuisine,
      'festivals': festivals,
      'language': language,
      'history': history,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}