import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/figma_variable.dart';
import '../models/figma_variable_collection.dart';

/// A service for interacting with the Figma API.
///
/// This service provides methods to:
/// - Fetch nodes and components from Figma files
/// - Export images in different formats
/// - Fetch and manage variables and variable collections
///
/// All methods require a valid Figma access token and file ID.
class FigmaApiService {
  /// The base URL for the Figma API.
  final String _baseUrl = 'https://api.figma.com/v1';

  /// The Figma access token used for authentication.
  final String _figmaToken;

  /// The ID of the Figma file to interact with.
  final String _fileId;

  /// The HTTP client used for making API requests.
  final http.Client _client;

  /// Creates a new [FigmaApiService] instance.
  ///
  /// Parameters:
  /// - [_figmaToken]: A valid Figma access token
  /// - [_fileId]: The ID of the Figma file to access
  /// - [client]: Optional HTTP client for making requests
  FigmaApiService(
    this._figmaToken,
    this._fileId, {
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetches a specific node from the Figma file.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to fetch
  ///
  /// Returns the node's document data.
  /// Throws an exception if the node cannot be fetched.
  Future<Map<String, dynamic>> fetchNode(String nodeId) async {
    final formattedNodeId = nodeId.replaceAll('-', ':');
    final nodeUrl = '$_baseUrl/files/$_fileId/nodes?ids=$formattedNodeId';

    final response = await _makeRequest(nodeUrl);
    return response['nodes'][formattedNodeId]['document'];
  }

  /// Exports images for specified vector nodes.
  ///
  /// Parameters:
  /// - [vectorIds]: List of vector node IDs to export
  /// - [exportAsSvg]: Whether to export as SVG (true) or PDF (false)
  ///
  /// Returns a map of node IDs to their export URLs.
  /// Throws an exception if the export fails.
  Future<Map<String, String>> exportImages(List<String> vectorIds,
      {bool exportAsSvg = false}) async {
    final idsParam = vectorIds.join(',');
    final format = exportAsSvg ? 'svg' : 'pdf';
    final exportUrl =
        '$_baseUrl/images/$_fileId?ids=$idsParam&format=$format&scale=1';

    final response = await _makeRequest(exportUrl);
    return Map<String, String>.from(response['images']);
  }

  /// Fetches all variables from the Figma file.
  ///
  /// Returns the raw variable data from the API.
  /// Throws an exception if the variables cannot be fetched.
  Future<Map<String, dynamic>> fetchVariables() async {
    final variablesUrl = '$_baseUrl/files/$_fileId/variables/local';
    return _makeRequest(variablesUrl);
  }

  /// Fetches and parses variables into strongly-typed objects.
  ///
  /// Returns a map of variable IDs to [FigmaVariable] objects.
  /// Throws an exception if the variables cannot be fetched or parsed.
  Future<Map<String, FigmaVariable>> fetchTypedVariables() async {
    final response = await fetchVariables();
    final variables = response['meta']['variables'] as Map<String, dynamic>;
    return variables.map((key, value) =>
        MapEntry(key, FigmaVariable.fromJson(value as Map<String, dynamic>)));
  }

  /// Fetches and parses variable collections into strongly-typed objects.
  ///
  /// Returns a map of collection IDs to [FigmaVariableCollection] objects.
  /// Throws an exception if the collections cannot be fetched or parsed.
  Future<Map<String, FigmaVariableCollection>>
      fetchVariableCollections() async {
    final response = await fetchVariables();
    final collections =
        response['meta']['variableCollections'] as Map<String, dynamic>;
    return collections.map((key, value) => MapEntry(
        key, FigmaVariableCollection.fromJson(value as Map<String, dynamic>)));
  }

  /// Makes an authenticated request to the Figma API.
  ///
  /// Parameters:
  /// - [url]: The API endpoint URL
  ///
  /// Returns the parsed JSON response.
  /// Throws an exception if the request fails or returns an error.
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
