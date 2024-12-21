import 'dart:io';
import 'package:path/path.dart' as path;
import '../api/figma_client.dart';
import '../utils/logger.dart';

/// A generator for creating icon fonts from Figma components.
///
/// This class handles the process of:
/// - Fetching icon components from Figma
/// - Downloading icon assets (SVG/PDF)
/// - Organizing files in the output directory
/// - Preparing files for icon font generation
class IconGenerator {
  /// The Figma API client used to fetch data.
  final FigmaClient _client;

  /// The ID of the node containing icons.
  final String _nodeId;

  /// The output directory for generated files.
  final String _outputDir;

  /// Whether to export icons directly as SVG.
  final bool _directSvg;

  /// Whether to enable verbose logging.
  final bool _verbose;

  /// Creates a new [IconGenerator] instance.
  ///
  /// Parameters:
  /// - [client]: The Figma API client
  /// - [nodeId]: ID of the node containing icons
  /// - [outputDir]: Directory for generated files
  /// - [directSvg]: Whether to export directly as SVG
  /// - [verbose]: Whether to enable verbose logging
  IconGenerator(
    this._client,
    this._nodeId,
    this._outputDir,
    this._directSvg,
    this._verbose,
  );

  /// Generates icon assets and prepares files for font generation.
  ///
  /// This method:
  /// 1. Creates necessary directories
  /// 2. Fetches icon components from Figma
  /// 3. Downloads icon assets
  /// 4. Organizes files for font generation
  ///
  /// Returns `true` if generation was successful, `false` otherwise.
  Future<bool> generate() async {
    try {
      // Create output directories
      final directories = [
        Directory(path.join(_outputDir, 'svg')),
        Directory(path.join(_outputDir, 'pdf')),
      ];

      for (final dir in directories) {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }

      // Fetch file data
      final fileData = await _client.getFile();
      final document = fileData['document'];

      // Find icon components
      final components = _findComponents(document);
      if (components.isEmpty) {
        Logger.error('No icon components found in node $_nodeId');
        return false;
      }

      Logger.info('Found ${components.length} icon components');
      if (_verbose) {
        for (final component in components) {
          Logger.debug('Icon: ${component['name']}');
        }
      }

      // Get image URLs
      final componentIds = components.map((c) => c['id'] as String).toList();
      final format = _directSvg ? 'svg' : 'pdf';
      final imageUrls =
          await _client.getImageUrls(componentIds, format: format);

      // Download images
      for (final component in components) {
        final id = component['id'] as String;
        final name = component['name'] as String;
        final url = imageUrls[id] as String;

        final extension = _directSvg ? 'svg' : 'pdf';
        final outputPath = path.join(
          _outputDir,
          extension,
          '$name.$extension',
        );

        final imageData = await _client.downloadImage(url);
        File(outputPath).writeAsBytesSync(imageData);

        if (_verbose) {
          Logger.debug('Downloaded: $outputPath');
        }
      }

      Logger.success('Icon generation completed successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to generate icons: $e');
      return false;
    }
  }

  /// Recursively finds icon components in the document.
  ///
  /// Parameters:
  /// - [node]: The current node to search in
  ///
  /// Returns a list of icon components found.
  List<Map<String, dynamic>> _findComponents(Map<String, dynamic> node) {
    final components = <Map<String, dynamic>>[];

    if (node['id'] == _nodeId) {
      if (node['type'] == 'COMPONENT_SET' || node['type'] == 'FRAME') {
        final children = node['children'] as List<dynamic>;
        for (final child in children) {
          if (child['type'] == 'COMPONENT') {
            components.add(child);
          }
        }
      } else if (node['type'] == 'COMPONENT') {
        components.add(node);
      }
    } else if (node.containsKey('children')) {
      final children = node['children'] as List<dynamic>;
      for (final child in children) {
        components.addAll(_findComponents(child));
      }
    }

    return components;
  }
}
