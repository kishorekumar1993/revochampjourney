

/// Generates the GetX router files and returns them in the standard map format.
///
/// Returns a list of maps with keys:
///   `folderPath` – e.g. `lib/getx/features/motor_insurance/routing`
///   `fileName`   – e.g. `app_pages.dart` or `app_routes.dart`
///   `textContent`– the complete file content
List<Map<String, String>> generateGetXRouterFromSteps(
  List<dynamic> steps,   // ← changed
  String journeyNamespace,
) {
  // Cast to Map<String, dynamic> safely
  steps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  
  final files = <Map<String, String>>[];
  final bufferPages = StringBuffer();
  final bufferRoutes = StringBuffer();

  // ── 1. File header & imports ─────────────────────────────────
  final header = "// GENERATED CODE – DO NOT MODIFY BY HAND\n";
  bufferPages.writeln(header);
  bufferPages.writeln("import 'package:get/get.dart';");
  bufferPages.writeln();

  // Collect view / binding names (for imports)
  final views = <String>{};
  final bindings = <String>{};
  for (final step in steps) {
    final id = step['id'] as String?;
    if (id == null || id.isEmpty) continue;
    views.add('${_pascalCase(id)}View');
    bindings.add('${_pascalCase(id)}Binding');
  }

  // Imports (adjust paths as needed)
  for (final view in views) {
    final snake = _toSnakeCase(view.replaceAll('View', ''));
    bufferPages.writeln(
      "import '../../features/$journeyNamespace/$snake/view/${snake}_view.dart';",
    );
  }
  for (final binding in bindings) {
    final snake = _toSnakeCase(binding.replaceAll('Binding', ''));
    bufferPages.writeln(
      "import '../../features/$journeyNamespace/$snake/binding/${snake}_binding.dart';",
    );
  }
  bufferPages.writeln();

  // ── 2. AppRoutes constants class (optional separate file) ────
  bufferRoutes.writeln("// GENERATED CODE – DO NOT MODIFY BY HAND");
  bufferRoutes.writeln("abstract class AppRoutes {");
  for (final step in steps) {
    final id = step['id'] as String?;
    if (id == null) continue;
    final routeName = _camelCase(id);
    bufferRoutes.writeln("  static const String $routeName = '/$id';");
  }
  bufferRoutes.writeln("}");

  // ── 3. AppPages class ────────────────────────────────────────
  bufferPages.writeln("class AppPages {");
  bufferPages.writeln("  static final List<GetPage> pages = [");

  for (final step in steps) {
    final id = step['id'] as String?;
    if (id == null) continue;

    final routeName = _camelCase(id);
    final viewClass = '${_pascalCase(id)}View';
    final bindingClass = '${_pascalCase(id)}Binding';

    bufferPages.writeln("    GetPage(");
    bufferPages.writeln("      name: AppRoutes.$routeName,");
    bufferPages.writeln("      page: () => $viewClass(),");
    bufferPages.writeln("      binding: $bindingClass(),");
    bufferPages.writeln("    ),");
  }

  bufferPages.writeln("  ];");
  bufferPages.writeln("}");

  // ── 4. Build output maps ─────────────────────────────────────
  final routingFolder = 'lib/getx/features/$journeyNamespace/routing';

  files.add({
    'folderPath': routingFolder,
    'fileName': 'app_pages.dart',
    'textContent': bufferPages.toString(),
  });

  files.add({
    'folderPath': routingFolder,
    'fileName': 'app_routes.dart',
    'textContent': bufferRoutes.toString(),
  });

  return files;
}

// Helpers – identical to your existing naming conventions
String _camelCase(String input) {
  if (input.isEmpty) return '';
  final parts = input.split(RegExp(r'[_\-\s]+'));
  final first = parts[0].toLowerCase();
  final rest = parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  return '$first$rest';
}

String _pascalCase(String input) {
  if (input.isEmpty) return '';
  return input.split(RegExp(r'[_\-\s]+'))
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join();
}

String _toSnakeCase(String input) {
  return input.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (m) => '_${m.group(1)!.toLowerCase()}',
  ).replaceFirst(RegExp(r'^_'), '').toLowerCase();
}