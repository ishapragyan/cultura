class Phrase {
  final String english;
  final String local;
  final String? localScript;
  final String language;
  final String pronunciation;

  Phrase({
    required this.english,
    required this.local,
    this.localScript,
    required this.language,
    required this.pronunciation,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      english: json['english'],
      local: json['local'],
      localScript: json['localScript'],
      language: json['language'],
      pronunciation: json['pronunciation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'local': local,
      'localScript': localScript,
      'language': language,
      'pronunciation': pronunciation,
    };
  }
}
