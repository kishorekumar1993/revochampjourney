String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

  // -------------------------------------------------------------------
  // Helper to recursively flatten all fields
  // -------------------------------------------------------------------
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) {
        flattenFields(item, result);
      }
      return;
    }
    if (source is! Map<String, dynamic>) return;

    if (source.containsKey('steps')) {
      flattenFields(source['steps'], result);
      return;
    }
    if (source.containsKey('fields')) {
      flattenFields(source['fields'], result);
      return;
    }
    if (source.containsKey('type')) {
      result.add(source);
      flattenFields(source['nestedFields'], result);
      final config = source['componentConfig'];
      if (config is Map) {
        flattenFields(config['fields'], result);
        flattenFields(config['columns'], result);
      }
    }
  }

  final flatFields = <Map<String, dynamic>>[];
  flattenFields(configList, flatFields);

  // -------------------------------------------------------------------
  // Name helpers
  // -------------------------------------------------------------------
  String getFieldName(Map<String, dynamic> field) {
    final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
        .toString()
        .trim();
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String getPascalName(Map<String, dynamic> field) {
    final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
        .toString()
        .trim();
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return n.isEmpty ? 'Field' : n[0].toUpperCase() + n.substring(1);
  }

  String capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String singularize(String text) {
    if (text.endsWith('ies')) {
      return '${text.substring(0, text.length - 3)}y';
    }
    if (text.endsWith('s') && text.length > 1) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  // ✅ FIX 1: Resolve model class WITHOUT appending "Model"
  // The dropdown items are the inner classes (e.g., Post, User), not the wrapper.
  String resolveModelClass(Map<String, dynamic> field) {
    final dropdowndata = field['dropdowndata'];
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
          final singular = singularize(entry.key);
          return capitalize(singular); // e.g. "recipes" → "Recipe"
        }
      }
    }
    // Fallback: label‑based
    final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
        .toString()
        .trim();
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return capitalize(n);
  }

  // e.g. "Recipe" → "recipe"  (for import file name)
  String modelClassToFileName(String modelClass) {
    // Model class is now just "Recipe", not "RecipeModel"
    final snake = modelClass.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
    return snake.startsWith('_') ? snake.substring(1) : snake;
  }

  // ✅ FIX 2: Repository method pattern changed to get<PascalName>Options
  // No longer needed for the method name itself, but keep the function if used elsewhere.
  bool needsS(String name) => !name.toLowerCase().endsWith('s');

  // -------------------------------------------------------------------
  // Imports
  // -------------------------------------------------------------------
  final hasRadio = flatFields.any(
    (f) => (f['type'] ?? '').toString().toLowerCase().startsWith('radio'),
  );
  final hasDropdown = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t == 'dropdown' || t == 'api_dropdown';
  });

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase().replaceAll(' ', '_')}_repository.dart';",
  );
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");

  // ✅ FIX 3: Remove the import of common_dropdown_search.dart from the controller.
  // That widget is only needed in the view, not in the controller.
  // The following three lines are DELETED:
  // if (hasDropdown) {
  //   buffer.writeln("import '/widget/common_dropdown_search.dart';");
  // }

  // Collect model imports for API dropdowns
  final emittedModelFiles = <String>{};
  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if ((!useStatic && hasApiUrl) ||
          (!useStatic && (staticOpts == null || staticOpts.isEmpty))) {
        final modelClass = resolveModelClass(field); // e.g. "Post"
        final modelFile = modelClassToFileName(modelClass); // e.g. "post"
        if (emittedModelFiles.add(modelFile)) {
          buffer.writeln("import '../model/${modelFile}_model.dart';");
        }
      }
    }
  }

  buffer.writeln();
  buffer.writeln("class ${className}Controller extends GetxController {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln("  ${className}Controller(this.repository);");
  buffer.writeln();
  buffer.writeln("  final isLoading = false.obs;");
  buffer.writeln();

  final dropdownInitCalls = <String>[];
  final extraMethods = <String>[];

  // -------------------------------------------------------------------
  // Field declarations
  // -------------------------------------------------------------------
  for (final item in flatFields) {
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    final useStatic = item['useStaticOptions'] == true;
    final staticOpts =
        (item['options'] as List<dynamic>?) ??
        (item['staticOptions'] as List<dynamic>?);
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        item['dropdownApiUrl'] != null;

    // ---------- Text based ----------
    if (type == 'text' ||
        type == 'textfield' ||
        type == 'phone' ||
        type == 'textarea' ||
        type == 'otp' ||
        type == 'email' ||
        type == 'password' ||
        type == 'number' ||
        type == 'integer' ||
        type == 'int' ||
        type == 'decimal' ||
        type == 'double' ||
        type == 'float' ||
        type == 'date' ||
        type == 'datetime' ||
        type == 'date time' ||
        type == 'time') {
      buffer.writeln("  final ${name}Controller = TextEditingController();");

      // ---------- Dropdown ----------
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (!isApiDropdown && staticOpts != null && staticOpts.isNotEmpty) {
        // Static dropdown
        final literals = staticOpts
            .map((o) {
              if (o is Map) {
                final k = (o['key'] ?? o['value'] ?? o['id'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                final v = (o['value'] ?? o['label'] ?? o['title'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                return "DropdownItem(key: '$k', value: '$v')";
              }
              final val = o?.toString().replaceAll("'", "\\'") ?? '';
              return "DropdownItem(key: '$val', value: '$val')";
            })
            .join(', ');
        buffer.writeln("  var selected$pascalName = Rxn<DropdownItem>();");
        buffer.writeln(
          "  final ${name}Options = <DropdownItem>[$literals].obs;",
        );
      } else if (isApiDropdown) {
        // Dynamic dropdown – uses inner model class
        final dropdownmodel = resolveModelClass(item);

        buffer.writeln("  var ${name}Options = <$dropdownmodel>[].obs;");
        buffer.writeln("  var selected$pascalName = Rxn<$dropdownmodel>();");
        buffer.writeln("  var isLoading$pascalName = false.obs;");

        // ✅ FIX 2: Repository method changed to "get{pascalName}Options"
        final repoMethod = 'get${pascalName}Options';
        dropdownInitCalls.add("    load${pascalName}Options(),");
        extraMethods.addAll([
          "  Future<void> load${pascalName}Options() async {",
          "    if (isLoading$pascalName.value) return;",
          "    isLoading$pascalName.value = true;",
          "    try {",
          "      final data = await repository.$repoMethod();",
          "      // Defer assignment to avoid didUpdateWidget during build",
          "      SchedulerBinding.instance.addPostFrameCallback((_) {",
          "        ${name}Options.value = data.map((json) => $dropdownmodel.fromJson(json)).toList();",
          "      });",
          "    } catch (e) {",
          "      Get.snackbar('Error', 'Could not load $pascalName: \$e');",
          "    } finally {",
          "      isLoading$pascalName.value = false;",
          "    }",
          "  }",
          "",
        ]);
      }

      // ---------- Radio ----------
    } else if (type == 'radio' || type == 'radio buttons') {
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final formattedOptions = staticOpts
            .map((o) {
              if (o is Map) {
                final k = (o['key'] ?? o['value'] ?? o['id'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                final v = (o['value'] ?? o['label'] ?? o['title'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                return "RadioOption<String>(value: '$k', label: '$v')";
              }
              final val = o?.toString().replaceAll("'", "\\'") ?? '';
              return "RadioOption<String>(value: '$val', label: '$val')";
            })
            .join(', ');
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln(
          "  final ${name}Options = <RadioOption<String>>[$formattedOptions];",
        );
      } else {
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln("  final ${name}Options = <RadioOption<String>>[];");
      }

      // ---------- Switch ----------
    } else if (type == 'switch') {
      final defaultValue =
          (item['defaultValue'] ?? 'false').toString().toLowerCase() == 'true';
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");

      // ---------- Checkbox ----------
    } else if (type == 'checkbox') {
      final defaultValue =
          (item['defaultValue'] ?? 'false').toString().toLowerCase() == 'true';
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");

      // ---------- File / Image ----------
    } else if (type == 'file' ||
        type == 'fileupload' ||
        type == 'file upload' ||
        type == 'image') {
      buffer.writeln("  var ${name}FileName = ''.obs;");
      buffer.writeln("  var ${name}FilePath = ''.obs;");
      extraMethods.addAll([
        "  Future<void> pick$pascalName() async {",
        "    // TODO: integrate file_picker or image_picker",
        "  }",
        "",
      ]);

      // ---------- Multi-select ----------
    } else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
      buffer.writeln("  final ${name}Selected = <String>[].obs;");
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optLiterals = staticOpts
            .map((o) {
              if (o is Map) {
                final v = (o['value'] ?? o['key'] ?? o['title'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                return "'$v'";
              }
              return "'${o?.toString().replaceAll("'", "\\'") ?? ''}'";
            })
            .join(', ');
        buffer.writeln("  final ${name}Options = <String>[$optLiterals];");
      } else {
        buffer.writeln("  final ${name}Options = <String>[];");
      }

      // ---------- Slider ----------
    } else if (type == 'slider' || type == 'range slider') {
      final defaultValue =
          (item['defaultValue'] as num?)?.toDouble() ??
          (item['minValue'] as num?)?.toDouble() ??
          0.0;
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");

      // ---------- Star Rating ----------
    } else if (type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("  var ${name}Value = 0.0.obs;");

      // ---------- Grid / Table ----------
    } else if (type == 'grid' ||
        type == 'table' ||
        type == 'table/grid' ||
        type == 'table grid' ||
        type == 'table_grid') {
      buffer.writeln("  final ${name}Rows = <Map<String, dynamic>>[].obs;");
      extraMethods.addAll([
        "  void add${pascalName}Row() { ${name}Rows.add({}); }",
        "  void update${pascalName}Cell(int index, String key, dynamic value) {",
        "    if (index >= 0 && index < ${name}Rows.length) {",
        "      final row = Map<String, dynamic>.from(${name}Rows[index]);",
        "      row[key] = value;",
        "      ${name}Rows[index] = row;",
        "    }",
        "  }",
        "  void delete${pascalName}Row(int index) {",
        "    if (index >= 0 && index < ${name}Rows.length) ${name}Rows.removeAt(index);",
        "  }",
        "",
      ]);

      // ---------- Repeater ----------
    } else if (type == 'repeater') {
      buffer.writeln("  final ${name}Items = <dynamic>[].obs;");
      extraMethods.addAll([
        "  void add${pascalName}Item() { ${name}Items.add({}); }",
        "  void remove${pascalName}Item(int index) {",
        "    if (index >= 0 && index < ${name}Items.length) ${name}Items.removeAt(index);",
        "  }",
        "",
      ]);

      // ---------- Autocomplete ----------
    } else if (type == 'autocomplete') {
      buffer.writeln("  var selected${pascalName}Text = ''.obs;");
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optLiterals = staticOpts
            .map((o) {
              if (o is Map) {
                final v = (o['value'] ?? o['key'] ?? o['title'] ?? '')
                    .toString()
                    .replaceAll("'", "\\'");
                return "'$v'";
              }
              return "'${o?.toString().replaceAll("'", "\\'") ?? ''}'";
            })
            .join(', ');
        buffer.writeln("  final ${name}Options = <String>[$optLiterals];");
      } else {
        buffer.writeln("  final ${name}Options = <String>[];");
      }

      // ---------- Signature ----------
    } else if (type == 'signature') {
      buffer.writeln("  var ${name}Signed = false.obs;");
      buffer.writeln("  var ${name}Data = ''.obs;");
      extraMethods.addAll([
        "  Future<void> capture${pascalName}Signature() async {",
        "    // TODO: open signature pad",
        "  }",
        "",
      ]);

      // ---------- Formula ----------
    } else if (type == 'formula') {
      buffer.writeln("  var $name = ''.obs;");

      // ---------- Layout — no state ----------
    } else if ([
      'label',
      'divider',
      'section',
      'card',
      'tabs',
      'accordion',
      'hidden',
      'row',
    ].contains(type)) {
      // intentionally empty

      // ---------- Default fallback ----------
    } else {
      buffer.writeln("  var $name = ''.obs;");
    }
  }

  // -------------------------------------------------------------------
  // onInit
  // -------------------------------------------------------------------
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("    _loadAllDropdowns();");
  }
  buffer.writeln("  }");
  buffer.writeln();

  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("  Future<void> _loadAllDropdowns() async {");
    buffer.writeln("    isLoading.value = true;");
    buffer.writeln("    try {");
    buffer.writeln("      await Future.wait([");
    for (final call in dropdownInitCalls) {
      buffer.writeln("        $call");
    }
    buffer.writeln("      ]);");
    buffer.writeln("    } catch (e) {");
    buffer.writeln("      debugPrint('Error loading dropdowns: \$e');");
    buffer.writeln("    } finally {");
    buffer.writeln("      isLoading.value = false;");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  for (final line in extraMethods) {
    buffer.writeln("  $line");
  }

  // -------------------------------------------------------------------
  // onClose
  // -------------------------------------------------------------------
  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    final useStatic = item['useStaticOptions'] == true;
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        item['dropdownApiUrl'] != null;

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
        if (isApiDropdown) {
          buffer.writeln("    selected$pascalName.value = null;");
          buffer.writeln("    ${name}Options.clear();");
        } else {
          buffer.writeln("    selected$pascalName.value = null;");
        }
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$pascalName.value = '';");
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
        buffer.writeln("    selected${pascalName}Text.value = '';");
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

  // -------------------------------------------------------------------
  // clearForm
  // -------------------------------------------------------------------
  buffer.writeln("  void clearForm() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    final useStatic = item['useStaticOptions'] == true;
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        item['dropdownApiUrl'] != null;

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
        buffer.writeln("    selected$pascalName.value = null;");
        break;
      case 'radio':
      case 'radio buttons':
        buffer.writeln("    selected$pascalName.value = '';");
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
        buffer.writeln("    selected${pascalName}Text.value = '';");
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
