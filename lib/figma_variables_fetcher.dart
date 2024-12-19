import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'constants/figma_constants.dart';

/// A service for fetching and processing Figma variables.
///
/// This service provides high-level functionality to:
/// - Fetch variables from Figma
/// - Process and categorize variables
/// - Generate theme files from variables
/// - Handle variable collections and modes
///
/// Requires a valid Figma access token and file ID.
class FigmaVariablesFetcher {
  /// The Figma access token used for authentication.
  final String _figmaToken;

  /// The ID of the Figma file to fetch variables from.
  final String _fileId;

  /// Metadata from the last variables fetch operation.
  late Map<String, dynamic> _meta;

  /// Creates a new [FigmaVariablesFetcher] instance.
  ///
  /// Parameters:
  /// - [_figmaToken]: A valid Figma access token
  /// - [_fileId]: The ID of the Figma file to access
  FigmaVariablesFetcher(this._figmaToken, this._fileId);

  /// Fetches all variables from the Figma file.
  ///
  /// Makes an API request to fetch variables and their metadata.
  /// Returns the raw variable data from the API.
  ///
  /// Throws an exception if:
  /// - The API request fails
  /// - The response is invalid
  /// - The authentication token is invalid
  Future<Map<String, dynamic>> fetchVariables() async {
    try {
      final variablesUrl =
          '${FigmaConstants.baseUrl}/files/$_fileId${FigmaConstants.variablesEndpoint}';
      final response = await http.get(
        Uri.parse(variablesUrl),
        headers: {
          FigmaConstants.authHeader: _figmaToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            '${FigmaConstants.fetchVariablesError}: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchVariables: $e');
      rethrow;
    }
  }

  /// Generates theme files from Figma variables.
  ///
  /// Parameters:
  /// - [outputDirectory]: The directory where theme files will be generated
  ///
  /// This method:
  /// 1. Fetches variables from Figma
  /// 2. Processes and categorizes variables
  /// 3. Generates theme files for each mode (e.g., light/dark)
  ///
  /// Throws an exception if:
  /// - Variables cannot be fetched
  /// - The mapped collection is not found
  /// - Files cannot be written to the output directory
  Future<void> generateThemeFiles(String outputDirectory) async {
    try {
      final data = await fetchVariables();

      if (!data.containsKey('meta')) {
        throw Exception(FigmaConstants.invalidResponseError);
      }

      _meta = data['meta'];
      final collections = _meta['variableCollections'] as Map<String, dynamic>;
      final variables = _meta['variables'] as Map<String, dynamic>;

      // Find the mapped collection
      final mappedCollection = collections.values.firstWhere(
        (collection) =>
            collection['name'] == FigmaConstants.mappedCollectionName,
        orElse: () =>
            throw Exception(FigmaConstants.mappedCollectionNotFoundError),
      );

      print(
          'Found mapped collection with ${mappedCollection['variableIds'].length} variables');

      // Process each mode in the mapped collection
      for (var mode in mappedCollection['modes']) {
        await _generateThemeFile(
            mode, mappedCollection, variables, outputDirectory);
      }
    } catch (e) {
      print('Error generating theme files: $e');
      rethrow;
    }
  }

  /// Generates a theme file for a specific mode.
  ///
  /// Parameters:
  /// - [mode]: The mode configuration (e.g., light/dark)
  /// - [collection]: The variable collection containing the mode
  /// - [variables]: All available variables
  /// - [outputDirectory]: Where to save the generated file
  ///
  /// Creates a Dart file containing theme constants for the specified mode.
  Future<void> _generateThemeFile(
    Map<String, dynamic> mode,
    Map<String, dynamic> collection,
    Map<String, dynamic> variables,
    String outputDirectory,
  ) async {
    final modeName = _formatModeName(mode['name'] as String);
    final modeId = mode['modeId'] as String;
    final fileName = '${modeName}_theme.dart';
    final filePath = path.join(outputDirectory, fileName);

    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';\n");
    buffer.writeln('class ${modeName.capitalize()}Theme {');

    // Group variables by category
    final groupedVariables = _groupVariablesByCategory(
      collection['variableIds'] as List,
      variables,
      modeId,
    );

    // Generate code for each category
    for (var category in groupedVariables.keys.toList()..sort()) {
      buffer.writeln('\n  // $category');
      for (var variable in groupedVariables[category]!) {
        final propertyName = _formatPropertyName(variable['name'] as String);
        final value = _resolveValue(variable, modeId, variables);
        if (value != null) {
          buffer.writeln(
              '  final ${_getPropertyType(variable)} $propertyName = $value;');
        }
      }
    }

    buffer.writeln('}\n');
    buffer.writeln('final ${modeName}Theme = ${modeName.capitalize()}Theme();');

    await File(filePath).writeAsString(buffer.toString());
    print('Generated theme file: $filePath');
  }

  /// Groups variables by their category based on their path structure.
  ///
  /// Parameters:
  /// - [variableIds]: List of variable IDs to group
  /// - [variables]: Map of all available variables
  /// - [modeId]: The current mode ID
  ///
  /// Returns a map where keys are categories and values are lists of variables.
  Map<String, List<Map<String, dynamic>>> _groupVariablesByCategory(
    List<dynamic> variableIds,
    Map<String, dynamic> variables,
    String modeId,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var id in variableIds) {
      final variable = variables[id];
      if (variable == null) continue;

      final name = variable['name'] as String;
      final parts = name.split('/');
      if (parts.length < 2) continue;

      final category = parts[0];
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(variable);
    }

    // Sort variables within each category
    for (var category in grouped.keys) {
      grouped[category]!
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }

    return grouped;
  }

