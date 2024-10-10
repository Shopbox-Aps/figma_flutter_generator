
# SVG Fetch to Icon Font

**SVG Fetch to Icon Font** is a Flutter plugin that fetches SVG icons from a Figma file and converts them into an icon font using the [`icon_font_generator`](https://pub.dev/packages/icon_font_generator) tool. It automates the process of downloading SVG files from a Figma page and generating a font file along with a Dart file to use in your Flutter app.

## Features

- Fetches all SVGs from a specified Figma page or file.
- Saves the SVGs to a local directory.
- Converts the SVG files into a font and Dart icon file using the `icon_font_generator` tool.
- Automates the icon font creation process, reducing manual work.

## Installation

1. Add the plugin as a dev dependency in your Flutter project's `pubspec.yaml`:

    ```yaml
    dev_dependencies:
      svg_fetch_to_icon_font:
        path: ../path_to_your_plugin  # Add your local path here
      icon_font_generator: ^3.0.0
    ```

2. Install the required dependencies:

    ```bash
    flutter pub get
    ```

3. Globally activate the `icon_font_generator` tool:

    ```bash
    dart pub global activate icon_font_generator
    ```

## How to Get Figma API Token and Page ID

### 1. Figma API Token

To fetch SVGs from a Figma page, you'll need a Figma API token. Here's how you can generate it:

1. Go to your Figma account's [API settings page](https://www.figma.com/developers/api#access-tokens).
2. Click **Create a new personal access token**.
3. Copy the generated token. You'll use this token when running the command to fetch SVGs.

### 2. Figma File ID and Node ID (Page ID)

You need the Figma file ID and the page (node) ID to fetch the SVGs from a specific page:

#### Get the Figma File ID:
1. Open the Figma file you want to fetch icons from.
2. Look at the URL in the address bar. It should look something like this:

    ```
    https://www.figma.com/file/abc12345/example-file?node-id=0%3A1
    ```

    The file ID is the string after `/file/` and before `?node-id=`.
    
    In this case:
    - **File ID**: `abc12345`

#### Get the Node ID (Page ID):
1. The **Node ID** is the part after `node-id=` in the URL, such as `0%3A1`. This represents the page ID you want to fetch the icons from.
   
    In this case:
    - **Node ID (Page ID)**: `0:1`

## Usage

After you have your Figma API token and the file and page IDs, you can run the command to fetch SVGs and generate the icon font.

### Command

```bash
dart run svg_fetch_to_icon_font:fetch_and_convert <FIGMA_API_TOKEN> <FIGMA_FILE_ID> <SVG_OUTPUT_DIRECTORY> <FONT_OUTPUT_DIRECTORY>
```

### Example:

```bash
dart run svg_fetch_to_icon_font:fetch_and_convert "your-figma-api-token" "abc12345" ./assets/svg ./assets/fonts
```

### Parameters:

- `<FIGMA_API_TOKEN>`: Your Figma API token.
- `<FIGMA_FILE_ID>`: The Figma file ID (extracted from the URL).
- `<SVG_OUTPUT_DIRECTORY>`: The directory where the fetched SVG files will be saved (e.g., `./assets/svg`).
- `<FONT_OUTPUT_DIRECTORY>`: The directory where the generated font and Dart icon files will be saved (e.g., `./assets/fonts`).

### Result:
- **SVG Files**: The SVG files from Figma will be saved in the specified `SVG_OUTPUT_DIRECTORY`.
- **Font File**: The generated font file (`custom_icons.ttf`) will be saved in the `FONT_OUTPUT_DIRECTORY`.
- **Dart Icon File**: A Dart file (`custom_icons.dart`) will be generated in the `FONT_OUTPUT_DIRECTORY`, which you can import into your Flutter app to use the icons.

## Using the Generated Icons in Flutter

After generating the font and Dart icon file, you can use them in your Flutter project.

1. Add the generated font to your `pubspec.yaml`:

    ```yaml
    flutter:
      fonts:
        - family: CustomIcons
          fonts:
            - asset: assets/fonts/custom_icons.ttf
    ```

2. Import the generated Dart icon file in your Flutter widgets:

    ```dart
    import 'assets/fonts/custom_icons.dart';

    class MyIconWidget extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return Icon(CustomIcons.my_custom_icon);
      }
    }
    ```

Now you can use the custom icons generated from Figma as part of your Flutter app!

## Notes

- Ensure that the `icon_font_generator` tool is globally activated.
- If you face any issues with file permissions or paths, double-check the output directory paths provided in the command.

## Troubleshooting

### 1. Plugin Not Found
If you see an error like `Could not find package 'fetch_and_convert'`, ensure that:
- You’ve correctly added the plugin as a dev dependency in your `pubspec.yaml`.
- The plugin’s `bin/fetch_and_convert.dart` file exists.

### 2. Icons Not Showing
If the icons are not showing in your Flutter app:
- Ensure that you’ve correctly added the font in the `pubspec.yaml`.
- Double-check the font family name (`CustomIcons`) and make sure the path to the `custom_icons.ttf` file is correct.
