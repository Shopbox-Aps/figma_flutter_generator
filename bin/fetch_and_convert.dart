import 'dart:io';

import 'package:svg_fetch_to_icon_font/svg_fetch_to_icon_font.dart';

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
    String fontOutputDirectory, fontClassOutputDirectory) async {
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
  );

  if (result.exitCode == 0) {
    print('Icon font generated successfully:');
    print(result.stdout);
  } else {
    print('Error running icon font generator: ${result.stderr}');
  }
}

Future<void> main(List<String> args) async {
  if (args.length < 4) {
    print(
        'Usage: fetch_and_convert <figma_token> <figma_file_id> <svg_output_directory> <font_output_directory>');
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
    await fetcher.fetchAllSvgs(svgOutputDirectory);
    print('SVGs saved to $svgOutputDirectory');
  } catch (error) {
    print('Error fetching SVGs: $error');
    return;
  }

  // Step 2: Run the icon_font_generator command to convert SVGs into a font
  print('Generating icon font...');
  try {
    await runIconFontGenerator(
        svgOutputDirectory, fontOutputDirectory, fontClassOutputDirectory);
  } catch (error) {
    print('Error running icon font generator: $error');
  }
}
