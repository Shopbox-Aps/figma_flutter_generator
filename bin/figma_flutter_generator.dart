import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:figma_flutter_generator/cli/command_parser.dart';
import 'package:figma_flutter_generator/services/figma_api_service.dart';
import 'package:figma_flutter_generator/services/file_service.dart';
import 'package:figma_flutter_generator/services/theme_generator_service.dart';

bool _verbose = false;

void log(String message) {
  if (_verbose) {
    print(message);
  }
}

Future<void> main(List<String> args) async {
  final parser = CommandParser.createParser();

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } catch (e) {
    print('Error: ${e.toString()}');
    CommandParser.printUsage();
    exit(1);
  }

  if (args.isEmpty) {
    CommandParser.printUsage();
    exit(1);
  }

  final command = argResults.command;
  if (command == null) {
    print('Error: No command specified');
    CommandParser.printUsage();
    exit(1);
  }

  final token = argResults['token'] as String;
  final fileId = argResults['file'] as String;
  _verbose = command['verbose'] as bool;

  final figmaApi = FigmaApiService(token, fileId);
  final fileService = FileService();
  final themeGenerator = ThemeGeneratorService();

  try {
    switch (command.name) {
      case 'icons':
        await handleIconsCommand(command, figmaApi, fileService);
        break;
      case 'variables':
        await handleVariablesCommand(
            command, figmaApi, fileService, themeGenerator);
        break;
      default:
        print('Unknown command: ${command.name}');
        CommandParser.printUsage();
        exit(1);
    }
  } catch (e) {
    print('Error: ${e.toString()}');
    exit(1);
  }
}

Future<void> handleVariablesCommand(
    ArgResults command,
    FigmaApiService figmaApi,
    FileService fileService,
    ThemeGeneratorService themeGenerator) async {
  final outputDir = command['output'];
  final clean = command['clean'] as bool;

  log('Creating output directory...');
  await fileService.ensureDirectoryExists(outputDir);
  if (clean) {
    log('Cleaning output directory...');
    await fileService.cleanDirectory(outputDir);
  }

  log('Fetching variables from Figma...');
  final variables = await figmaApi.fetchTypedVariables();
  final collections = await figmaApi.fetchVariableCollections();

  log('Finding mapped collection...');
  final mappedCollection = collections.values.firstWhere(
    (collection) => collection.name == '1. ✨Mapped',
    orElse: () => throw Exception('Mapped collection not found'),
  );

  log('Generating theme files...');
  await themeGenerator.generateThemeFiles(
    mappedCollection,
    variables,
    outputDir,
  );
  print('Theme files generated successfully in $outputDir');
}

List<Map<String, dynamic>> _extractComponents(Map<String, dynamic> nodeData) {
  final components = <Map<String, dynamic>>[];

  void traverse(Map<String, dynamic> node) {
    // Check for INSTANCE type or icon-related components
    if (node['type'] == 'INSTANCE' ||
        (node['name']?.toString().toLowerCase().contains('icon') ?? false)) {
      // Extract component information
      final componentInfo = {
        'id': node['id'],
        'name': node['name'],
        'componentId': node['componentId'],
        'type': node['type'],
      };

      // Add size information if available
      if (node['absoluteBoundingBox'] != null) {
        componentInfo['size'] = {
          'width': node['absoluteBoundingBox']['width'],
          'height': node['absoluteBoundingBox']['height'],
        };
      }

      components.add(componentInfo);
    }

    // Handle different node structures
    if (node['document'] != null) {
      traverse(node['document']);
    }

    // Handle children array
    if (node['children'] != null && node['children'] is List) {
      for (var child in node['children']) {
        traverse(child);
      }
    }

    // Handle nodes object
    if (node['nodes'] != null && node['nodes'] is Map) {
      node['nodes'].values.forEach((nodeValue) {
        if (nodeValue is Map<String, dynamic>) {
          traverse(nodeValue);
        }
      });
    }
  }

  // Handle the specific structure where nodes is the top-level key
  if (nodeData['nodes'] != null) {
    nodeData['nodes'].values.forEach((node) {
      traverse(node);
    });
  } else {
    traverse(nodeData);
  }

  return components;
}

