class FigmaVariableCollection {
  final String id;
  final String name;
  final List<FigmaVariableMode> modes;
  final List<String> variableIds;
  final String defaultModeId;

  FigmaVariableCollection({
    required this.id,
    required this.name,
    required this.modes,
    required this.variableIds,
    required this.defaultModeId,
  });

  factory FigmaVariableCollection.fromJson(Map<String, dynamic> json) {
    return FigmaVariableCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      modes: (json['modes'] as List)
          .map((mode) => FigmaVariableMode.fromJson(mode))
          .toList(),
      variableIds: (json['variableIds'] as List).cast<String>(),
      defaultModeId: json['defaultModeId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'modes': modes.map((mode) => mode.toJson()).toList(),
        'variableIds': variableIds,
        'defaultModeId': defaultModeId,
      };
}

class FigmaVariableMode {
  final String modeId;
  final String name;

  FigmaVariableMode({
    required this.modeId,
    required this.name,
  });

  factory FigmaVariableMode.fromJson(Map<String, dynamic> json) {
    return FigmaVariableMode(
      modeId: json['modeId'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'modeId': modeId,
        'name': name,
      };
}
