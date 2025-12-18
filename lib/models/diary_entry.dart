class DiaryEntry {
  final String id;
  final DateTime date;
  final String? content;
  final String? aiGeneratedContent;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    this.content,
    this.aiGeneratedContent,
    this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? aiGeneratedContent,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      aiGeneratedContent: aiGeneratedContent ?? this.aiGeneratedContent,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'aiGeneratedContent': aiGeneratedContent,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String?,
      aiGeneratedContent: json['aiGeneratedContent'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
