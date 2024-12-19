import 'package:args/args.dart';

/// A utility class for parsing command-line arguments for the Figma Flutter Generator.
/// 
/// This class provides functionality to create and configure the argument parser
/// for both icon generation and theme generation commands. It handles all command-line
/// options and their validation.
class CommandParser {
  /// Creates and configures an [ArgParser] with all supported commands and options.
  /// 
  /// Returns an [ArgParser] configured with:
  /// - Global options (token, file)
  /// - Icons command with its specific options
  /// - Variables command with its specific options
  /// 
  /// Example usage:
  /// ```dart
  /// final parser = CommandParser.createParser();
  /// final results = parser.parse(arguments);
  /// ```
  static ArgParser createParser() {
    final parser = ArgParser();

    // Global options
    parser.addOption(
      'token',
      abbr: 't',
      help: 'Figma access token',
      mandatory: true,
    );

    parser.addOption(
      'file',
      abbr: 'f',
      help: 'Figma file ID',
      mandatory: true,
    );

    // Commands
    parser.addCommand('icons')
      ..addOption(
        'node',
        abbr: 'n',
        help: 'Node ID containing icons',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for all generated files',
        mandatory: true,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
        defaultsTo: false,
      )
      ..addFlag(
        'direct-svg',
        help: 'Export directly as SVG instead of PDF',
        defaultsTo: false,
      )
      ..addFlag(
        'clean',
        help: 'Clean output directories before processing',
        defaultsTo: false,
      );

    parser.addCommand('variables')
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for theme files',
        mandatory: true,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
        defaultsTo: false,
      )
      ..addFlag(
        'clean',
        help: 'Clean output directory before processing',
        defaultsTo: false,
      );

    return parser;
  }

  /// Prints usage information for the command-line tool.
  /// 
  /// This method displays:
  /// - Basic usage syntax
  /// - Available commands
  /// - Example usage
  /// - Links to more detailed help
  static void printUsage() {
    print('Usage:');
    print('  figma_flutter_generator <command> [options]');
    print('\nCommands:');
    print('  icons      Generate icon font from Figma components');
    print('  variables  Generate theme files from Figma variables');
    print('\nExample:');
    print('  figma_flutter_generator icons \\');
    print('    --token YOUR_FIGMA_TOKEN \\');
    print('    --file YOUR_FILE_ID \\');
    print('    --node YOUR_NODE_ID \\');
    print('    --output ./output');
    print('\nFor more information:');
    print('  figma_flutter_generator icons --help');
    print('  figma_flutter_generator variables --help');
  }
}
