import 'package:figma_flutter_generator/figma_flutter_generator.dart';
import 'package:figma_flutter_generator/figma_variables_fetcher.dart';

void main() async {
  // Example 1: Generate Icons
  await generateIcons();

  // Example 2: Generate Theme
  await generateTheme();
}

Future<void> generateIcons() async {
  // Configuration
  const figmaToken = 'YOUR_FIGMA_TOKEN';
  const fileId = 'YOUR_FILE_ID';
  const nodeId = 'YOUR_NODE_ID';
  const outputDir = './lib/icons';

  // Initialize the generator
  final generator = SvgFetchToIconFont(figmaToken, fileId, nodeId);

  // Generate icons
  try {
    await generator.fetchAllImages(outputDir);
    print('Icons generated successfully in $outputDir');
  } catch (e) {
    print('Error generating icons: $e');
  }
}

Future<void> generateTheme() async {
  // Configuration
  const figmaToken = 'YOUR_FIGMA_TOKEN';
  const fileId = 'YOUR_FILE_ID';
  const outputDir = './lib/theme';

  // Initialize the generator
  final generator = FigmaVariablesFetcher(figmaToken, fileId);

  // Generate theme files
  try {
    await generator.generateThemeFiles(outputDir);
    print('Theme files generated successfully in $outputDir');
  } catch (e) {
    print('Error generating theme files: $e');
  }
}
