/// Diabetes type options for onboarding
enum DiabetesType {
  prediabetes('prediabetes', 'Pre-Diabetes'),
  type1('type1', 'Type 1'),
  type2('type2', 'Type 2'),
  lada('lada', 'LADA (1.5)'),
  mody('mody', 'MODY'),
  unknown('unknown', 'Unknown');

  final String value;
  final String displayName;

  const DiabetesType(this.value, this.displayName);

  static DiabetesType fromValue(String value) {
    return DiabetesType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DiabetesType.unknown,
    );
  }
}
