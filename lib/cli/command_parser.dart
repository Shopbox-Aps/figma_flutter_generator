import 'package:args/args.dart';

class CommandParser {
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
