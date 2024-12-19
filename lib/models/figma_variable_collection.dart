/// Represents a collection of related Figma variables.
///
/// A variable collection groups related variables together and defines
/// the modes (e.g., light/dark) in which these variables can have different values.
/// This is typically used to organize design tokens in a design system.
class FigmaVariableCollection {
  /// The unique identifier of the collection.
  final String id;

  /// The human-readable name of the collection.
  final String name;

  /// The list of modes (e.g., light/dark) supported by this collection.
  ///
  /// Each mode represents a different state or theme where variables
  /// can have different values.
  final List<FigmaVariableMode> modes;

  /// The list of variable IDs that belong to this collection.
  final List<String> variableIds;

  /// The ID of the default mode for this collection.
  ///
  /// This mode is used when no specific mode is specified.
  final String defaultModeId;

  /// Creates a new [FigmaVariableCollection] instance.
  ///
  /// All parameters are required and correspond to Figma's collection properties.
  FigmaVariableCollection({
    required this.id,
    required this.name,
    required this.modes,
    required this.variableIds,
    required this.defaultModeId,
  });

  /// Creates a [FigmaVariableCollection] from a JSON map.
  ///
  /// The JSON structure should match Figma's API response format for variable collections.
  /// Throws if required fields are missing or of incorrect type.
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

  /// Converts the collection to a JSON map.
  ///
  /// The resulting map matches Figma's API format and can be used
  /// for serialization or API requests.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'modes': modes.map((mode) => mode.toJson()).toList(),
        'variableIds': variableIds,
        'defaultModeId': defaultModeId,
      };
}

/// Represents a mode within a variable collection.
///
/// A mode defines a specific state or theme (e.g., light mode, dark mode)
/// where variables can have different values. This allows for maintaining
/// multiple sets of values for the same variables.
class FigmaVariableMode {
  /// The unique identifier of the mode.
  final String modeId;

  /// The human-readable name of the mode (e.g., "Light", "Dark").
  final String name;

  /// Creates a new [FigmaVariableMode] instance.
  ///
  /// Both [modeId] and [name] are required parameters.
  FigmaVariableMode({
    required this.modeId,
    required this.name,
  });

  /// Creates a [FigmaVariableMode] from a JSON map.
  ///
  /// The JSON structure should match Figma's API response format for modes.
  /// Throws if required fields are missing or of incorrect type.
  factory FigmaVariableMode.fromJson(Map<String, dynamic> json) {
    return FigmaVariableMode(
      modeId: json['modeId'] as String,
      name: json['name'] as String,
    );
  }

  /// Converts the mode to a JSON map.
  ///
  /// The resulting map matches Figma's API format and can be used
  /// for serialization or API requests.
  Map<String, dynamic> toJson() => {
        'modeId': modeId,
        'name': name,
      };
}
