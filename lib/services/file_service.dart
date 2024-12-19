import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// A service for handling file system operations.
/// 
/// This service provides utilities for:
/// - Downloading and saving files
/// - Managing directories
/// - Converting file formats
/// - Sanitizing file names
class FileService {
  /// Downloads a file from a URL and saves it to the specified path.
  /// 
  /// Parameters:
  /// - [url]: The URL to download the file from
  /// - [outputPath]: The directory to save the file in
  /// - [fileName]: The name to give the downloaded file
  /// - [extension]: The file extension to use
  /// 
  /// Throws an exception if the download fails or the file cannot be saved.
  Future<void> downloadAndSaveFile(
    String url,
    String outputPath,
    String fileName,
    String extension,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(path.join(outputPath, '$fileName.$extension'));
        await file.writeAsBytes(response.bodyBytes);
        print('File saved: ${file.path}');
      } else {
        throw Exception(
            'Failed to download file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  /// Ensures that a directory exists, creating it if necessary.
  /// 
  /// Parameters:
  /// - [directory]: The path of the directory to check/create
  /// 
  /// Creates parent directories as needed if they don't exist.
  Future<void> ensureDirectoryExists(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Sanitizes a file name by removing or replacing invalid characters.
  /// 
  /// Parameters:
  /// - [fileName]: The file name to sanitize
  /// 
  /// Returns a sanitized version of the file name that is safe to use
  /// in file systems. The sanitization:
  /// - Replaces invalid characters with underscores
  /// - Removes duplicate underscores
  /// - Removes leading underscores
  String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll('--', '_')
        .replaceAll('__', '_')
        .replaceAll(RegExp(r'^_+'), '');
  }

  /// Converts a PDF file to SVG format using the pdf2svg command-line tool.
  /// 
  /// Parameters:
  /// - [pdfPath]: The path to the source PDF file
  /// - [outputDirectory]: The directory to save the SVG file in
  /// 
  /// Requires the pdf2svg tool to be installed on the system.
  /// Throws an exception if the conversion fails or pdf2svg is not available.
  Future<void> convertPdfToSvg(String pdfPath, String outputDirectory) async {
    try {
      final pdfFileName = path.basenameWithoutExtension(pdfPath);
      final svgPath = path.join(outputDirectory, '$pdfFileName.svg');

      final result = await Process.run(
        'pdf2svg',
        [pdfPath, svgPath],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('PDF to SVG conversion failed: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Error converting PDF to SVG: $e');
    }
  }

  /// Cleans a directory by removing all its contents.
  /// 
  /// Parameters:
  /// - [directory]: The path of the directory to clean
  /// 
  /// Removes all files and subdirectories in the specified directory.
  /// Creates the directory if it doesn't exist.
  Future<void> cleanDirectory(String directory) async {
    final dir = Directory(directory);
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    }
  }
}
