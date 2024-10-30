import 'dart:io';
import 'package:svg_fetch_to_icon_font/svg_fetch_to_icon_font.dart';
import 'package:svg_fetch_to_icon_font/figma_variables_fetcher.dart';

Future<void> activateIconFontGenerator() async {
  print('Activating icon_font_generator...');

  final result = await Process.run(
    'dart',
    ['pub', 'global', 'activate', 'icon_font_generator'],
  );

  if (result.exitCode == 0) {
    print('icon_font_generator activated successfully');
  } else {
    print('Error activating icon_font_generator: ${result.stderr}');
  }
}

Future<void> runIconFontGenerator(String svgDirectory,
    String fontOutputDirectory, String fontClassOutputDirectory) async {
  // Ensure icon_font_generator is activated
  await activateIconFontGenerator();

  // Run the icon_font_generator command
  final result = await Process.run(
    'dart',
    [
      'pub',
      'global',
      'run',
      'icon_font_generator:generator',
      svgDirectory,
      fontOutputDirectory,
      '-o',
      fontClassOutputDirectory,
      '-f',
      'icon_font',
    ],
    runInShell:
        true, // Added to ensure the command runs properly in a shell environment
  );

  if (result.exitCode == 0) {
    print('Icon font generated successfully:');
    print(result.stdout);
  } else {
    print('Error running icon font generator: ${result.stderr}');
  }
}

Future<void> installPdf2Svg() async {
  print('Installing pdf2svg via brew...');

  // Run brew command to install pdf2svg
  final result = await Process.run(
    'brew',
    ['install', 'pdf2svg'],
    runInShell:
        true, // Added to ensure the command runs properly in a shell environment
  );

  if (result.exitCode == 0) {
    print('pdf2svg installed successfully');
  } else {
    print('Error installing pdf2svg: ${result.stderr}');
  }
}

Future<void> convertPdfToSvg(
    String pdfFilePath, String svgOutputDirectory) async {
  final pdfFileName =
      pdfFilePath.split(Platform.pathSeparator).last.split('.').first;
  final svgPrefix = '$svgOutputDirectory/$pdfFileName.svg';
  print('Converting PDF to SVG using pdf2svg...');

  // Run the pdf2svg command to convert each page of the PDF to an SVG file
  final result = await Process.run(
    'pdf2svg',
    [pdfFilePath, svgPrefix],
    runInShell:
        true, // Added to ensure the command runs properly in a shell environment
  );

  if (result.exitCode == 0) {
    print('PDF conversion successful: SVGs saved to $svgOutputDirectory');
  } else {
    print('Error converting PDF to SVG: ${result.stderr}');
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('''
Usage: 
  For icons: fetch_and_convert icons <figma_token> <figma_file_id> <node_id> <svg_output_directory> <font_output_directory> <font_class_output_directory>
  For variables: fetch_and_convert variables <figma_token> <figma_file_id> <output_directory>
    ''');
    return;
  }

  final command = args[0];

  if (command == 'icons') {
    await handleIconsCommand(args.sublist(1));
  } else if (command == 'variables') {
    await handleVariablesCommand(args.sublist(1));
  } else {
    print('Unknown command: $command');
  }
}

Future<void> handleIconsCommand(List<String> args) async {
  if (args.length < 6) {
    print(
        'Usage: fetch_and_convert icons <figma_token> <figma_file_id> <node_id> <svg_output_directory> <font_output_directory> <font_class_output_directory>');
    return;
  }

  final figmaToken = args[0];
  final figmaFileId = args[1];
  final nodeId = args[2];
  final svgOutputDirectory = args[3];
  final fontOutputDirectory = args[4];
  final fontClassOutputDirectory = args[5];

  final fetcher = SvgFetchToIconFont(figmaToken, figmaFileId, nodeId);

  // Step 1: Fetch SVGs from Figma and save them locally
  print('Fetching SVGs from Figma...');
  try {
    await fetcher.fetchAllImages(svgOutputDirectory);
    print('SVGs saved to $svgOutputDirectory');
  } catch (error) {
    print('Error fetching SVGs: $error');
    return;
  }

  // Step 2: Convert PDFs to SVGs if required
  final pdfDirectory = Directory(svgOutputDirectory);
  final pdfFiles =
      pdfDirectory.listSync().where((file) => file.path.endsWith('.pdf'));

  for (var pdfFile in pdfFiles) {
    final pdfFilePath = pdfFile.path;

    try {
      await convertPdfToSvg(pdfFilePath, svgOutputDirectory);
    } catch (error) {
      print('Error converting PDF to SVG: $error');
    }
  }

  // Step 3: Run the icon_font_generator command to convert SVGs into a font
  print('Generating icon font...');
  try {
    await runIconFontGenerator(
        svgOutputDirectory, fontOutputDirectory, fontClassOutputDirectory);
  } catch (error) {
    print('Error running icon font generator: $error');
  }
}

Future<void> handleVariablesCommand(List<String> args) async {
  if (args.length < 3) {
    print(
        'Usage: fetch_and_convert variables <figma_token> <figma_file_id> <output_directory>');
    return;
  }

  final figmaToken = args[0];
  final figmaFileId = args[1];
  final outputDirectory = args[2];

  // Ensure output directory exists
  await Directory(outputDirectory).create(recursive: true);

  final variablesFetcher = FigmaVariablesFetcher(figmaToken, figmaFileId);

  print('Fetching Figma variables...');
  try {
    await variablesFetcher.generateThemeFiles(outputDirectory);
    print('Theme files generated successfully in: $outputDirectory');
  } catch (error) {
    print('Error fetching variables: $error');
  }
}
