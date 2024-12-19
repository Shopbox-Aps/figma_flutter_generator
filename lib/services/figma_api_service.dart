import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/figma_variable.dart';
import '../models/figma_variable_collection.dart';

class FigmaApiService {
  final String _baseUrl = 'https://api.figma.com/v1';
  final String _figmaToken;
  final String _fileId;
  final http.Client _client;

  FigmaApiService(
    this._figmaToken,
    this._fileId, {
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> fetchNode(String nodeId) async {
    final formattedNodeId = nodeId.replaceAll('-', ':');
    final nodeUrl = '$_baseUrl/files/$_fileId/nodes?ids=$formattedNodeId';

    final response = await _makeRequest(nodeUrl);
    return response['nodes'][formattedNodeId]['document'];
  }

  Future<Map<String, String>> exportImages(List<String> vectorIds,
      {bool exportAsSvg = false}) async {
    final idsParam = vectorIds.join(',');
    final format = exportAsSvg ? 'svg' : 'pdf';
    final exportUrl =
        '$_baseUrl/images/$_fileId?ids=$idsParam&format=$format&scale=1';

    final response = await _makeRequest(exportUrl);
    return Map<String, String>.from(response['images']);
  }

  Future<Map<String, dynamic>> fetchVariables() async {
    final variablesUrl = '$_baseUrl/files/$_fileId/variables/local';
    return _makeRequest(variablesUrl);
  }

  Future<Map<String, FigmaVariable>> fetchTypedVariables() async {
    final response = await fetchVariables();
    final variables = response['meta']['variables'] as Map<String, dynamic>;
    return variables.map((key, value) =>
        MapEntry(key, FigmaVariable.fromJson(value as Map<String, dynamic>)));
  }

  Future<Map<String, FigmaVariableCollection>>
      fetchVariableCollections() async {
    final response = await fetchVariables();
    final collections =
        response['meta']['variableCollections'] as Map<String, dynamic>;
    return collections.map((key, value) => MapEntry(
        key, FigmaVariableCollection.fromJson(value as Map<String, dynamic>)));
  }

  Future<Map<String, dynamic>> _makeRequest(String url) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'X-Figma-Token': _figmaToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Figma API request failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to make Figma API request: $e');
    }
  }
}
