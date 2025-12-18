class MealRecord {
  final String id;
  final DateTime timestamp;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? description;
  final List<String>? photoUrls;
  final String? note;
  final int? estimatedCarbs;

  MealRecord({
    required this.id,
    required this.timestamp,
    required this.mealType,
    this.description,
    this.photoUrls,
    this.note,
    this.estimatedCarbs,
  });

  MealRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? mealType,
    String? description,
    List<String>? photoUrls,
    String? note,
    int? estimatedCarbs,
  }) {
    return MealRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      note: note ?? this.note,
      estimatedCarbs: estimatedCarbs ?? this.estimatedCarbs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mealType': mealType,
      'description': description,
      'photoUrls': photoUrls,
      'note': note,
      'estimatedCarbs': estimatedCarbs,
    };
  }

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    return MealRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealType: json['mealType'] as String,
      description: json['description'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>(),
      note: json['note'] as String?,
      estimatedCarbs: json['estimatedCarbs'] as int?,
    );
  }
}
