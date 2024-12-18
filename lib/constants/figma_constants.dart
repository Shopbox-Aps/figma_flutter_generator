class FigmaConstants {
  // API Constants
  static const String baseUrl = 'https://api.figma.com/v1';
  static const String variablesEndpoint = '/variables/local';
  
  // Collection Names
  static const String mappedCollectionName = '1. ✨Mapped';
  
  // Headers
  static const String authHeader = 'X-Figma-Token';
  
  // Variable Types
  static const String colorType = 'COLOR';
  static const String floatType = 'FLOAT';
  static const String stringType = 'STRING';
  
  // Component Types
  static const String componentType = 'COMPONENT';
  
  // Error Messages
  static const String invalidResponseError = 'Invalid API response structure';
  static const String mappedCollectionNotFoundError = 'Mapped collection not found';
  static const String fetchVariablesError = 'Failed to fetch variables from Figma';
  
  // File Structure
  static const String svgDirectory = 'svg';
  static const String fontDirectory = 'font';
  static const String libDirectory = 'lib';
  static const String iconsDirectory = 'icons';
  
  // File Extensions
  static const String svgExtension = 'svg';
  static const String pdfExtension = 'pdf';
  
  // Reserved Words
  static const Set<String> dartReservedWords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'library', 'mixin',
    'new', 'null', 'operator', 'part', 'rethrow', 'return', 'set', 'show',
    'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try',
    'typedef', 'var', 'void', 'while', 'with', 'yield',
  };
} 