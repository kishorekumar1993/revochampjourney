String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase()}_repository.dart';",
  );
  buffer.writeln("import '../../../widget/common_radiobutton.dart';");
  buffer.writeln("import '../../../widget/common_dropdown_search.dart';");

  final dropdownModels = <String>{}; // ✅ Collect required dropdown model names

  void parseField(Map<String, dynamic> field) {
    final type = field['type'] ?? '';
    if (type == 'Dropdown') {
      final List<dynamic>? staticOpts =
          field['staticOptions'] as List<dynamic>?;
      // only add if staticOptions is null or empty
      if (staticOpts == null || staticOpts.isEmpty) {
        final label = (field['label'] ?? '').toString().trim();
        dropdownModels.add(label);
      }
    }
  }

  // Preprocess fields to collect model imports
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      parseField(item);
    }
  }

  // // ✅ Now write dynamic model imports
  // for (final model in dropdownModels) {
  //   buffer.writeln(
  //     "import '../model/${model.toLowerCase().toString().replaceAll(" ", "_")}_model.dart';",
  //   );
  // }
  // ✅ Now write dynamic model imports
  // 2️⃣ Import each needed model exactly once
  for (final model in dropdownModels) {
    final fileName = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../model/${fileName}_model.dart';");
  }
  // Class start
  buffer.writeln("\nclass ${className}Controller extends GetxController {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln("  ${className}Controller(this.repository);\n");

  final dropdownInitCalls = <String>[];
  final dropdownInitCallsvariable = <String>[];

  buffer.writeln('final isLoading = false.obs;');
  // ✅ Redo the parsing for field declarations (after imports)
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      final type = item['type'] ?? '';
      final rawLabel = (item['label'] ?? '').toString().trim();
      final name = camelCaseName(rawLabel);
      final capitalLabel = pascalCaseName(rawLabel);
      var apidata = item['dropdowndata'];
      var dropdownmodel = item['modelName'] ?? '${capitalLabel}Model';

      if (apidata is Map<String, dynamic>) {
        for (final entry in apidata.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List &&
              value.isNotEmpty &&
              value.first is Map<String, dynamic>) {
            dropdownmodel = capitalize(key);
            break;
          }
        }
      }

      switch (type) {
        case 'TextField':
          buffer.writeln(
            "  /// Controller for the ${rawLabel.replaceAll('(', '\\(').replaceAll(')', '\\)')} field",
          );
          buffer.writeln(
            "  final ${name}Controller = TextEditingController();",
          );
          break;
        case 'Date Time':
        case 'Date':
          buffer.writeln(
            "  /// Controller for the ${rawLabel.replaceAll('(', '\\(').replaceAll(')', '\\)')} field",
          );
          buffer.writeln(
            "  final ${name}Controller = TextEditingController();",
          );
          break;
        case 'Dropdown':
          buffer.writeln("  /// Dropodown selection for the $rawLabel field");
          // if your JSON has a `staticOptions` key, generate a hard-coded list
          if (item.containsKey('staticOptions') &&
              (item['staticOptions'] as List).isNotEmpty) {
            // build the list literal from staticOptions
            // final List<Map<String, String>> opts =
            //     List<Map<String, String>>.from(item['staticOptions']);
            // final literals = opts
            //     .map((opt) {
            //       final k = opt['key']!.replaceAll("'", "\\'");
            //       final v = opt['value']!.replaceAll("'", "\\'");
            //       return "DropdownItem(key: '$k', value: '$v')";
            //     })
            //     .join(', ');

            // buffer.writeln(
            //   "  var selected$capitalLabel = Rxn<DropdownItem>();",
            // );
            // buffer.writeln(
            //   "  final ${name}Options = <DropdownItem>[$literals].obs;",
            // );
            final staticOptionsRaw = item['staticOptions'];
            if (staticOptionsRaw is List && staticOptionsRaw.isNotEmpty) {
              final opts = staticOptionsRaw
                  .whereType<Map<String, dynamic>>()
                  .map((opt) {
                    final k = (opt['key'] ?? '').toString().replaceAll(
                      "'",
                      "\\'",
                    );
                    final v = (opt['value'] ?? '').toString().replaceAll(
                      "'",
                      "\\'",
                    );
                    return "DropdownItem(key: '$k', value: '$v')";
                  })
                  .join(', ');

              buffer.writeln(
                "  var selected$capitalLabel = Rxn<DropdownItem>();",
              );
              buffer.writeln(
                "  final ${name}Options = <DropdownItem>[$opts].obs;",
              );
            }
          } else {
            // fall back to API-backed dropdown
            buffer.writeln(
              "  var selected$capitalLabel = Rxn<$dropdownmodel>();",
            );
            buffer.writeln("  var ${name}Options = <$dropdownmodel>[].obs;");
            dropdownInitCallsvariable.add("    load$capitalLabel();");
            dropdownInitCalls.add("// API Call for the $capitalLabel()");
            dropdownInitCalls.add(" Future<void> load$capitalLabel() async {");

            dropdownInitCalls.add("   try {");
            dropdownInitCalls.add(
              "    final ${name}Data = await repository.get$capitalLabel();",
            );
            dropdownInitCalls.add(
              "    ${name}Options.assignAll(${name}Data);\n",
            );

            dropdownInitCalls.add("          } catch (e, st) {");

            dropdownInitCalls.add(
              "              debugPrint('Error loading $capitalLabel: \$e');",
            );

            dropdownInitCalls.add("     debugPrintStack(stackTrace: st);");
            dropdownInitCalls.add(
              "    Get.snackbar('Error', 'Failed to load $capitalLabel');",
            );
            dropdownInitCalls.add("  }");
            dropdownInitCalls.add("}");
          }

          break;
        case 'Checkbox':
          buffer.writeln("  /// Checkbox state for the $rawLabel field");
          buffer.writeln("  var is${capitalLabel}Checked = false.obs;");
          break;
        case 'Radio Buttons':
          buffer.writeln(
            "  /// Radio button selection for the $rawLabel field",
          );
          final staticOptions = item['staticOptions'] ?? [];
          final formattedOptions = staticOptions
              .map((e) {
                final key = e['key'].toString().replaceAll("'", "\\'");
                final labelText = e['value'].toString().replaceAll("'", "\\'");
                return "RadioOption<String>(value: '$key', label: '$labelText')";
              })
              .join(', ');

          buffer.writeln("  var selected$name = ''.obs;");
          buffer.writeln(
            "  List<RadioOption<String>> ${name}Options = [$formattedOptions];",
          );
          break;

        default:
          buffer.writeln("  var $name = ''.obs;");
      }
    }
  }

  // onInit
  buffer.writeln("\n  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("     loadDropdowns();");
  }
  buffer.writeln("  }\n");

  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("  \n");
    buffer.writeln("/// Loads all Api values asynchronously");

    buffer.writeln("  Future<void> loadDropdowns() async {");
    buffer.writeln('  isLoading.value = true;');
    buffer.writeln("  try{");
    buffer.writeln("   await Future.wait([");
    for (var call in dropdownInitCallsvariable) {
      buffer.writeln(call);
    }
    buffer.writeln("      ]);");
    buffer.writeln("  } catch (e, st) {");
    buffer.writeln("    debugPrint('Error loading dropdowns: \$e');");
    buffer.writeln("    debugPrintStack(stackTrace: st);");
    buffer.writeln("  } finally {");

    buffer.writeln("isLoading.value = false;");
    buffer.writeln("}");
    buffer.writeln("  }\n");
  }

  for (var call in dropdownInitCalls) {
    buffer.writeln(call);
  }

  // onClose
  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  //  buffer.writeln("try{");
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      final label = (item['label'] ?? '').toString().trim().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final labelname = label[0].toLowerCase() + label.substring(1);
      final name = labelname.replaceAll(RegExp(r'\s+'), '');
      final capitalLabel = capitalize(label);
      final type = item['type'] ?? '';

      // Dispose only TextEditingControllers
      if (type == 'TextField' || type == 'Date' || type == 'Date Time') {
        buffer.writeln("    ${name}Controller.dispose();");
      } else if (type == 'Dropdown') {
        buffer.writeln("    selected$capitalLabel.value = null;");
      } else if (type == 'Checkbox') {
        buffer.writeln("    is${capitalLabel}Checked.value = false;");
      } else if (type == 'Radio Buttons') {
        final lowerLabel = capitalLabel.toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );
        buffer.writeln("    selected$lowerLabel.value = '';");
      }
    }
  }

  //  buffer.writeln("  }catch (e){}");

  buffer.writeln("    super.onClose();");
  buffer.writeln("  }");

  // clearForm
  buffer.writeln("\n  void clearForm() {");
  for (var item in configList.expand((e) => e is Iterable ? e : [e])) {
    if (item is Map<String, dynamic>) {
      final type = item['type'] ?? '';
      final label = (item['label'] ?? '').toString().trim().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      // final label = (item['label'] ?? '').toString().trim();
      final capitalLabel = capitalize(label);
      // final label = (item['label'] ?? '').toString().trim();
      // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final labelname = label[0].toLowerCase() + label.substring(1);
      final name = labelname.replaceAll(RegExp(r'\s+'), '');

      switch (type) {
        case 'TextField':
        case 'Date':
        case 'Date Time':
          buffer.writeln("    ${name}Controller.clear();");
          break;
        case 'Dropdown':
          buffer.writeln("    selected$capitalLabel.value = null;");
          break;
        case 'Checkbox':
          buffer.writeln("    is${capitalLabel}Checked.value = false;");
          break;
        case 'Radio Buttons':
          final lowerLabel = capitalLabel.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            '',
          );
          buffer.writeln(
            "    selected$lowerLabel.value = '';",
          ); // Reset to empty string
          break;
      }
    }
  }
  buffer.writeln("  }\n");

  buffer.writeln("}");

  return buffer.toString();
}

String getType(dynamic value, String key) {
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is List) {
    if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      return 'List<${capitalize(key)}>';
    }
    return 'List<dynamic>';
  }
  if (value is Map<String, dynamic>) {
    return capitalize(key);
  }
  return 'dynamic';
}

// 🔹 Helpers
String normalizeLabel(String label) =>
    label.trim().replaceAll(RegExp(r'\s+'), '');

String camelCaseName(String label) {
  final normalized = normalizeLabel(label);
  return normalized.isEmpty
      ? ''
      : normalized[0].toLowerCase() + normalized.substring(1);
}

String pascalCaseName(String label) {
  final normalized = normalizeLabel(label);
  return normalized.isEmpty
      ? ''
      : normalized[0].toUpperCase() + normalized.substring(1);
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
