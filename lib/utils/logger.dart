/// A utility class for consistent logging throughout the application.
///
/// This class provides static methods for logging messages with different
/// severity levels and color-coded output for better visibility.
class Logger {
  /// ANSI escape codes for text colors
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';

  /// Logs an informational message in blue.
  ///
  /// Use this for general information that might be helpful to know
  /// but doesn't indicate a problem or success.
  ///
  /// Example:
  /// ```dart
  /// Logger.info('Processing file: example.svg');
  /// ```
  static void info(String message) {
    print('${_blue}INFO: $message$_reset');
  }

  /// Logs a success message in green.
  ///
  /// Use this to indicate that an operation completed successfully.
  ///
  /// Example:
  /// ```dart
  /// Logger.success('Icon font generated successfully');
  /// ```
  static void success(String message) {
    print('${_green}SUCCESS: $message$_reset');
  }

  /// Logs a warning message in yellow.
  ///
  /// Use this for potentially problematic situations that don't prevent
  /// the program from continuing but should be noted.
  ///
  /// Example:
  /// ```dart
  /// Logger.warning('File already exists, overwriting');
  /// ```
  static void warning(String message) {
    print('${_yellow}WARNING: $message$_reset');
  }

  /// Logs an error message in red.
  ///
  /// Use this for errors that prevent normal operation or indicate
  /// a serious problem that needs attention.
  ///
  /// Example:
  /// ```dart
  /// Logger.error('Failed to connect to Figma API');
  /// ```
  static void error(String message) {
    print('${_red}ERROR: $message$_reset');
  }

  /// Logs a debug message in blue.
  ///
  /// Use this for detailed information that is helpful during
  /// development or troubleshooting. These messages should only
  /// be shown when verbose logging is enabled.
  ///
  /// Example:
  /// ```dart
  /// Logger.debug('API response received: $response');
  /// ```
  static void debug(String message) {
    print('${_blue}DEBUG: $message$_reset');
  }
}