  /// Formats a mode name to be Dart-compliant.
  ///
  /// Converts spaces to underscores and makes the name lowercase.
  String _formatModeName(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }

  /// Formats a property name to be Dart-compliant.
  ///
  /// Handles special characters, reserved words, and naming conventions.
  String _formatPropertyName(String name) {
    final parts = name.split('/');
    final propertyName = parts.last
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .replaceAll('--', '_')
        .replaceAll('sb_', '')
        .replaceAll('__', '_')
        .replaceAll(RegExp(r'^_+'), '')
        .toLowerCase();

    return FigmaConstants.dartReservedWords.contains(propertyName)
        ? '${propertyName}_value'
        : propertyName;
  }

  /// Determines the Dart type for a Figma variable.
  String _getPropertyType(Map<String, dynamic> variable) {
    switch (variable['resolvedType']) {
      case FigmaConstants.colorType:
        return 'Color';
      case FigmaConstants.floatType:
        return 'double';
      case FigmaConstants.stringType:
        return 'String';
      default:
        return 'dynamic';
    }
  }

  /// Resolves a variable's value for a specific mode.
  ///
  /// Parameters:
  /// - [variable]: The variable to resolve
  /// - [modeId]: The mode to get the value for
  /// - [variables]: All available variables for reference
  ///
  /// Returns the resolved value in a format suitable for Dart code generation.
  dynamic _resolveValue(
    Map<String, dynamic> variable,
    String modeId,
    Map<String, dynamic> variables,
  ) {
    final value = variable['valuesByMode'][modeId];
    if (value == null) return null;

    switch (variable['resolvedType']) {
      case FigmaConstants.colorType:
        if (value is Map<String, dynamic>) {
          return _colorToString(value);
        }
        break;
      case FigmaConstants.floatType:
        if (value is num) {
          return value.toDouble();
        }
        break;
      case FigmaConstants.stringType:
        return "'$value'";
    }

    return null;
  }

  /// Converts a Figma color value to a Dart Color constructor string.
  String _colorToString(Map<String, dynamic> color) {
    final r = (color['r'] * 255).round();
    final g = (color['g'] * 255).round();
    final b = (color['b'] * 255).round();
    final a = color['a'] ?? 1.0;

    return 'Color.fromRGBO($r, $g, $b, $a)';
  }
}

/// Extension to add string capitalization functionality.
extension StringExtension on String {
  /// Capitalizes the first character of the string.
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
