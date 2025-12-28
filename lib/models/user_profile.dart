class UserProfile {
  final String? name;
  final String? gender;
  final DateTime? birthday;
  final String diabetesType;
  final int? diagnosisYear;

  UserProfile({
    this.name,
    this.gender,
    this.birthday,
    this.diabetesType = 'none',
    this.diagnosisYear,
  });

  UserProfile copyWith({
    String? name,
    String? gender,
    DateTime? birthday,
    String? diabetesType,
    int? diagnosisYear,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      diabetesType: diabetesType ?? this.diabetesType,
      diagnosisYear: diagnosisYear ?? this.diagnosisYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'diabetesType': diabetesType,
      'diagnosisYear': diagnosisYear,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      diabetesType: json['diabetesType'] as String? ?? 'none',
      diagnosisYear: json['diagnosisYear'] as int?,
    );
  }

  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }
}
