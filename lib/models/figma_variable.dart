class FigmaVariable {
  final String id;
  final String name;
  final String resolvedType;
  final Map<String, dynamic> valuesByMode;
  final String variableCollectionId;

  FigmaVariable({
    required this.id,
    required this.name,
    required this.resolvedType,
    required this.valuesByMode,
    required this.variableCollectionId,
  });

  factory FigmaVariable.fromJson(Map<String, dynamic> json) {
    return FigmaVariable(
      id: json['id'] as String,
      name: json['name'] as String,
      resolvedType: json['resolvedType'] as String,
      valuesByMode: json['valuesByMode'] as Map<String, dynamic>,
      variableCollectionId: json['variableCollectionId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'resolvedType': resolvedType,
        'valuesByMode': valuesByMode,
        'variableCollectionId': variableCollectionId,
      };
} 