Future<void> handleIconsCommand(ArgResults command, FigmaApiService figmaApi,
    FileService fileService) async {
  final nodeId = command['node'];
  final baseOutputDir = command['output'];
  final directSvg = command['direct-svg'] as bool;
  final clean = command['clean'] as bool;

  // Create proper directory structure
  final svgOutput = path.join(baseOutputDir, 'svg');
  final fontOutput = path.join(baseOutputDir, 'font');
  final classOutput = path.join(baseOutputDir, 'lib');

  log('Creating output directories...');
  for (final dir in [svgOutput, fontOutput, classOutput]) {
    final directory = Directory(dir);
    if (clean && await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
  }

  if (clean) {
    log('Cleaning output directories...');
    await fileService.cleanDirectory(svgOutput);
    await fileService.cleanDirectory(fontOutput);
    await fileService.cleanDirectory(classOutput);
  }

  log('Fetching node data from Figma...');
  final nodeData = await figmaApi.fetchNode(nodeId);

  final components = _extractComponents(nodeData);
  if (components.isEmpty) {
    print('No icon components found in the specified node');
    return;
  }
  log('Found ${components.length} icon components');

  // Filter out non-icon components if needed
  final iconComponents = components
      .where((c) =>
          c['type'] == 'INSTANCE' ||
          (c['name']?.toString().toLowerCase().contains('icon') ?? false))
      .toList();

  log('Exporting images from Figma...');
  final vectorIds = iconComponents.map((c) => c['id'] as String).toList();
  final imageUrls =
      await figmaApi.exportImages(vectorIds, exportAsSvg: directSvg);

  log('Processing components...');
  for (var component in iconComponents) {
    final id = component['id'] as String;
    final name = component['name'] as String;
    final url = imageUrls[id];

    if (url != null) {
      final fileName = fileService.sanitizeFileName(name);
      final extension = directSvg ? 'svg' : 'pdf';

      log('Downloading ${fileName}.$extension...');
      await fileService.downloadAndSaveFile(
          url, svgOutput, fileName, extension);

      if (!directSvg) {
        log('Converting $fileName.pdf to SVG...');
        await fileService.convertPdfToSvg(
            '$svgOutput/$fileName.pdf', svgOutput);
      }
    }
  }
  // Add validation step before font generation
  log('Validating SVG files...');
  await validateSvgFiles(svgOutput);

  log('Generating icon font...');
  try {
    final fontFile = path.join(fontOutput, 'icon_font'); // Without extension
    final classFile =
        path.join(classOutput, 'icon_font.dart'); // With extension

    await _generateIconFont(
      svgOutput,
      fontFile,
      classFile,
    );
    print('Icon font generated successfully in $baseOutputDir');
  } catch (e) {
    print('Error generating icon font: $e');
    final svgFiles = Directory(svgOutput)
        .listSync()
        .where((file) => file.path.toLowerCase().endsWith('.svg'))
        .toList();
    print('Number of SVG files found: ${svgFiles.length}');
    print('SVG files:');
    for (var file in svgFiles) {
      print('  - ${file.path}');
    }
    rethrow;
  }

  print('Icon font generated successfully in $baseOutputDir');
}

Future<void> _generateIconFont(
    String svgDir, String fontFile, String classFile) async {
  // Verify SVG files exist
  final directory = Directory(svgDir);
  final svgFiles = directory
      .listSync()
      .where((file) => file.path.toLowerCase().endsWith('.svg'))
      .toList();

  if (svgFiles.isEmpty) {
    throw Exception('No SVG files found in directory: $svgDir');
  }

  log('Found ${svgFiles.length} SVG files to process');

  // Run the generator with correct parameters
  final result = await Process.run(
    'dart',
    [
      'pub',
      'global',
      'run',
      'icon_font_generator:generator',
      svgDir, // input-svg-dir
      '$fontFile.ttf', // output-font-file
      '--output-class-file=$classFile', // correct parameter name
      '--class-name=IconFont',
      '--font-name=IconFont',
      '--normalize',
      '--verbose',
    ],
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  if (result.exitCode != 0) {
    print('Icon font generator stdout: ${result.stdout}');
    print('Icon font generator stderr: ${result.stderr}');
    throw Exception(
        'Failed to generate icon font. Exit code: ${result.exitCode}');
  } else {
    log('Icon font generator output: ${result.stdout}');
  }
}

Future<void> validateSvgFiles(String svgDir) async {
  final directory = Directory(svgDir);
  final svgFiles = directory
      .listSync()
      .where((file) => file.path.toLowerCase().endsWith('.svg'))
      .toList();

  for (var file in svgFiles) {
    try {
      final content = await File(file.path).readAsString();

      // Basic SVG validation
      if (!content.contains('<svg') || !content.contains('</svg>')) {
        print('Warning: File ${file.path} might not be a valid SVG file');
        continue;
      }

      // Check for potential issues that might cause font generation to fail
      if (content.contains('data:image') || content.contains('base64,')) {
        print(
            'Warning: File ${file.path} contains embedded images which might cause issues');
      }

      if (!content.contains('viewBox')) {
        print('Warning: File ${file.path} missing viewBox attribute');
      }
    } catch (e) {
      print('Error validating SVG file ${file.path}: $e');
    }
  }
}

Future<void> ensureIconFontGeneratorInstalled() async {
  try {
    final result = await Process.run(
      'dart',
      ['pub', 'global', 'list'],
      runInShell: true,
    );

    if (!result.stdout.toString().contains('icon_font_generator')) {
      print('Installing icon_font_generator...');
      final installResult = await Process.run(
        'dart',
        ['pub', 'global', 'activate', 'icon_font_generator'],
        runInShell: true,
      );

      if (installResult.exitCode != 0) {
        throw Exception(
            'Failed to install icon_font_generator: ${installResult.stderr}');
      }
    }
  } catch (e) {
    print('Error ensuring icon_font_generator is installed: $e');
    rethrow;
  }
}
