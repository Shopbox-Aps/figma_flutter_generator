/// Represents a Figma variable with its properties and values.
/// 
/// This class encapsulates a variable from Figma's design system, including
/// its identifier, name, type, and values for different modes (e.g., light/dark).
class FigmaVariable {
  /// The unique identifier of the variable in Figma.
  final String id;

  /// The human-readable name of the variable.
  /// 
  /// Usually follows a path-like structure, e.g., "colors/primary/background".
  final String name;

  /// The resolved type of the variable.
  /// 
  /// Common types include:
  /// - COLOR: Color values
  /// - FLOAT: Numeric values (e.g., spacing, opacity)
  /// - STRING: Text values (e.g., font names)
  final String resolvedType;

  /// A map of values for different modes (e.g., light/dark theme).
  /// 
  /// The key is the mode ID, and the value depends on the [resolvedType]:
  /// - For COLOR: Map with r, g, b, a values
  /// - For FLOAT: Numeric value
  /// - For STRING: String value
  final Map<String, dynamic> valuesByMode;

  /// The ID of the variable collection this variable belongs to.
  final String variableCollectionId;

  /// Creates a new [FigmaVariable] instance.
  /// 
  /// All parameters are required and correspond to Figma's variable properties.
  FigmaVariable({
    required this.id,
    required this.name,
    required this.resolvedType,
    required this.valuesByMode,
    required this.variableCollectionId,
  });

  /// Creates a [FigmaVariable] from a JSON map.
  /// 
  /// The JSON structure should match Figma's API response format for variables.
  /// Throws if required fields are missing or of incorrect type.
  factory FigmaVariable.fromJson(Map<String, dynamic> json) {
    return FigmaVariable(
      id: json['id'] as String,
      name: json['name'] as String,
      resolvedType: json['resolvedType'] as String,
      valuesByMode: json['valuesByMode'] as Map<String, dynamic>,
      variableCollectionId: json['variableCollectionId'] as String,
    );
  }

  /// Converts the variable to a JSON map.
  /// 
  /// The resulting map matches Figma's API format and can be used
  /// for serialization or API requests.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'resolvedType': resolvedType,
        'valuesByMode': valuesByMode,
        'variableCollectionId': variableCollectionId,
      };
}
