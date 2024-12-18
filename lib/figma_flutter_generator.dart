import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SvgFetchToIconFont {
  final String _baseUrl = 'https://api.figma.com/v1';
  final String _figmaToken;
  final String _fileId;
  final String _nodeId;
  final bool _exportDirectlyAsSvg;

  SvgFetchToIconFont(
    this._figmaToken,
    this._fileId,
    this._nodeId, {
    bool exportDirectlyAsSvg = false,
  }) : _exportDirectlyAsSvg = exportDirectlyAsSvg;

  Future<void> fetchAllImages(String outputDirectory) async {
    try {
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
        await _processNodes(nodes, outputDirectory);
      } else {
        throw Exception(
            'Failed to fetch node data from Figma: ${nodeResponse.body}');
      }
    } catch (e) {
      print('Error in fetchAllImages: $e');
    }
  }

  Future<void> _processNodes(
      List<dynamic> nodes, String outputDirectory) async {
    List<Map<String, String>> vectorDetails = [];

    for (var node in nodes) {
      if (node['type'] == 'COMPONENT') {
        vectorDetails.add({
          'id': node['id'],
          'name': node['name'],
        });
      }

      if (node.containsKey('children')) {
        await _processNodes(node['children'], outputDirectory);
      }
    }

    if (vectorDetails.isNotEmpty) {
      await _fetchAndSaveImages(vectorDetails, outputDirectory);
    }
  }

  Future<void> _fetchAndSaveImages(
      List<Map<String, String>> vectorDetails, String outputDirectory) async {
    try {
      List<String> vectorIds =
          vectorDetails.map((vector) => vector['id']!).toList();
      final idsParam = vectorIds.join(',');

      final exportUrl = _exportDirectlyAsSvg
          ? '$_baseUrl/images/$_fileId?ids=$idsParam&format=svg&scale=1'
          : '$_baseUrl/images/$_fileId?ids=$idsParam&format=pdf';

      final exportResponse = await http.get(
        Uri.parse(exportUrl),
        headers: {
          'X-Figma-Token': _figmaToken,
        },
      );

      if (exportResponse.statusCode == 200) {
        final exportJson = json.decode(exportResponse.body);
        final imageUrls = exportJson['images'];

        for (var vector in vectorDetails) {
          final imageUrl = imageUrls[vector['id']];
          if (imageUrl != null) {
            if (_exportDirectlyAsSvg) {
              await _downloadAndSaveSvg(imageUrl, vector, outputDirectory);
            } else {
              await _downloadAndSavePng(imageUrl, vector, outputDirectory);
            }
          } else {
            print('No URL found for VECTOR: ${vector['id']}');
          }
        }
      } else {
        throw Exception('Failed to export images: ${exportResponse.body}');
      }
    } catch (e) {
      print('Error in _fetchAndSaveImages: $e');
    }
  }

  Future<void> _downloadAndSavePng(
      String pngUrl, Map<String, String> vector, String outputDirectory) async {
    try {
      final pngResponse = await http.get(Uri.parse(pngUrl));
      if (pngResponse.statusCode == 200) {
        var fileName = _generateFileName(vector);
        final file = File('$outputDirectory/$fileName.pdf');
        await file.writeAsBytes(pngResponse.bodyBytes);
        print('PNG saved: $outputDirectory/$fileName.pdf');
      } else {
        throw Exception(
            'Failed to download PNG for VECTOR: ${vector['id']}. Status code: ${pngResponse.statusCode}');
      }
    } catch (e) {
      print('Error downloading PNG for VECTOR ${vector['id']}: $e');
    }
  }

  Future<void> _downloadAndSaveSvg(
      String svgUrl, Map<String, String> vector, String outputDirectory) async {
    try {
      final svgResponse = await http.get(Uri.parse(svgUrl));
      if (svgResponse.statusCode == 200) {
        var fileName = _generateFileName(vector);
        final file = File('$outputDirectory/$fileName.svg');
        await file.writeAsBytes(svgResponse.bodyBytes);
        print('SVG saved: $outputDirectory/$fileName.svg');
      } else {
        throw Exception(
            'Failed to download SVG for VECTOR: ${vector['id']}. Status code: ${svgResponse.statusCode}');
      }
    } catch (e) {
      print('Error downloading SVG for VECTOR ${vector['id']}: $e');
    }
  }

  String _generateFileName(Map<String, String> vector) {
    var fileName = vector['id'];
    if (vector['name'] != null) {
      if (vector['name']!.contains('=')) {
        fileName = vector['name']!.split('=')[1];
      } else {
        fileName = vector['name']!;
      }
    }
    // Remove any invalid characters from the filename
    fileName = fileName!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return fileName;
  }
}
