import 'dart:convert';
import 'package:http/http.dart' as http;

/// A client for interacting with the Figma API.
///
/// This class provides methods to fetch design tokens, components, and assets
/// from a Figma file. It handles authentication and API requests to the Figma REST API.
class FigmaClient {
  /// The base URL for the Figma API.
  static const String _baseUrl = 'https://api.figma.com/v1';

  /// The Figma access token used for authentication.
  final String _token;

  /// The Figma file ID to fetch data from.
  final String _fileId;

  /// Creates a new [FigmaClient] instance.
  ///
  /// Parameters:
  /// - [token]: A valid Figma access token
  /// - [fileId]: The ID of the Figma file to access
  FigmaClient(this._token, this._fileId);

  /// Fetches the entire Figma file data.
  ///
  /// Returns a JSON object containing all file data including:
  /// - Document structure
  /// - Components
  /// - Styles
  /// - Variables
  Future<Map<String, dynamic>> getFile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/files/$_fileId'),
      headers: {'X-FIGMA-TOKEN': _token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch Figma file: ${response.statusCode}');
    }
  }

  /// Fetches image URLs for specified node IDs.
  ///
  /// Parameters:
  /// - [ids]: List of node IDs to fetch images for
  /// - [format]: Image format (e.g., 'svg', 'pdf')
  /// - [scale]: Image scale factor
  ///
  /// Returns a map of node IDs to their corresponding image URLs.
  Future<Map<String, dynamic>> getImageUrls(
    List<String> ids, {
    String format = 'pdf',
    int scale = 1,
  }) async {
    final queryParams = {
      'ids': ids.join(','),
      'format': format,
      'scale': scale.toString(),
    };

    final uri = Uri.parse('$_baseUrl/images/$_fileId')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'X-FIGMA-TOKEN': _token},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['images'];
    } else {
      throw Exception('Failed to fetch image URLs: ${response.statusCode}');
    }
  }

  /// Downloads an image from a given URL.
  ///
  /// Parameters:
  /// - [url]: The URL of the image to download
  ///
  /// Returns the downloaded image data as bytes.
  Future<List<int>> downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download image: ${response.statusCode}');
    }
  }

  /// Fetches all variables from the Figma file.
  ///
  /// Returns a JSON object containing all variable collections and their variables.
  Future<Map<String, dynamic>> getVariables() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/files/$_fileId/variables/local'),
      headers: {'X-FIGMA-TOKEN': _token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch variables: ${response.statusCode}');
    }
  }
}
