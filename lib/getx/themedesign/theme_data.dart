
String generateThemeClass(String className, Map<String, dynamic> json, String fileName, {bool isNested = false,String fontName = "roboto", Map<String, double>? fontSizes}) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:flutter/material.dart';\n");
  buffer.writeln("import 'package:google_fonts/google_fonts.dart';\n");

  buffer.writeln("class $className {");

  void writeTextTheme(String fontName, [Map<String, double>? fontSizes]) {
  String fontFunc = "GoogleFonts.$fontName";

  final textStyles = {
    "displayLarge": {"size": fontSizes?["displayLarge"] ?? 48.0, "weight": "FontWeight.bold"},
    "displayMedium": {"size": fontSizes?["displayMedium"] ?? 40.0, "weight": "FontWeight.bold"},
    "displaySmall": {"size": fontSizes?["displaySmall"] ?? 32.0, "weight": "FontWeight.bold"},
    "headlineLarge": {"size": fontSizes?["headlineLarge"] ?? 28.0, "weight": "FontWeight.bold"},
    "headlineMedium": {"size": fontSizes?["headlineMedium"] ?? 24.0, "weight": "FontWeight.bold"},
    "headlineSmall": {"size": fontSizes?["headlineSmall"] ?? 20.0, "weight": "FontWeight.w600"},
    "titleLarge": {"size": fontSizes?["titleLarge"] ?? 18.0, "weight": "FontWeight.w600"},
    "titleMedium": {"size": fontSizes?["titleMedium"] ?? 16.0, "weight": "FontWeight.w500"},
    "titleSmall": {"size": fontSizes?["titleSmall"] ?? 14.0, "weight": "FontWeight.w500"},
    "bodyLarge": {"size": fontSizes?["bodyLarge"] ?? 16.0},
    "bodyMedium": {"size": fontSizes?["bodyMedium"] ?? 14.0},
    "bodySmall": {"size": fontSizes?["bodySmall"] ?? 12.0},
    "labelLarge": {"size": fontSizes?["labelLarge"] ?? 14.0},
    "labelMedium": {"size": fontSizes?["labelMedium"] ?? 12.0},
    "labelSmall": {"size": fontSizes?["labelSmall"] ?? 10.0},
  };

  buffer.writeln("    textTheme: TextTheme(");

  textStyles.forEach((styleName, config) {
    final size = config["size"];
    final weight = config["weight"];
    if (weight != null) {
      buffer.writeln(
          "      $styleName: $fontFunc(fontSize: $size, fontWeight: $weight),");
    } else {
      buffer.writeln(
          "      $styleName: $fontFunc(fontSize: $size),");
    }
  });

  buffer.writeln("    ),");
}


  buffer.writeln("  static final ThemeData lightTheme = ThemeData(");
  buffer.writeln("    brightness: Brightness.light,");
  buffer.writeln("    primaryColor: ${json['Primary'] ?? 'Colors.blue'},");
  buffer.writeln("    colorScheme: ColorScheme.light(");
  buffer.writeln("      primary: ${json['Primary'] ?? 'Colors.blue'},");
  buffer.writeln("      secondary: ${json['Secondary'] ?? 'Colors.orange'},");
  buffer.writeln("      background: ${json['Background'] ?? 'Colors.white'},");
  buffer.writeln("      surface: ${json['Surface'] ?? 'Colors.grey[200]!'},");
  buffer.writeln("      error: ${json['Error'] ?? 'Colors.red'},");
  buffer.writeln("      onPrimary: ${json['OnPrimary'] ?? 'Colors.white'},");
  buffer.writeln("      onSecondary: ${json['OnSecondary'] ?? 'Colors.black'},");
  buffer.writeln("      onBackground: ${json['OnBackground'] ?? 'Colors.black'},");
  buffer.writeln("      onSurface: ${json['OnSurface'] ?? 'Colors.black'},");
  buffer.writeln("      onError: ${json['OnError'] ?? 'Colors.white'},");
  buffer.writeln("    ),");
  buffer.writeln("    appBarTheme: AppBarTheme(");
  buffer.writeln("      backgroundColor: ${json['lightAppBarColor'] ?? 'Colors.blue'},");
  buffer.writeln("      foregroundColor: ${json['lightAppBarForegroundColor'] ?? 'Colors.white'},");
  buffer.writeln("    ),");
  buffer.writeln("    elevatedButtonTheme: ElevatedButtonThemeData(");
  buffer.writeln("      style: ElevatedButton.styleFrom(");
  buffer.writeln("        backgroundColor: ${json['lightButtonColor'] ?? 'Colors.blue'},");
  buffer.writeln("        foregroundColor: ${json['lightButtonForegroundColor'] ?? 'Colors.white'},");
  buffer.writeln("        shape: RoundedRectangleBorder(");
  buffer.writeln("          borderRadius: BorderRadius.circular(${json['buttonBorderRadius'] ?? 12}),");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    ),");
  // buffer.writeln("    textTheme: const TextTheme(");
  // buffer.writeln("      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),");
  // buffer.writeln("      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),");
  // buffer.writeln("      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),");
  // buffer.writeln("      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),");
  // buffer.writeln("      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),");
  // buffer.writeln("      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),");
  // buffer.writeln("      bodyLarge: TextStyle(fontSize: 16),");
  // buffer.writeln("      bodyMedium: TextStyle(fontSize: 14),");
  // buffer.writeln("      bodySmall: TextStyle(fontSize: 12),");
  // buffer.writeln("      labelLarge: TextStyle(fontSize: 14),");
  // buffer.writeln("      labelMedium: TextStyle(fontSize: 12),");
  // buffer.writeln("      labelSmall: TextStyle(fontSize: 10),");
  // buffer.writeln("    ),");
   writeTextTheme(fontName); // Uses GoogleFonts.roboto

  buffer.writeln("  );\n");

  // Dark Theme
  buffer.writeln("  static final ThemeData darkTheme = ThemeData(");
  buffer.writeln("    brightness: Brightness.dark,");
  buffer.writeln("    primaryColor: ${json['darkPrimaryColor'] ?? 'Colors.blue'},");
  buffer.writeln("    colorScheme: ColorScheme.dark(");
  buffer.writeln("      primary: ${json['darkPrimaryColor'] ?? 'Colors.blue'},");
  buffer.writeln("      secondary: ${json['darkSecondaryColor'] ?? 'Colors.orange'},");
  buffer.writeln("      background: ${json['darkBackgroundColor'] ?? 'Colors.black'},");
  buffer.writeln("      surface: ${json['darkSurfaceColor'] ?? 'Colors.grey[800]!'},");
  buffer.writeln("      error: ${json['darkErrorColor'] ?? 'Colors.red'},");
  buffer.writeln("      onPrimary: ${json['darkOnPrimaryColor'] ?? 'Colors.white'},");
  buffer.writeln("      onSecondary: ${json['darkOnSecondaryColor'] ?? 'Colors.white'},");
  buffer.writeln("      onBackground: ${json['darkOnBackgroundColor'] ?? 'Colors.white'},");
  buffer.writeln("      onSurface: ${json['darkOnSurfaceColor'] ?? 'Colors.white'},");
  buffer.writeln("      onError: ${json['darkOnErrorColor'] ?? 'Colors.black'},");
  buffer.writeln("    ),");
  buffer.writeln("    appBarTheme: AppBarTheme(");
  buffer.writeln("      backgroundColor: ${json['darkAppBarColor'] ?? 'Colors.grey[900]'},");
  buffer.writeln("      foregroundColor: ${json['darkAppBarForegroundColor'] ?? 'Colors.white'},");
  buffer.writeln("    ),");
  buffer.writeln("    elevatedButtonTheme: ElevatedButtonThemeData(");
  buffer.writeln("      style: ElevatedButton.styleFrom(");
  buffer.writeln("        backgroundColor: ${json['darkButtonColor'] ?? 'Colors.blue'},");
  buffer.writeln("        foregroundColor: ${json['darkButtonForegroundColor'] ?? 'Colors.white'},");
  buffer.writeln("        shape: RoundedRectangleBorder(");
  buffer.writeln("          borderRadius: BorderRadius.circular(${json['buttonBorderRadius'] ?? 12}),");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    ),");
   writeTextTheme(fontName); // Uses GoogleFonts.roboto

  // buffer.writeln("    textTheme: const TextTheme(");
  // buffer.writeln("      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),");
  // buffer.writeln("      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),");
  // buffer.writeln("      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),");
  // buffer.writeln("      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),");
  // buffer.writeln("      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),");
  // buffer.writeln("      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),");
  // buffer.writeln("      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),");
  // buffer.writeln("      bodyLarge: TextStyle(fontSize: 16),");
  // buffer.writeln("      bodyMedium: TextStyle(fontSize: 14),");
  // buffer.writeln("      bodySmall: TextStyle(fontSize: 12),");
  // buffer.writeln("      labelLarge: TextStyle(fontSize: 14),");
  // buffer.writeln("      labelMedium: TextStyle(fontSize: 12),");
  // buffer.writeln("      labelSmall: TextStyle(fontSize: 10),");
  // buffer.writeln("    ),");
  buffer.writeln("  );");

  buffer.writeln("}");

  return buffer.toString();
}
