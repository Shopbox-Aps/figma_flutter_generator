# SVG Fetch to Icon Font

A powerful command-line tool that fetches SVG icons from Figma and converts them into an icon font, while also handling Figma variables for Flutter theme files.

## Features

🔄 Fetch SVG icons directly from Figma using the Figma API
🎨 Convert SVGs to an icon font with corresponding Flutter class
🎯 Generate Flutter theme files from Figma variables
📥 Support for both PDF and SVG icon downloads
📝 Verbose mode for detailed operation logging

## Icon Download Types

The tool supports two methods of downloading icons from Figma:

1. **Direct SVG Download** (Recommended)
   - Faster processing
   - Better quality
   - Use with `--direct-svg` flag
   - Requires Figma Professional plan

2. **PDF Download** (Default)
   - Works with all Figma plans
   - Converts PDF to SVG automatically
   - Slightly slower processing
   - Requires pdf2svg installed:
     ```bash
     # macOS
     brew install pdf2svg
     
     # Linux
     sudo apt-get install pdf2svg
     
     # Windows
     # Download from: http://www.cityinthesky.co.uk/opensource/pdf2svg/
     ```

## Installation

```bash
dart pub global activate svg_fetch_to_icon_font
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
svg_fetch_to_icon_font icons \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --node 456:789 \
  --output ./lib/icons

# Generate icon font using direct SVG download
svg_fetch_to_icon_font icons \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --node 456:789 \
  --output ./lib/icons \
  --direct-svg
```

### Theme Generation from Variables

```bash
# Generate theme files from Figma variables
svg_fetch_to_icon_font variables \
  --token YOUR_FIGMA_TOKEN \
  --file abc123xyz \
  --output ./lib/theme

# Generate with clean output
svg_fetch_to_icon_font variables \
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

```dart
import 'package:your_project/theme/theme.dart';

// In your MaterialApp
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  // ...
)
```

## Requirements

- Dart SDK >=2.19.0 <4.0.0
- Flutter (for theme generation)
- icon_font_generator (installed automatically)

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

- **Ramy Selim** - *Initial work and development*
- **Mohammed Ebrahim** - *Initial work and development*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Company

Developed and maintained by [Shopbox APS](https://shopbox.com).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
