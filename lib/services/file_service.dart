import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FileService {
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

  Future<void> ensureDirectoryExists(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll('--', '_')
        .replaceAll('__', '_')
        .replaceAll(RegExp(r'^_+'), '');
  }

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

  Future<void> cleanDirectory(String directory) async {
    final dir = Directory(directory);
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    }
  }
}
