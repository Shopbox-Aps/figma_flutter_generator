import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:figma_flutter_generator/services/theme_generator_service.dart';
import 'package:figma_flutter_generator/models/figma_variable.dart';
import 'package:figma_flutter_generator/models/figma_variable_collection.dart';

void main() {
  late ThemeGeneratorService generator;
  late Directory tempDir;

  setUp(() async {
    generator = ThemeGeneratorService();
    tempDir = await Directory.systemTemp.createTemp('theme_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ThemeGeneratorService', () {
    test('generates theme files correctly', () async {
      final collection = FigmaVariableCollection(
        id: 'collection1',
        name: 'Test Collection',
        modes: [
          FigmaVariableMode(modeId: 'mode1', name: 'Light'),
          FigmaVariableMode(modeId: 'mode2', name: 'Dark'),
        ],
        variableIds: ['var1', 'var2', 'var3'],
        defaultModeId: 'mode1',
      );

      final variables = {
        'var1': FigmaVariable(
          id: 'var1',
          name: 'colors/primary',
          resolvedType: 'COLOR',
          valuesByMode: {
            'mode1': {'r': 1, 'g': 0, 'b': 0, 'a': 1},
            'mode2': {'r': 0, 'g': 0, 'b': 1, 'a': 1},
          },
          variableCollectionId: 'collection1',
        ),
        'var2': FigmaVariable(
          id: 'var2',
          name: 'typography/body_size',
          resolvedType: 'FLOAT',
          valuesByMode: {
            'mode1': 16.0,
            'mode2': 18.0,
          },
          variableCollectionId: 'collection1',
        ),
        'var3': FigmaVariable(
          id: 'var3',
          name: 'typography/font_family',
          resolvedType: 'STRING',
          valuesByMode: {
            'mode1': 'Roboto',
            'mode2': 'Roboto',
          },
          variableCollectionId: 'collection1',
        ),
      };

      await generator.generateThemeFiles(collection, variables, tempDir.path);

      // Check if files were created
      final lightThemeFile = File(path.join(tempDir.path, 'light_theme.dart'));
      final darkThemeFile = File(path.join(tempDir.path, 'dark_theme.dart'));

      expect(await lightThemeFile.exists(), true);
      expect(await darkThemeFile.exists(), true);

      // Check light theme content
      final lightContent = await lightThemeFile.readAsString();
      expect(lightContent.contains('class LightTheme'), true);
      expect(
          lightContent.contains('Color primary = Color.fromRGBO(255, 0, 0, 1)'),
          true);
      expect(lightContent.contains('double body_size = 16.0'), true);
      expect(lightContent.contains("String font_family = 'Roboto'"), true);

      // Check dark theme content
      final darkContent = await darkThemeFile.readAsString();
      expect(darkContent.contains('class DarkTheme'), true);
      expect(
          darkContent.contains('Color primary = Color.fromRGBO(0, 0, 255, 1)'),
          true);
      expect(darkContent.contains('double body_size = 18.0'), true);
      expect(darkContent.contains("String font_family = 'Roboto'"), true);
    });

    test('handles invalid variables gracefully', () async {
      final collection = FigmaVariableCollection(
        id: 'collection1',
        name: 'Test Collection',
        modes: [FigmaVariableMode(modeId: 'mode1', name: 'Light')],
        variableIds: ['var1'],
        defaultModeId: 'mode1',
      );

      final variables = {
        'var1': FigmaVariable(
          id: 'var1',
          name: 'invalid/variable',
          resolvedType: 'UNKNOWN',
          valuesByMode: {'mode1': 'invalid'},
          variableCollectionId: 'collection1',
        ),
      };

      await generator.generateThemeFiles(collection, variables, tempDir.path);
      final themeFile = File(path.join(tempDir.path, 'light_theme.dart'));

      expect(await themeFile.exists(), true);
      final content = await themeFile.readAsString();
      expect(content.contains('dynamic variable = '), false);
    });
  });
}
