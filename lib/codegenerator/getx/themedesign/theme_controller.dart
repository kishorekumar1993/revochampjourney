String generateThemeControllerClass(
  String className,
  String fileName, {
  bool isNested = false,
}) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import 'package:get_storage/get_storage.dart';");
  buffer.writeln("import 'package:flutter/material.dart';\n");

  buffer.writeln("class $className extends GetxController {");
  buffer.writeln("  static const String _key = 'isDarkMode';");
  buffer.writeln("  final GetStorage _box = GetStorage();\n");

  buffer.writeln("  /// Reactive observable for UI theme listening");
  buffer.writeln("  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;\n");

  buffer.writeln("  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  buffer.writeln("    themeMode.value = _loadTheme() ? ThemeMode.dark : ThemeMode.light;");
  buffer.writeln("    Get.changeThemeMode(themeMode.value);");
  buffer.writeln("  }\n");

  buffer.writeln("  /// Load theme from local storage");
  buffer.writeln("  bool _loadTheme() => _box.read(_key) ?? false;\n");

  buffer.writeln("  /// Save theme to local storage");
  buffer.writeln("  void _saveTheme(bool isDarkMode) => _box.write(_key, isDarkMode);\n");

  buffer.writeln("  /// Switch theme (light <-> dark)");
  buffer.writeln("  void switchTheme() {");
  buffer.writeln("    final isDark = _loadTheme();");
  buffer.writeln("    final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;");
  buffer.writeln("    Get.changeThemeMode(newTheme);");
  buffer.writeln("    themeMode.value = newTheme;");
  buffer.writeln("    _saveTheme(!isDark);");
  buffer.writeln("  }\n");

  buffer.writeln("  /// Set theme explicitly from UI switch");
  buffer.writeln("  void setTheme(bool isDarkMode) {");
  buffer.writeln("    final newTheme = isDarkMode ? ThemeMode.dark : ThemeMode.light;");
  buffer.writeln("    Get.changeThemeMode(newTheme);");
  buffer.writeln("    themeMode.value = newTheme;");
  buffer.writeln("    _saveTheme(isDarkMode);");
  buffer.writeln("  }");

  buffer.writeln("}");

  return buffer.toString();
}

