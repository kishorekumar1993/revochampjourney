import 'package:revojourneytryone/filegegnerator/journey_step_codegen.dart';
import 'package:revojourneytryone/getx/getx_model_naming.dart';

String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName, {
  Map<String, dynamic>? stepJson,
}) {
  final buffer = StringBuffer();
  final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});

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
    if (source is! Map) return;

    final map = Map<String, dynamic>.from(source);
    if (map.containsKey('steps')) {
      flattenFields(map['steps'], result);
      return;
    }
    if (map.containsKey('fields')) {
      flattenFields(map['fields'], result);
      return;
    }
    if (map.containsKey('type')) {
      result.add(map);
      flattenFields(map['nestedFields'], result);
      final config = map['componentConfig'];
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

  // -------------------------------------------------------------------
  // Imports
  // -------------------------------------------------------------------
  final hasRadio = flatFields.any(
    (f) => (f['type'] ?? '').toString().toLowerCase().startsWith('radio'),
  );
  buffer.writeln("import 'dart:convert';");
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import 'package:http/http.dart' as http;");
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
    if (!fieldNeedsGetxModel(field)) continue;
    final modelFile = resolveGetxModelFileBase(field);
    if (emittedModelFiles.add(modelFile)) {
      buffer.writeln("import '${getxModelImportPath(modelFile)}';");
    }
  }

  buffer.writeln();
  buffer.writeln("class ${className}Controller extends GetxController {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln("  ${className}Controller(this.repository);");
  buffer.writeln();
  buffer.writeln("  final isLoading = false.obs;");
  buffer.writeln("  final isExecuting = false.obs;");
  buffer.writeln();
  stepMeta.writeStepConstants(buffer);
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
        final dropdownmodel = resolveGetxModelClassName(item);

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
  buffer.writeln();

  // ── Journey step execution (from JSON: apiCalls, actions, nextStep) ──
  buffer.writeln('  dynamic _formValue(String fieldId) {');
  buffer.writeln('    // Map field values from controllers / observables');
  for (final item in flatFields) {
    final name = getFieldName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    if (type == 'text' ||
        type == 'textfield' ||
        type == 'phone' ||
        type == 'textarea' ||
        type == 'otp' ||
        type == 'email' ||
        type == 'password' ||
        type == 'number' ||
        type == 'date' ||
        type == 'time') {
      buffer.writeln("    if (fieldId == '${item['id']}') return ${name}Controller.text;");
    } else if (type == 'radio' || type == 'dropdown') {
      final pascal = getPascalName(item);
      buffer.writeln("    if (fieldId == '${item['id']}') return selected$pascal.value?.toString();");
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("    if (fieldId == '${item['id']}') return ${name}Value.value.toString();");
    }
  }
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln();

  _writeGetxValidation(buffer, stepMeta, flatFields, getFieldName);
  JourneyStepCodegen.writeHttpHelper(buffer);
  stepMeta.writeApiExecutionMethods(buffer);
  buffer.writeln();
  buffer.writeln('  Future<void> onPrimaryAction() async {');
  buffer.writeln('    if (isExecuting.value) return;');
  buffer.writeln('    isExecuting.value = true;');
  buffer.writeln('    try {');
  buffer.writeln('      if (!validateStep()) return;');
  buffer.writeln("      await executeStepApis(trigger: '${stepMeta.hasNextStep ? 'onNext' : 'onSubmit'}');");
  stepMeta.writeNavigateNextGetX(buffer, indent: '      ');
  buffer.writeln('    } catch (e) {');
  buffer.writeln("      Get.snackbar('Error', e.toString());");
  buffer.writeln('    } finally {');
  buffer.writeln('      isExecuting.value = false;');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln("}");

  return buffer.toString();
}

void _writeGetxValidation(
  StringBuffer buffer,
  JourneyStepCodegen stepMeta,
  List<Map<String, dynamic>> flatFields,
  String Function(Map<String, dynamic>) getFieldName,
) {
  buffer.writeln('  bool validateStep() {');
  if (!stepMeta.hasValidations) {
    buffer.writeln('    return true;');
    buffer.writeln('  }');
    return;
  }
  for (final v in stepMeta.validations) {
    final type = v['type']?.toString() ?? 'required';
    final field = v['field']?.toString() ?? '';
    final message = v['message']?.toString().replaceAll("'", "\\'") ?? 'Required';
    if (type == 'required' && field.isNotEmpty) {
      buffer.writeln('    final v = _formValue(\'$field\');');
      buffer.writeln('    if (v == null || v.toString().trim().isEmpty) {');
      buffer.writeln("      Get.snackbar('Validation', '$message');");
      buffer.writeln('      return false;');
      buffer.writeln('    }');
    }
  }
  buffer.writeln('    return true;');
  buffer.writeln('  }');
  buffer.writeln();
}
