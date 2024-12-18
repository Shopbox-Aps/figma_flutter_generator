import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'constants/figma_constants.dart';

class FigmaVariablesFetcher {
  final String _figmaToken;
  final String _fileId;
  late Map<String, dynamic> _meta;

  FigmaVariablesFetcher(this._figmaToken, this._fileId);

  Future<Map<String, dynamic>> fetchVariables() async {
    try {
      final variablesUrl = '${FigmaConstants.baseUrl}/files/$_fileId${FigmaConstants.variablesEndpoint}';
      final response = await http.get(
        Uri.parse(variablesUrl),
        headers: {
          FigmaConstants.authHeader: _figmaToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('${FigmaConstants.fetchVariablesError}: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchVariables: $e');
      rethrow;
    }
  }

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
        (collection) => collection['name'] == FigmaConstants.mappedCollectionName,
        orElse: () => throw Exception(FigmaConstants.mappedCollectionNotFoundError),
      );

      print('Found mapped collection with ${mappedCollection['variableIds'].length} variables');

      // Process each mode in the mapped collection
      for (var mode in mappedCollection['modes']) {
        await _generateThemeFile(mode, mappedCollection, variables, outputDirectory);
      }
    } catch (e) {
      print('Error generating theme files: $e');
      rethrow;
    }
  }

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
          buffer.writeln('  final ${_getPropertyType(variable)} $propertyName = $value;');
        }
      }
    }

    buffer.writeln('}\n');
    buffer.writeln('final ${modeName}Theme = ${modeName.capitalize()}Theme();');

    await File(filePath).writeAsString(buffer.toString());
    print('Generated theme file: $filePath');
  }

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
      grouped[category]!.sort((a, b) => 
          (a['name'] as String).compareTo(b['name'] as String));
    }

    return grouped;
  }

  String _formatModeName(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }

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

  String _colorToString(Map<String, dynamic> color) {
    final r = (color['r'] * 255).round();
    final g = (color['g'] * 255).round();
    final b = (color['b'] * 255).round();
    final a = color['a'] ?? 1.0;

    return 'Color.fromRGBO($r, $g, $b, $a)';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
