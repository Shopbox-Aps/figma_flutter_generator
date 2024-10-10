// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SvgFetchToIconFont {
  final String _baseUrl = 'https://api.figma.com/v1';
  final String _figmaToken;
  final String _fileId;
  final String _nodeId;
  SvgFetchToIconFont(this._figmaToken, this._fileId, this._nodeId);

  Future<void> fetchAllSvgs(String outputDirectory) async {
    // Step 1: Get node details to identify components/frames
    var nodeId = _nodeId.replaceAll('-', ':');
    final nodeUrl = '$_baseUrl/files/$_fileId/nodes?ids=$nodeId';
    final nodeResponse = await http.get(
      Uri.parse(nodeUrl),
      headers: {
        'X-Figma-Token': _figmaToken,
      },
    );

    if (nodeResponse.statusCode == 200) {
      final jsonResponse = json.decode(nodeResponse.body);
      final nodes = jsonResponse['nodes'][nodeId]['document']['children'];

      // Start processing nodes recursively, looking for VECTOR types only
      await _processNodes(nodes, outputDirectory, parentName: '');
    } else {
      print('Failed to fetch node data from Figma');
    }
  }

  // Recursive function to process nodes and find VECTOR types only, passing the parent name
  Future<void> _processNodes(List<dynamic> nodes, String outputDirectory,
      {required String parentName}) async {
    List<Map<String, String>> vectorDetails = [];

    for (var node in nodes) {
      // Handle only VECTOR types
      if (node['type'] == 'VECTOR') {
        vectorDetails.add({
          'id': node['id'],
          'name': parentName.isNotEmpty
              ? parentName
              : node['name'], // Use parent name if available
        });
      }

      // If the node has children, recursively process them, passing the current node's name as the parent
      if (node.containsKey('children')) {
        await _processNodes(node['children'], outputDirectory,
            parentName: node['name']);
      }
    }

    if (vectorDetails.isNotEmpty) {
      // Step 2: Export vector components as SVG using the images API
      await _fetchAndSaveSvgs(vectorDetails, outputDirectory);
    }
  }

  // Fetch and save SVGs based on vector details (which now include both ID and the name)
  Future<void> _fetchAndSaveSvgs(
      List<Map<String, String>> vectorDetails, String outputDirectory) async {
    List<String> vectorIds =
        vectorDetails.map((vector) => vector['id']!).toList();
    final idsParam = vectorIds.join(',');
    final exportUrl = '$_baseUrl/images/$_fileId?ids=$idsParam&format=svg';

    final exportResponse = await http.get(
      Uri.parse(exportUrl),
      headers: {
        'X-Figma-Token': _figmaToken,
      },
    );

    if (exportResponse.statusCode == 200) {
      final exportJson = json.decode(exportResponse.body);
      final svgUrls = exportJson['images'];

      // Download and save each SVG with the parent's name
      for (var vector in vectorDetails) {
        final svgUrl = svgUrls[vector['id']];
        if (svgUrl != null) {
          final svgResponse = await http.get(Uri.parse(svgUrl));
          if (svgResponse.statusCode == 200) {
            var fileName = vector['id'];
            if (vector['name'] != null) {
              if (vector['name']!.contains('=')) {
                fileName = vector['name']!.split('=')[1];
              } else {
                fileName = vector['name']!;
              }
            }
            final file = File('$outputDirectory/$fileName.svg');
            await file.writeAsString(svgResponse.body);
            print('SVG saved: $outputDirectory/$fileName.svg');
          } else {
            print('Failed to download SVG for VECTOR: ${vector['id']}');
          }
        } else {
          print('No SVG URL found for VECTOR: ${vector['id']}');
        }
      }
    } else {
      print('Failed to export SVGs: ${exportResponse.body}');
    }
  }
}
