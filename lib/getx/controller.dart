void _extractFieldsRecursive(dynamic fields, List<Map<String, dynamic>> flatFields) {
  if (fields == null) return;
  
  final fieldList = fields is List ? fields : [fields];
  
  for (final field in fieldList) {
    if (field is! Map<String, dynamic>) continue;
    
    // Add the field itself
    flatFields.add(Map<String, dynamic>.from(field));
    
    // Recursively extract nested fields
    final nestedFields = field['nestedFields'];
    if (nestedFields is List) {
      _extractFieldsRecursive(nestedFields, flatFields);
    }
    
    // Also check componentConfig for repeater/table nested fields
    final config = field['componentConfig'];
    if (config is Map) {
      final configFields = config['fields'] ?? config['columns'];
      if (configFields is List) {
        _extractFieldsRecursive(configFields, flatFields);
      }
    }
  }
}

String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Flatten fields once ──────────────────────────────────────
  final flatFields = <Map<String, dynamic>>[];
  for (final config in configList) {
    if (config is Map<String, dynamic>) {
      if (config.containsKey('steps') && config['steps'] is List) {
        for (final step in (config['steps'] as List)) {
          if (step is Map<String, dynamic> && step.containsKey('fields')) {
            _extractFieldsRecursive(step['fields'], flatFields);
          }
        }
      } else if (config.containsKey('fields')) {
        _extractFieldsRecursive(config['fields'], flatFields);
      } else if (config.containsKey('type')) {
        _extractFieldsRecursive(config, flatFields);
      }
    }
  }

  // ─── Conditional imports ──────────────────────────────────────
  final hasRadio = flatFields.any((f) =>
      (f['type'] ?? '').toString().toLowerCase().startsWith('radio'));
  final hasDropdown = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t == 'dropdown' || t == 'api_dropdown';
  });

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase()}_repository.dart';",
  );
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  if (hasDropdown) {
    buffer.writeln("import '/widget/common_dropdown_search.dart';");
  }

  // ─── Dynamic dropdown model imports ──────────────────────────
  final dropdownModels = <String>{};
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if (staticOpts == null || staticOpts.isEmpty) {
        final rawId = (field['id'] ?? field['label'] ?? 'model').toString().trim();
        dropdownModels.add(rawId);
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
  // Extra method bodies (file pickers, grid ops, etc.) collected here
  final extraMethods = <String>[];

  // ─── Field declarations ───────────────────────────────────────
  for (final item in flatFields) {
    final rawId = (item['id'] ?? item['fieldId'] ?? item['label'] ?? 'field').toString().trim();
    final name = camelCaseName(rawId);
    final capitalLabel = pascalCaseName(rawId);
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

    final staticOpts = (item['options'] as List<dynamic>?) ??
        (item['staticOptions'] as List<dynamic>?);

    switch (type) {
      // ══════════════════════════════════════════════
      //  Text / Phone / TextArea / OTP / Email / Password / Number / Decimal
      // ══════════════════════════════════════════════
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
      case 'email':
      case 'password':
      case 'number':
      case 'integer':
      case 'int':
      case 'decimal':
      case 'double':
      case 'float':
        buffer.writeln(
            "  final ${name}Controller = TextEditingController();");
        break;

      // ══════════════════════════════════════════════
      //  Date / DateTime / Time
      // ══════════════════════════════════════════════
      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
        buffer.writeln(
            "  final ${name}Controller = TextEditingController();");
        break;

      // ══════════════════════════════════════════════
      //  Dropdown
      // ══════════════════════════════════════════════
      case 'dropdown':
      case 'api_dropdown':
        if (staticOpts != null && staticOpts.isNotEmpty) {
          final literals = staticOpts.map((o) {
            if (o is Map) {
              final k = (o['key'] ?? o['value'] ?? o['id'] ?? '').toString().replaceAll("'", "\\'");
              final v = (o['value'] ?? o['label'] ?? o['title'] ?? '').toString().replaceAll("'", "\\'");
              return "DropdownItem(key: '$k', value: '$v')";
            }
            final val = o?.toString().replaceAll("'", "\\'") ?? '';
            return "DropdownItem(key: '$val', value: '$val')";
          }).join(', ');
          buffer.writeln(
              "  var selected$capitalLabel = Rxn<DropdownItem>();");
          buffer.writeln(
              "  final ${name}Options = <DropdownItem>[$literals].obs;");
        } else {
          buffer.writeln(
              "  var selected$capitalLabel = Rxn<$dropdownmodel>();");
          buffer.writeln(
              "  var ${name}Options = <$dropdownmodel>[].obs;");
          dropdownInitCallsvariable.add("      load$capitalLabel(),");
          dropdownInitCalls.addAll([
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

      // ══════════════════════════════════════════════
      //  Radio
      // ══════════════════════════════════════════════
      case 'radio':
      case 'radio buttons':
        if (staticOpts != null && staticOpts.isNotEmpty) {
          final formattedOptions = staticOpts.map((o) {
            if (o is Map) {
              final k = (o['key'] ?? o['value'] ?? o['id'] ?? '').toString().replaceAll("'", "\\'");
              final v = (o['value'] ?? o['label'] ?? o['title'] ?? '').toString().replaceAll("'", "\\'");
              return "RadioOption<String>(value: '$k', label: '$v')";
            }
            final val = o?.toString().replaceAll("'", "\\'") ?? '';
            return "RadioOption<String>(value: '$val', label: '$val')";
          }).join(', ');
          buffer.writeln("  var selected$capitalLabel = ''.obs;");
          buffer.writeln(
              "  final ${name}Options = <RadioOption<String>>[$formattedOptions];");
        } else {
          buffer.writeln("  var selected$capitalLabel = ''.obs;");
          buffer.writeln(
              "  final ${name}Options = <RadioOption<String>>[];");
        }
        break;

      // ══════════════════════════════════════════════
      //  Switch
      // ══════════════════════════════════════════════
      case 'switch':
        final defaultSwitchVal =
            (item['defaultValue'] ?? 'false').toString().toLowerCase() ==
                'true';
        buffer.writeln("  var ${name}Value = $defaultSwitchVal.obs;");
        break;

      // ══════════════════════════════════════════════
      //  Checkbox
      // ══════════════════════════════════════════════
      case 'checkbox':
        final defaultCheckVal =
            (item['defaultValue'] ?? 'false').toString().toLowerCase() ==
                'true';
        buffer.writeln("  var ${name}Value = $defaultCheckVal.obs;");
        break;

      // ══════════════════════════════════════════════
      //  File
      // ══════════════════════════════════════════════
      case 'file':
      case 'fileupload':
      case 'file upload':
        buffer.writeln("  var ${name}FileName = ''.obs;");
        buffer.writeln("  var ${name}FilePath = ''.obs;");
        extraMethods.addAll([
          "  Future<void> pick${capitalLabel}File() async {",
          "    // TODO: integrate file_picker package",
          "    // final result = await FilePicker.platform.pickFiles();",
          "    // if (result != null) {",
          "    //   ${name}FileName.value = result.files.single.name;",
          "    //   ${name}FilePath.value = result.files.single.path ?? '';",
          "    // }",
          "  }",
          "",
        ]);
        break;

      // ══════════════════════════════════════════════
      //  Image
      // ══════════════════════════════════════════════
      case 'image':
        buffer.writeln("  var ${name}FileName = ''.obs;");
        buffer.writeln("  var ${name}FilePath = ''.obs;");
        extraMethods.addAll([
          "  Future<void> pick${capitalLabel}Image() async {",
          "    // TODO: integrate image_picker package",
          "    // final picked = await ImagePicker().pickImage(source: ImageSource.gallery);",
          "    // if (picked != null) {",
          "    //   ${name}FileName.value = picked.name;",
          "    //   ${name}FilePath.value = picked.path;",
          "    // }",
          "  }",
          "",
        ]);
        break;

      // ══════════════════════════════════════════════
      //  Multiselect
      // ══════════════════════════════════════════════
      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        buffer.writeln("  final ${name}Selected = <String>[].obs;");
        if (staticOpts != null && staticOpts.isNotEmpty) {
          final optLiterals = staticOpts.map((o) {
            if (o is Map) {
              final v = (o['value'] ?? o['key'] ?? o['title'] ?? '').toString().replaceAll("'", "\\'");
              return "'$v'";
            }
            return "'${o?.toString().replaceAll("'", "\\'") ?? ''}'";
          }).join(', ');
          buffer.writeln(
              "  final ${name}Options = <String>[$optLiterals];");
        } else {
          buffer.writeln("  final ${name}Options = <String>[];");
        }
        break;

      // ══════════════════════════════════════════════
      //  Slider
      // ══════════════════════════════════════════════
      case 'slider':
      case 'range slider':
        final sliderDefault =
            (item['defaultValue'] as num?)?.toDouble() ??
            (item['minValue'] as num?)?.toDouble() ??
            0.0;
        buffer.writeln(
            "  var ${name}Value = $sliderDefault.obs;");
        break;

      // ══════════════════════════════════════════════
      //  Star Rating
      // ══════════════════════════════════════════════
      case 'starrating':
      case 'rating':
      case 'star rating':
        buffer.writeln("  var ${name}Value = 0.0.obs;");
        break;

      // ══════════════════════════════════════════════
      //  Grid / Table
      // ══════════════════════════════════════════════
      case 'grid':
      case 'table':
      case 'table/grid':
      case 'table grid':
      case 'table_grid':
        buffer.writeln(
            "  final ${name}Rows = <Map<String, dynamic>>[].obs;");
        extraMethods.addAll([
          "  void add${capitalLabel}Row() {",
          "    ${name}Rows.add({});",
          "    // TODO: show dialog to fill row fields",
          "  }",
          "",
          "  void edit${capitalLabel}Row(int index) {",
          "    // TODO: show dialog pre-filled with ${name}Rows[index]",
          "  }",
          "",
          "  void delete${capitalLabel}Row(int index) {",
          "    if (index >= 0 && index < ${name}Rows.length) {",
          "      ${name}Rows.removeAt(index);",
          "    }",
          "  }",
          "",
        ]);
        break;

      // ══════════════════════════════════════════════
      //  Repeater
      // ══════════════════════════════════════════════
      case 'repeater':
        buffer.writeln("  final ${name}Items = <dynamic>[].obs;");
        extraMethods.addAll([
          "  void add${capitalLabel}Item() {",
          "    ${name}Items.add({});",
          "    // TODO: populate item with repeater sub-fields",
          "  }",
          "",
          "  void remove${capitalLabel}Item(int index) {",
          "    if (index >= 0 && index < ${name}Items.length) {",
          "      ${name}Items.removeAt(index);",
          "    }",
          "  }",
          "",
        ]);
        break;

      // ══════════════════════════════════════════════
      //  Timeline
      // ══════════════════════════════════════════════
      case 'timeline':
        final timelineList = (item['items'] as List?) ?? (item['componentConfig']?['items'] as List?) ?? staticOpts ?? [];
        final timelineSteps = timelineList.isNotEmpty
            ? timelineList.map((o) {
                if (o is Map) {
                  return "'${(o['title'] ?? o['value'] ?? o['label'] ?? '').toString().replaceAll("'", "\\'")}'";
                }
                return "'${o?.toString().replaceAll("'", "\\'") ?? ''}'";
              }).join(', ')
            : "'Step 1', 'Step 2', 'Step 3'";
        buffer.writeln(
            "  final ${name}Steps = <dynamic>[$timelineSteps].obs;");
        break;

      // ══════════════════════════════════════════════
      //  Autocomplete
      // ══════════════════════════════════════════════
      case 'autocomplete':
        buffer.writeln("  var selected${capitalLabel}Text = ''.obs;");
        if (staticOpts != null && staticOpts.isNotEmpty) {
          final optLiterals = staticOpts.map((o) {
            if (o is Map) {
              final v = (o['value'] ?? o['key'] ?? o['title'] ?? '').toString().replaceAll("'", "\\'");
              return "'$v'";
            }
            return "'${o?.toString().replaceAll("'", "\\'") ?? ''}'";
          }).join(', ');
          buffer.writeln(
              "  final ${name}Options = <String>[$optLiterals];");
        } else {
          buffer.writeln("  final ${name}Options = <String>[];");
        }
        break;

      // ══════════════════════════════════════════════
      //  Signature
      // ══════════════════════════════════════════════
      case 'signature':
        buffer.writeln("  var ${name}Signed = false.obs;");
        buffer.writeln("  var ${name}Data = ''.obs;");
        extraMethods.addAll([
          "  Future<void> capture${capitalLabel}Signature() async {",
          "    // TODO: open signature pad and capture result",
          "    // ${name}Data.value = signatureBytes;",
          "    // ${name}Signed.value = true;",
          "  }",
          "",
        ]);
        break;

      // ══════════════════════════════════════════════
      //  Layout / Static — no state needed
      // ══════════════════════════════════════════════
      case 'label':
      case 'divider':
      case 'section':
      case 'card':
      case 'tabs':
      case 'accordion':
      case 'hidden':
      case 'row':
        break;

      case 'formula':
        buffer.writeln("  var $name = ''.obs; // Calculated formula value");
        break;

      default:
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

  // ─── Extra methods (file pickers, grid ops, etc.) ─────────────
  for (final line in extraMethods) {
    buffer.writeln("  $line");
  }

  // ─── onClose ─────────────────────────────────────────────────
  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  for (final item in flatFields) {
    final rawId = (item['id'] ?? item['fieldId'] ?? item['label'] ?? 'field').toString().trim();
    final name = camelCaseName(rawId);
    final capitalLabel = pascalCaseName(rawId);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();

    switch (type) {
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
      case 'email':
      case 'password':
      case 'number':
      case 'integer':
      case 'int':
      case 'decimal':
      case 'double':
      case 'float':
      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
        buffer.writeln("    ${name}Controller.dispose();");
        break;
      case 'dropdown':
      case 'api_dropdown':
        buffer.writeln("    selected$capitalLabel.value = null;");
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$capitalLabel.value = '';");
        break;
      case 'switch':
      case 'checkbox':
        buffer.writeln("    ${name}Value.value = false;");
        break;
      case 'slider':
      case 'range slider':
      case 'starrating':
      case 'rating':
      case 'star rating':
        buffer.writeln("    ${name}Value.value = 0.0;");
        break;
      case 'file':
      case 'fileupload':
      case 'file upload':
      case 'image':
        buffer.writeln("    ${name}FileName.value = '';");
        buffer.writeln("    ${name}FilePath.value = '';");
        break;
      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        buffer.writeln("    ${name}Selected.clear();");
        break;
      case 'grid':
      case 'table':
      case 'table/grid':
      case 'table grid':
      case 'table_grid':
        buffer.writeln("    ${name}Rows.clear();");
        break;
      case 'repeater':
        buffer.writeln("    ${name}Items.clear();");
        break;
      case 'autocomplete':
        buffer.writeln("    selected${capitalLabel}Text.value = '';");
        break;
      case 'signature':
        buffer.writeln("    ${name}Signed.value = false;");
        buffer.writeln("    ${name}Data.value = '';");
        break;
    }
  }
  buffer.writeln("    super.onClose();");
  buffer.writeln("  }");
  buffer.writeln();

  // ─── clearForm ───────────────────────────────────────────────
  buffer.writeln("  void clearForm() {");
  for (final item in flatFields) {
    final rawId = (item['id'] ?? item['fieldId'] ?? item['label'] ?? 'field').toString().trim();
    final name = camelCaseName(rawId);
    final capitalLabel = pascalCaseName(rawId);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();

    switch (type) {
      case 'text':
      case 'textfield':
      case 'phone':
      case 'textarea':
      case 'otp':
      case 'email':
      case 'password':
      case 'number':
      case 'integer':
      case 'int':
      case 'decimal':
      case 'double':
      case 'float':
      case 'date':
      case 'datetime':
      case 'date time':
      case 'time':
        buffer.writeln("    ${name}Controller.clear();");
        break;
      case 'dropdown':
      case 'api_dropdown':
        buffer.writeln("    selected$capitalLabel.value = null;");
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$capitalLabel.value = '';");
        break;
      case 'switch':
      case 'checkbox':
        buffer.writeln("    ${name}Value.value = false;");
        break;
      case 'slider':
      case 'range slider':
        final minVal = (item['minValue'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln("    ${name}Value.value = $minVal;");
        break;
      case 'starrating':
      case 'rating':
      case 'star rating':
        buffer.writeln("    ${name}Value.value = 0.0;");
        break;
      case 'file':
      case 'fileupload':
      case 'file upload':
      case 'image':
        buffer.writeln("    ${name}FileName.value = '';");
        buffer.writeln("    ${name}FilePath.value = '';");
        break;
      case 'multiselect':
      case 'multi select':
      case 'multi_select':
        buffer.writeln("    ${name}Selected.clear();");
        break;
      case 'grid':
      case 'table':
      case 'table/grid':
      case 'table grid':
      case 'table_grid':
        buffer.writeln("    ${name}Rows.clear();");
        break;
      case 'repeater':
        buffer.writeln("    ${name}Items.clear();");
        break;
      case 'autocomplete':
        buffer.writeln("    selected${capitalLabel}Text.value = '';");
        break;
      case 'signature':
        buffer.writeln("    ${name}Signed.value = false;");
        buffer.writeln("    ${name}Data.value = '';");
        break;
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
