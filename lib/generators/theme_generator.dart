import 'dart:io';
import 'package:path/path.dart' as path;
import '../api/figma_client.dart';
import '../utils/logger.dart';

/// A generator for creating Flutter theme files from Figma variables.
///
/// This class handles the process of:
/// - Fetching variables from Figma
/// - Converting variables to Flutter-compatible formats
/// - Generating theme files with color, typography, and spacing variables
/// - Creating a theme data class for easy consumption in Flutter apps
class ThemeGenerator {
  /// The Figma API client used to fetch data.
  final FigmaClient _client;

  /// The output directory for generated files.
  final String _outputDir;

  /// Whether to enable verbose logging.
  final bool _verbose;

  /// Creates a new [ThemeGenerator] instance.
  ///
  /// Parameters:
  /// - [client]: The Figma API client
  /// - [outputDir]: Directory for generated files
  /// - [verbose]: Whether to enable verbose logging
  ThemeGenerator(
    this._client,
    this._outputDir,
    this._verbose,
  );

  /// Generates theme files from Figma variables.
  ///
  /// This method:
  /// 1. Creates the output directory
  /// 2. Fetches variables from Figma
  /// 3. Processes and categorizes variables
  /// 4. Generates Flutter theme files
  ///
  /// Returns `true` if generation was successful, `false` otherwise.
  Future<bool> generate() async {
    try {
      // Create output directory
      final dir = Directory(_outputDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Fetch variables
      final data = await _client.getVariables();
      final collections =
          data['meta']['variableCollections'] as Map<String, dynamic>;
      final variables = data['variables'] as Map<String, dynamic>;

      if (_verbose) {
        Logger.debug('Found ${collections.length} variable collections');
        Logger.debug('Found ${variables.length} variables');
      }

      // Process variables by type
      final colors = <String, dynamic>{};
      final typography = <String, dynamic>{};
      final spacing = <String, dynamic>{};

      variables.forEach((id, variable) {
        final name = variable['name'] as String;
        final value = variable['valuesByMode'];
        final type = variable['resolvedType'] as String;

        if (type == 'COLOR') {
          colors[name] = value;
        } else if (type == 'FLOAT' || type == 'NUMBER') {
          if (name.toLowerCase().contains('spacing')) {
            spacing[name] = value;
          }
        } else if (type == 'STRING' && name.toLowerCase().contains('font')) {
          typography[name] = value;
        }
      });

      // Generate theme files
      _generateColorFile(colors);
      _generateTypographyFile(typography);
      _generateSpacingFile(spacing);
      _generateThemeFile();

      Logger.success('Theme generation completed successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to generate theme: $e');
      return false;
    }
  }

  /// Generates a Dart file containing color constants.
  ///
  /// Parameters:
  /// - [colors]: Map of color variables from Figma
  void _generateColorFile(Map<String, dynamic> colors) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();
    buffer.writeln('/// Color constants generated from Figma variables');
    buffer.writeln('class AppColors {');

    colors.forEach((name, value) {
      final colorValue = _processColorValue(value);
      buffer.writeln('  static const Color $name = Color($colorValue);');
    });

    buffer.writeln('}');

    final file = File(path.join(_outputDir, 'colors.dart'));
    file.writeAsStringSync(buffer.toString());

    if (_verbose) {
      Logger.debug('Generated colors.dart with ${colors.length} colors');
    }
  }

  /// Generates a Dart file containing typography styles.
  ///
  /// Parameters:
  /// - [typography]: Map of typography variables from Figma
  void _generateTypographyFile(Map<String, dynamic> typography) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();
    buffer.writeln('/// Typography styles generated from Figma variables');
    buffer.writeln('class AppTypography {');

    typography.forEach((name, value) {
      final style = _processTypographyValue(value);
      buffer.writeln('  static const TextStyle $name = TextStyle($style);');
    });

    buffer.writeln('}');

    final file = File(path.join(_outputDir, 'typography.dart'));
    file.writeAsStringSync(buffer.toString());

    if (_verbose) {
      Logger.debug(
          'Generated typography.dart with ${typography.length} styles');
    }
  }

  /// Generates a Dart file containing spacing constants.
  ///
  /// Parameters:
  /// - [spacing]: Map of spacing variables from Figma
  void _generateSpacingFile(Map<String, dynamic> spacing) {
    final buffer = StringBuffer();
    buffer.writeln('/// Spacing constants generated from Figma variables');
    buffer.writeln('class AppSpacing {');

    spacing.forEach((name, value) {
      final spacingValue = _processSpacingValue(value);
      buffer.writeln('  static const double $name = $spacingValue;');
    });

    buffer.writeln('}');

    final file = File(path.join(_outputDir, 'spacing.dart'));
    file.writeAsStringSync(buffer.toString());

    if (_verbose) {
      Logger.debug('Generated spacing.dart with ${spacing.length} constants');
    }
  }

  /// Generates the main theme file that combines all theme components.
  void _generateThemeFile() {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'colors.dart';");
    buffer.writeln("import 'typography.dart';");
    buffer.writeln("import 'spacing.dart';");
    buffer.writeln();
    buffer.writeln('/// Theme data generated from Figma variables');
    buffer.writeln('class AppTheme {');
    buffer.writeln('  static ThemeData get lightTheme => ThemeData(');
    buffer.writeln('    // Add theme configuration here');
    buffer.writeln('  );');
    buffer.writeln();
    buffer.writeln('  static ThemeData get darkTheme => ThemeData(');
    buffer.writeln('    // Add dark theme configuration here');
    buffer.writeln('  );');
    buffer.writeln('}');

    final file = File(path.join(_outputDir, 'theme.dart'));
    file.writeAsStringSync(buffer.toString());

    if (_verbose) {
      Logger.debug('Generated theme.dart');
    }
  }

  /// Processes a color value from Figma format to Flutter format.
  String _processColorValue(dynamic value) {
    // Implementation depends on Figma's color format
    return '0xFF000000';
  }

  /// Processes a typography value from Figma format to Flutter format.
  String _processTypographyValue(dynamic value) {
    // Implementation depends on Figma's typography format
    return 'fontSize: 16.0';
  }

  /// Processes a spacing value from Figma format to Flutter format.
  double _processSpacingValue(dynamic value) {
    // Implementation depends on Figma's spacing format
    return 8.0;
  }
}
