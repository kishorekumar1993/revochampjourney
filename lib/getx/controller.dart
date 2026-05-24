String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Flatten fields once ──────────────────────────────────────
  final flatFields = configList
      .expand((e) => e is Iterable ? e : [e])
      .whereType<Map<String, dynamic>>()
      .toList();

  // ─── Conditional imports ──────────────────────────────────────
  final hasRadio = flatFields.any((f) =>
      (f['type'] ?? '').toString().toLowerCase().startsWith('radio'));
  final hasDropdown = flatFields.any((f) =>
      (f['type'] ?? '').toString().toLowerCase() == 'dropdown');

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase()}_repository.dart';",
  );
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  if (hasDropdown)
    buffer.writeln("import '/widget/common_dropdown_search.dart';");

  // ─── Dynamic dropdown model imports ──────────────────────────
  final dropdownModels = <String>{};
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown') {
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if (staticOpts == null || staticOpts.isEmpty) {
        dropdownModels.add((field['label'] ?? '').toString().trim());
      }
    }
  }
  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../model/${modelFile}_model.dart';");
  }

  buffer.writeln();
  buffer.writeln("class ${className}Controller extends GetxController {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln("  ${className}Controller(this.repository);");
  buffer.writeln();
  buffer.writeln("  final isLoading = false.obs;");
  buffer.writeln();

  final dropdownInitCallsvariable = <String>[];
  final dropdownInitCalls = <String>[];

  // ─── Field declarations ───────────────────────────────────────
  for (final item in flatFields) {
    final rawLabel = (item['label'] ?? '').toString().trim();
    final name = camelCaseName(rawLabel);
    final capitalLabel = pascalCaseName(rawLabel);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();

    // Resolve dropdown model name
    var dropdownmodel =
        (item['modelName'] ?? '${capitalLabel}Model').toString();
    final apidata = item['dropdowndata'];
    if (apidata is Map<String, dynamic>) {
      for (final entry in apidata.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
          dropdownmodel = capitalize(entry.key);
          break;
        }
      }
    }

    // Support both 'options' (JSON) and 'staticOptions' (legacy)
    final staticOpts = (item['options'] as List<dynamic>?) ??
        (item['staticOptions'] as List<dynamic>?);

    switch (type) {
      // ── Text / Phone / TextArea / OTP → TextEditingController ──
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
        buffer.writeln("  /// Controller for '$rawLabel' field");
        buffer.writeln(
            "  final ${name}Controller = TextEditingController();");
        break;

      // ── Date / DateTime ─────────────────────────────────────────
      case 'date':
      case 'datetime':
      case 'date time':
        buffer.writeln("  /// Controller for '$rawLabel' date field");
        buffer.writeln(
            "  final ${name}Controller = TextEditingController();");
        break;

      // ── Dropdown ─────────────────────────────────────────────────
      case 'dropdown':
        buffer.writeln("  /// Dropdown selection for '$rawLabel' field");
        if (staticOpts != null && staticOpts.isNotEmpty) {
          // ✅ FIXED: both key and value required by DropdownItem
          final literals = staticOpts.map((o) {
            final val = o.toString().replaceAll("'", "\\'");
            return "DropdownItem(key: '$val', value: '$val')";
          }).join(', ');

          buffer.writeln(
              "  var selected$capitalLabel = Rxn<DropdownItem>();");
          buffer.writeln(
              "  final ${name}Options = <DropdownItem>[$literals].obs;");
        } else {
          // API-backed dropdown
          buffer.writeln(
              "  var selected$capitalLabel = Rxn<$dropdownmodel>();");
          buffer.writeln(
              "  var ${name}Options = <$dropdownmodel>[].obs;");
          dropdownInitCallsvariable.add("      load$capitalLabel(),");
          dropdownInitCalls.addAll([
            "  // ── API loader for $capitalLabel ──────────────────────",
            "  Future<void> load$capitalLabel() async {",
            "    try {",
            "      final data = await repository.get$capitalLabel();",
            "      ${name}Options.assignAll(data);",
            "    } catch (e, st) {",
            "      debugPrint('Error loading $capitalLabel: \$e');",
            "      debugPrintStack(stackTrace: st);",
            "      Get.snackbar('Error', 'Failed to load $capitalLabel');",
            "    }",
            "  }",
            "",
          ]);
        }
        break;

      // ── Radio ─────────────────────────────────────────────────────
      case 'radio':
      case 'radio buttons':
        buffer.writeln("  /// Radio selection for '$rawLabel' field");
        if (staticOpts != null && staticOpts.isNotEmpty) {
          final formattedOptions = staticOpts.map((o) {
            final val = o.toString().replaceAll("'", "\\'");
            return "RadioOption<String>(value: '$val', label: '$val')";
          }).join(', ');
          buffer.writeln(
              "  var selected$capitalLabel = ''.obs;");
          buffer.writeln(
              "  final ${name}Options = <RadioOption<String>>[$formattedOptions];");
        } else {
          buffer.writeln(
              "  var selected$capitalLabel = ''.obs;");
          buffer.writeln(
              "  final ${name}Options = <RadioOption<String>>[];");
        }
        break;

      // ── Switch ────────────────────────────────────────────────────
      case 'switch':
        buffer.writeln("  /// Switch state for '$rawLabel' field");
        final defaultVal =
            (item['defaultValue'] ?? 'false').toString().toLowerCase() ==
                'true';
        buffer.writeln("  var ${name}Value = $defaultVal.obs;");
        break;

      // ── File ──────────────────────────────────────────────────────
      case 'file':
        buffer.writeln("  /// File upload state for '$rawLabel' field");
        buffer.writeln("  var ${name}FileName = ''.obs;");
        buffer.writeln("  var ${name}FilePath = ''.obs;");
        buffer.writeln(
            "  Future<void> pick${capitalLabel}File() async {");
        buffer.writeln("    // TODO: integrate file_picker package");
        buffer.writeln(
            "    // final result = await FilePicker.platform.pickFiles();");
        buffer.writeln("    // if (result != null) {");
        buffer.writeln(
            "    //   ${name}FileName.value = result.files.single.name;");
        buffer.writeln(
            "    //   ${name}FilePath.value = result.files.single.path ?? '';");
        buffer.writeln("    // }");
        buffer.writeln("  }");
        buffer.writeln();
        break;

      // ── Checkbox ──────────────────────────────────────────────────
      case 'checkbox':
        buffer.writeln("  /// Checkbox state for '$rawLabel' field");
        buffer.writeln(
            "  var is${capitalLabel}Checked = false.obs;");
        break;

      // ── Divider — no state needed ─────────────────────────────────
      case 'divider':
        break;

      default:
        buffer.writeln(
            "  // TODO: unsupported field type '$type' for '$rawLabel'");
        buffer.writeln("  var $name = ''.obs;");
    }
  }

  // ─── onInit ───────────────────────────────────────────────────
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  if (dropdownInitCallsvariable.isNotEmpty) {
    buffer.writeln("    loadDropdowns();");
  }
  buffer.writeln("  }");
  buffer.writeln();

  // ─── loadDropdowns ────────────────────────────────────────────
  if (dropdownInitCallsvariable.isNotEmpty) {
    buffer.writeln("  /// Loads all API-backed dropdowns in parallel");
    buffer.writeln("  Future<void> loadDropdowns() async {");
    buffer.writeln("    isLoading.value = true;");
    buffer.writeln("    try {");
    buffer.writeln("      await Future.wait([");
    for (final call in dropdownInitCallsvariable) {
      buffer.writeln("        $call");
    }
    buffer.writeln("      ]);");
    buffer.writeln("    } catch (e, st) {");
    buffer.writeln("      debugPrint('Error loading dropdowns: \$e');");
    buffer.writeln("      debugPrintStack(stackTrace: st);");
    buffer.writeln("    } finally {");
    buffer.writeln("      isLoading.value = false;");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();

    for (final line in dropdownInitCalls) {
      buffer.writeln("  $line");
    }
  }

  // ─── onClose ─────────────────────────────────────────────────
  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  for (final item in flatFields) {
    final rawLabel = (item['label'] ?? '').toString().trim();
    final name = camelCaseName(rawLabel);
    final capitalLabel = pascalCaseName(rawLabel);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();

    switch (type) {
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
      case 'date':
      case 'datetime':
      case 'date time':
        buffer.writeln("    ${name}Controller.dispose();");
        break;
      case 'dropdown':
        buffer.writeln("    selected$capitalLabel.value = null;");
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$capitalLabel.value = '';");
        break;
      case 'switch':
        buffer.writeln("    ${name}Value.value = false;");
        break;
      case 'checkbox':
        buffer.writeln("    is${capitalLabel}Checked.value = false;");
        break;
      case 'file':
        buffer.writeln("    ${name}FileName.value = '';");
        buffer.writeln("    ${name}FilePath.value = '';");
        break;
      // divider → nothing
    }
  }
  buffer.writeln("    super.onClose();");
  buffer.writeln("  }");
  buffer.writeln();

  // ─── clearForm ───────────────────────────────────────────────
  buffer.writeln("  void clearForm() {");
  for (final item in flatFields) {
    final rawLabel = (item['label'] ?? '').toString().trim();
    final name = camelCaseName(rawLabel);
    final capitalLabel = pascalCaseName(rawLabel);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();

    switch (type) {
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
      case 'date':
      case 'datetime':
      case 'date time':
        buffer.writeln("    ${name}Controller.clear();");
        break;
      case 'dropdown':
        buffer.writeln("    selected$capitalLabel.value = null;");
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$capitalLabel.value = '';");
        break;
      case 'switch':
        buffer.writeln("    ${name}Value.value = false;");
        break;
      case 'checkbox':
        buffer.writeln("    is${capitalLabel}Checked.value = false;");
        break;
      case 'file':
        buffer.writeln("    ${name}FileName.value = '';");
        buffer.writeln("    ${name}FilePath.value = '';");
        break;
      // divider → nothing
    }
  }
  buffer.writeln("  }");
  buffer.writeln("}");

  return buffer.toString();
}

// ─── Helpers ─────────────────────────────────────────────────────
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String normalizeLabel(String label) =>
    label.trim().replaceAll(RegExp(r'\s+'), '');

String camelCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toLowerCase() + n.substring(1);
}

String pascalCaseName(String label) {
  final n = normalizeLabel(label);
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
}
