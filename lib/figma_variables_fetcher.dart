import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

const _dartReservedWords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'library',
  'mixin',
  'new',
  'null',
  'operator',
  'part',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

class FigmaVariablesFetcher {
  final String _baseUrl = 'https://api.figma.com/v1';
  final String _figmaToken;
  final String _fileId;
  late Map<String, dynamic> _meta; // Add this field

  FigmaVariablesFetcher(this._figmaToken, this._fileId);

  Future<Map<String, dynamic>> fetchVariables() async {
    try {
      final variablesUrl = '$_baseUrl/files/$_fileId/variables/local';
      final response = await http.get(
        Uri.parse(variablesUrl),
        headers: {
          'X-Figma-Token': _figmaToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to fetch variables from Figma: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchVariables: $e');
      rethrow;
    }
  }

  Future<void> generateThemeFiles(String outputDirectory) async {
    try {
      final data = await fetchVariables();

      if (data == null || !data.containsKey('meta')) {
        throw Exception('Invalid API response structure');
      }

      _meta = data['meta']; // Store meta data
      final collections = _meta['variableCollections'] as Map<String, dynamic>;
      final variables = _meta['variables'] as Map<String, dynamic>;

      // Find the "1. ✨Mapped" collection
      final mappedCollection = collections.values.firstWhere(
        (collection) => collection['name'] == '1. ✨Mapped',
        orElse: () => throw Exception('Mapped collection not found'),
      );

      print(
          'Found mapped collection with ${mappedCollection['variableIds'].length} variables');

      // Process each mode in the mapped collection
      for (var mode in mappedCollection['modes']) {
        final modeName =
            mode['name'].toString().toLowerCase().replaceAll(' ', '');
        final modeId = mode['modeId'];

        print('\nProcessing mode: ${mode['name']} (ID: $modeId)');

        // Create theme file content
        final themeContent = StringBuffer();
        themeContent.writeln('import \'package:flutter/material.dart\';\n');
        themeContent.writeln('class ${modeName.capitalize()}Theme {');

        // Process variables for this mode
        final mappedVariableIds = mappedCollection['variableIds'] as List;

        // Group variables by category (based on name prefix)
        final groupedVariables = <String, List<MapEntry<String, dynamic>>>{};

        for (var variableId in mappedVariableIds) {
          final variable = variables[variableId];
          if (variable == null) continue;

          final nameParts = variable['name'] as String;
          final parts = nameParts.split('/');
          if (parts.length < 2) continue;

          final category = parts[0];

          groupedVariables.putIfAbsent(category, () => []);
          groupedVariables[category]!.add(MapEntry(nameParts, variable));
        }

        print('\nFound categories: ${groupedVariables.keys.join(', ')}');

        // Sort categories for consistent output
        final sortedCategories = groupedVariables.keys.toList()..sort();

        // Generate code for each category
        for (var category in sortedCategories) {
          themeContent.writeln('\n  // $category');

          // Sort variables within category
          final sortedVariables = groupedVariables[category]!
            ..sort((a, b) => a.key.compareTo(b.key));

          print(
              '\nProcessing category: $category with ${sortedVariables.length} variables');

          for (var entry in sortedVariables) {
            final nameParts = entry.key.split('/');
            final name = nameParts.last
                .replaceAll('-', '_')
                .replaceAll(' ', '_')
                .replaceAll('--', '')
                .replaceAll('sb_', '')
                .replaceAll('*', '')
                .replaceAll('__', '_')
                .replaceAll(RegExp(r'^_+'),
                    '') // Add this line to remove leading underscores
                .toLowerCase();

            // Add suffix for reserved words
            final safeName =
                _dartReservedWords.contains(name) ? '${name}_value' : name;
            final variable = entry.value;

            try {
              final modeValue = variable['valuesByMode'][modeId];
              print('\nProcessing variable: ${entry.key}');
              print('Mode value: $modeValue');

              if (modeValue != null) {
                final resolvedValue =
                    await resolveValueRecursive(variables, modeValue, modeId);
                print('Resolved value: $resolvedValue');

                if (resolvedValue != null) {
                  switch (variable['resolvedType']) {
                    case 'COLOR':
                      if (resolvedValue is Map<String, dynamic>) {
                        final colorString = _colorToString(resolvedValue);
                        if (colorString != null) {
                          themeContent.writeln(
                              '  final Color $safeName = $colorString;');
                        }
                      }
                      break;
                    case 'FLOAT':
                      if (resolvedValue is num) {
                        themeContent.writeln(
                            '  final double $safeName = ${resolvedValue.toDouble()};');
                      }
                      break;
                    case 'STRING':
                      themeContent.writeln(
                          '  final String $safeName = \'$resolvedValue\';');
                      break;
                  }
                }
              }
            } catch (e) {
              print('Error processing variable ${entry.key}: $e');
            }
          }
        }

        // Close theme class
        themeContent.writeln('}\n');

        // Add theme instance
        themeContent.writeln(
            'final ${modeName}Theme = ${modeName.capitalize()}Theme();');

        // Write to file
        final fileName = '${modeName}_theme.dart';
        final filePath = '$outputDirectory/$fileName';
        await File(filePath).writeAsString(themeContent.toString());
        print('Generated theme file for ${mode['name']} at: $filePath');
      }
    } catch (e) {
      print('Error generating theme files: $e');
      rethrow;
    }
  }

  Future<dynamic> resolveValueRecursive(
      Map<String, dynamic> variables, dynamic value, String modeId) async {
    if (value == null) return null;

    print('Resolving value: $value');

    if (value is Map<String, dynamic> && value['type'] == 'VARIABLE_ALIAS') {
      final referencedId = value['id'];
      print('Found alias reference to: $referencedId');

      final referencedVariable = variables[referencedId];
      if (referencedVariable != null) {
        print('Referenced variable: ${referencedVariable['name']}');

        // Get all possible mode values
        final modeValues = referencedVariable['valuesByMode'];
        if (modeValues != null) {
          var modeValue = modeValues[modeId];

          if (modeValue == null) {
            // Try to find the default mode from the collection
            final collectionId = referencedVariable['variableCollectionId'];
            if (collectionId != null) {
              final collection =
                  _meta['variableCollections'][collectionId]; // Use _meta here
              if (collection != null) {
                final defaultModeId = collection['defaultModeId'];
                if (defaultModeId != null) {
                  modeValue = modeValues[defaultModeId];
                  print('Using default mode value from collection: $modeValue');
                }
              }
            }
          }

          print('Final mode value: $modeValue');

          if (modeValue != null) {
            // If it's another alias, resolve it recursively
            if (modeValue is Map<String, dynamic> &&
                modeValue['type'] == 'VARIABLE_ALIAS') {
              return resolveValueRecursive(variables, modeValue, modeId);
            }
            return modeValue;
          }
        }
      }
      return null;
    }

    // If it's not an alias, return the value directly
    return value;
  }

  String? _colorToString(Map<String, dynamic> color) {
    try {
      final r = (color['r'] * 255).round();
      final g = (color['g'] * 255).round();
      final b = (color['b'] * 255).round();
      final a = color['a'] ?? 1.0; // Keep alpha as float between 0 and 1

      return 'Color.fromRGBO($r, $g, $b, $a)';
    } catch (e) {
      print('Error converting color: $e');
      return null;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
