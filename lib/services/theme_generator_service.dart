import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/figma_variable.dart';
import '../models/figma_variable_collection.dart';

class ThemeGeneratorService {
  static const _dartReservedWords = {
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

  Future<void> generateThemeFiles(
    FigmaVariableCollection collection,
    Map<String, FigmaVariable> variables,
    String outputDir,
  ) async {
    for (var mode in collection.modes) {
      await _generateThemeFile(mode, collection, variables, outputDir);
    }
  }

  Future<void> _generateThemeFile(
    FigmaVariableMode mode,
    FigmaVariableCollection collection,
    Map<String, FigmaVariable> variables,
    String outputDir,
  ) async {
    final modeName = _formatModeName(mode.name);
    final fileName = '${modeName}_theme.dart';
    final filePath = path.join(outputDir, fileName);

    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';\n");
    buffer.writeln('class ${modeName.capitalize()}Theme {');

    // Group variables by category
    final groupedVariables = _groupVariablesByCategory(
        collection.variableIds, variables, mode.modeId);

    // Generate code for each category
    for (var category in groupedVariables.keys.toList()..sort()) {
      buffer.writeln('\n  // $category');
      for (var variable in groupedVariables[category]!) {
        final propertyName = _formatPropertyName(variable.name);
        final value = _resolveValue(variable, mode.modeId, variables);
        if (value != null) {
          buffer.writeln(
              '  final ${_getPropertyType(variable)} $propertyName = $value;');
        }
      }
    }

    // Close the class
    buffer.writeln('}\n');

    // Add theme instance
    buffer.writeln('final ${modeName}Theme = ${modeName.capitalize()}Theme();');

    // Write to file
    await File(filePath).writeAsString(buffer.toString());
  }

  Map<String, List<FigmaVariable>> _groupVariablesByCategory(
    List<String> variableIds,
    Map<String, FigmaVariable> variables,
    String modeId,
  ) {
    final grouped = <String, List<FigmaVariable>>{};

    for (var id in variableIds) {
      final variable = variables[id];
      if (variable == null) continue;

      final parts = variable.name.split('/');
      if (parts.length < 2) continue;

      final category = parts[0];
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(variable);
    }

    // Sort variables within each category
    for (var category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  String _formatModeName(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }

  String _formatPropertyName(String name) {
    final parts = name.split('/');
    final propertyName = parts.last
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll('--', '')
        .replaceAll('sb_', '')
        .replaceAll('*', '')
        .replaceAll('__', '_')
        .replaceAll(RegExp(r'^_+'), '')
        .toLowerCase();

    return _dartReservedWords.contains(propertyName)
        ? '${propertyName}_value'
        : propertyName;
  }

  String _getPropertyType(FigmaVariable variable) {
    switch (variable.resolvedType) {
      case 'COLOR':
        return 'Color';
      case 'FLOAT':
        return 'double';
      case 'STRING':
        return 'String';
      default:
        return 'dynamic';
    }
  }

  dynamic _resolveValue(
    FigmaVariable variable,
    String modeId,
    Map<String, FigmaVariable> variables,
  ) {
    final value = variable.valuesByMode[modeId];
    if (value == null) return null;

    switch (variable.resolvedType) {
      case 'COLOR':
        if (value is Map<String, dynamic>) {
          return _colorToString(value);
        }
        break;
      case 'FLOAT':
        if (value is num) {
          return value.toDouble();
        }
        break;
      case 'STRING':
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
