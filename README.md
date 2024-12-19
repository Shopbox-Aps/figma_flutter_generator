<div align="center">
  <img src="https://raw.githubusercontent.com/Shopbox-Aps/figma_flutter_generator/refactor/assets/screenshots/cover.png" alt="Figma Flutter Generator Cover" width="100%"/>
</div>

# Figma Flutter Generator

A powerful command-line tool that fetches SVG icons from Figma and converts them into an icon font, while also handling Figma variables for Flutter theme files.

## Features

🔄 Fetch SVG icons directly from Figma using the Figma API
🎨 Convert SVGs to an icon font with corresponding Flutter class
🎯 Generate Flutter theme files from Figma variables
📥 Support for both PDF and SVG icon downloads
📝 Verbose mode for detailed operation logging

## Documentation

Comprehensive documentation is available at [docs.page](https://docs.page/Shopbox-Aps/figma_flutter_generator). Here's what you'll find:

- [Getting Started](https://docs.page/Shopbox-Aps/figma_flutter_generator/installation) - Installation and basic setup
- [Icon Generation](https://docs.page/Shopbox-Aps/figma_flutter_generator/icons) - How to generate icon fonts from Figma
- [Theme Generation](https://docs.page/Shopbox-Aps/figma_flutter_generator/variables) - How to generate theme files from Figma variables
- [Figma Setup Guide](https://docs.page/Shopbox-Aps/figma_flutter_generator/figma-setup) - How to set up your Figma file
- [Examples](https://docs.page/Shopbox-Aps/figma_flutter_generator/examples) - Code examples and use cases
- [Troubleshooting](https://docs.page/Shopbox-Aps/figma_flutter_generator/troubleshooting) - Common issues and solutions
## Command Examples

### Icons Command
Generate icon fonts from your Figma icons:

<div align="center">
  <img src="https://raw.githubusercontent.com/Shopbox-Aps/figma_flutter_generator/refactor/assets/screenshots/flutter_icons_example.png" alt="Flutter Icons Example" width="600"/>
</div>

*Example of generated icon font being used in a Flutter app*

### Variables Command
Generate theme files from your Figma variables:

<div align="center">
  <img src="https://raw.githubusercontent.com/Shopbox-Aps/figma_flutter_generator/refactor/assets/screenshots/flutter_variable_example_1.png" alt="Figma Variables Setup" width="600"/>
  <p><em>Setting up variables in Figma</em></p>
  
  <img src="https://raw.githubusercontent.com/Shopbox-Aps/figma_flutter_generator/refactor/assets/screenshots/flutter_variable_example_2.png" alt="Generated Theme Files" width="600"/>
  <p><em>Generated theme files structure</em></p>
  
  <img src="https://raw.githubusercontent.com/Shopbox-Aps/figma_flutter_generator/refactor/assets/screenshots/flutter_variable_example_3.png" alt="Theme Usage Example" width="600"/>
  <p><em>Using generated theme in Flutter app</em></p>
</div>

## Icon Download Types

The tool supports two methods of downloading icons from Figma:

1. **PDF Download** (Default & Recommended)
   - Higher quality output and better vector preservation
   - More reliable handling of complex SVG features
   - Handles special effects and gradients better
   - Resolves common SVG compatibility issues
   - Works with all Figma plans
   - Converts PDF to SVG automatically
   - Requires pdf2svg installed:
     ```bash
     # macOS
     brew install pdf2svg
     
     # Linux
     sudo apt-get install pdf2svg
     
     # Windows
     # Download from: http://www.cityinthesky.co.uk/opensource/pdf2svg/
     ```

2. **Direct SVG Download** (Alternative)
   - Faster processing
   - Simpler workflow
   - Use with `--direct-svg` flag
   - May have issues with complex icons or special effects
   - Best for simple, basic icons

> **Note:** We recommend using the default PDF download method as it provides superior quality and better handles complex SVG features, ensuring your icons look consistent across all platforms.

## Installation

```bash
dart pub global activate figma_flutter_generator
```

## Step-by-Step Guide

### 1. Getting Your Figma Access Token
1. Log in to your Figma account
2. Go to Settings > Account Settings
3. In the Personal access tokens section, click "Create new token"
4. Copy your access token for use in the commands

### 2. Finding Your Figma File and Node IDs
1. Open your Figma file containing the icons
2. The File ID is in the URL: `https://www.figma.com/file/XXXXXX/...` (XXXXXX is your File ID)
3. Right-click on the frame containing your icons
4. Select "Copy/Paste as" → "Copy link"
5. The Node ID is the last part of the copied link after "node-id="

### 3. Setting Up Your Project
1. Create a directory for your icon font project
2. Initialize a new Flutter/Dart project if needed
3. Create an output directory for generated files

## Usage Examples

### Icon Font Generation with Different Download Types

```bash
# Generate icon font using PDF download (default)
figma_flutter_generator icons \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --node 456:789 \
  --output ./lib/icons

# Generate icon font using direct SVG download
figma_flutter_generator icons \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --node 456:789 \
  --output ./lib/icons \
  --direct-svg
```

### Theme Generation from Variables

> **Note:** The variables command requires a Figma Enterprise plan to access the Variables API.

```bash
# Generate theme files from Figma variables
figma_flutter_generator variables \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --output ./lib/theme

# Generate with clean output
figma_flutter_generator variables \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --output ./lib/theme \
  --clean
```

## Output File Structure

After running the commands, you'll get the following file structure:

```
your_project/
├── lib/
│   ├── icons/
│   │   ├── icons.ttf              # Generated icon font file
│   │   ├── icons.dart             # Flutter icon class definitions
│   │   ├── pdf/                   # (If using default PDF download)
│   │   │   ├── icon1.pdf
│   │   │   └── icon2.pdf
│   │   └── svg/                   # (Final SVG files from either method)
│   │       ├── icon1.svg
│   │       ├── icon2.svg
│   │       └── ...
│   └── theme/                     # (If variables command is used)
│       ├── colors.dart            # Color definitions
│       ├── typography.dart        # Typography definitions
│       └── theme.dart             # Main theme file
```

### Generated Files Description

- `icons.ttf`: The generated icon font containing all your icons
- `icons.dart`: Flutter class with named constants for each icon
- `pdf/*.pdf`: Downloaded PDF files (when using default PDF download)
- `svg/*.svg`: Final SVG files (converted from PDF or directly downloaded)
- `colors.dart`: Color constants from Figma variables
- `typography.dart`: Text styles from Figma variables
- `theme.dart`: Combined theme configuration

## Using Generated Icons in Flutter

```dart
import 'package:your_project/icons/icons.dart';

// Use icons in your widgets
Icon(MyIcons.menu)
Icon(MyIcons.search, size: 24.0, color: Colors.blue)
```

## Using Generated Theme

The theme generator creates separate files for each theme mode (e.g., light, dark) with categorized variables. Here's how to use them:

```dart
// Import the generated theme files
import 'package:your_project/theme/light_theme.dart';
import 'package:your_project/theme/dark_theme.dart';

// Example of using theme variables in a widget
Container(
  color: lightTheme.primary_background,
  padding: EdgeInsets.all(lightTheme.spacing_medium),
  child: Text(
    'Hello World',
    style: TextStyle(
      color: lightTheme.text_primary,
      fontSize: lightTheme.font_size_body,
    ),
  ),
)

// Example of creating a ThemeData
ThemeData getLightTheme() {
  return ThemeData(
    primaryColor: lightTheme.primary_color,
    backgroundColor: lightTheme.background_color,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: lightTheme.text_primary,
        fontSize: lightTheme.font_size_body,
      ),
      titleLarge: TextStyle(
        color: lightTheme.text_primary,
        fontSize: lightTheme.font_size_title,
      ),
    ),
  );
}

// Using in MaterialApp
MaterialApp(
  theme: getLightTheme(),
  darkTheme: getDarkTheme(),
  // ...
)
```

### Generated Theme Structure

The theme generator creates separate files for each theme mode with the following structure:

```dart
// light_theme.dart
class LightTheme {
  // Colors
  final Color primary_color = Color.fromRGBO(0, 122, 255, 1.0);
  final Color background_color = Color.fromRGBO(255, 255, 255, 1.0);
  
  // Typography
  final double font_size_body = 16.0;
  final double font_size_title = 24.0;
  
  // Spacing
  final double spacing_small = 8.0;
  final double spacing_medium = 16.0;
  final double spacing_large = 24.0;
}

final lightTheme = LightTheme();
```

Variables are grouped by categories (defined by Figma variable path) and maintain their original naming convention with underscores.

## Requirements

- Dart SDK >=2.19.0 <4.0.0
- Flutter (for theme generation)
- icon_font_generator (installed automatically)
- Figma Professional plan (for direct SVG export)
- Figma Enterprise plan (for variables command)
- pdf2svg (for PDF to SVG conversion, if not using direct SVG export)

## Development

To contribute to this package:

1. Clone the repository
2. Install dependencies:
   ```bash
   dart pub get
   ```
3. Run tests:
   ```bash
   dart test
   ```

## Authors

- [Ramy Selim](https://www.linkedin.com/in/ramy-selim-417a6160/)  [<img src="https://raw.githubusercontent.com/rahuldkjain/github-profile-readme-generator/master/src/images/icons/Social/linked-in-alt.svg" height="16" width="16"/>](https://www.linkedin.com/in/ramy-selim-417a6160/)

- [Mohammed Ebrahim](https://www.linkedin.com/in/mohammed-ebrahim-675418191/)  [<img src="https://raw.githubusercontent.com/rahuldkjain/github-profile-readme-generator/master/src/images/icons/Social/linked-in-alt.svg" height="16" width="16"/>](https://www.linkedin.com/in/mohammed-ebrahim-675418191/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Company

Developed and maintained by [Shopbox APS](https://shopbox.com).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


