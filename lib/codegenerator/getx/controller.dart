// ignore_for_file: constant_identifier_names
import 'package:revojourneytryone/codegenerator/filegegnerator/journey_step_codegen.dart';

// ============================================================================
// Helper functions for model resolution
// ============================================================================

bool fieldNeedsGetxModel(Map<String, dynamic> field) {
  final type = (field['type'] ?? '').toString().toLowerCase();
  final useStatic = field['useStaticOptions'] == true;
  final hasApiUrl = field['dropdownApiUrl'] != null;
  return (type == 'dropdown' || type == 'api_dropdown') &&
      !useStatic &&
      hasApiUrl;
}

String resolveGetxModelFileBase(Map<String, dynamic> field) {
  final apiUrl = field['dropdownApiUrl']?.toString() ?? '';
  final segments = apiUrl.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isNotEmpty) {
    final last = segments.last;
    final base = last.split('?').first;
    if (base.isNotEmpty && !base.contains('.')) return '${base}_model';
  }
  final label = (field['label'] ?? field['id'] ?? 'model')
      .toString()
      .toLowerCase();
  return '${label.replaceAll(RegExp(r'\s+'), '_')}_model';
}

String getxModelImportPath(String modelFileBase) =>
    '../model/${modelFileBase}.dart';

String resolveGetxModelClassName(Map<String, dynamic> field) {
  final base = resolveGetxModelFileBase(field);
  final parts = base.split('_');
  final className = parts
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join();
  return className.endsWith('Model') ? className : '${className}Model';
}

String _buildStaticDropdownOptions(List<dynamic> options) {
  final items = options
      .map((o) {
        if (o is Map) {
          final key = (o['key'] ?? o['value'] ?? o['id'] ?? '')
              .toString()
              .replaceAll("'", "\\'");
          final value = (o['value'] ?? o['label'] ?? o['title'] ?? '')
              .toString()
              .replaceAll("'", "\\'");
          return "DropdownItem(key: '$key', value: '$value')";
        }
        final val = o.toString().replaceAll("'", "\\'");
        return "DropdownItem(key: '$val', value: '$val')";
      })
      .join(', ');
  return '<DropdownItem>[$items]';
}

String _buildStaticRadioOptions(List<dynamic> options) {
  final items = options
      .map((o) {
        if (o is Map) {
          final key = (o['key'] ?? o['value'] ?? o['id'] ?? '')
              .toString()
              .replaceAll("'", "\\'");
          final label = (o['value'] ?? o['label'] ?? o['title'] ?? '')
              .toString()
              .replaceAll("'", "\\'");
          return "RadioOption<String>(value: '$key', label: '$label')";
        }
        final val = o.toString().replaceAll("'", "\\'");
        return "RadioOption<String>(value: '$val', label: '$val')";
      })
      .join(', ');
  return '<RadioOption<String>>[$items]';
}

// ============================================================================
// Main generator function – FULLY IMPROVED
// ============================================================================

String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName, {
  Map<String, dynamic>? stepJson,
}) {
  final buffer = StringBuffer();
  final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});

  // -------------------------------------------------------------------------
  // Flatten fields (including nested inside cards, etc.)
  // -------------------------------------------------------------------------
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) flattenFields(item, result);
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

  // -------------------------------------------------------------------------
  // Name helpers
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Determine which imports are actually needed
  // -------------------------------------------------------------------------
  final hasRadio = flatFields.any(
    (f) => (f['type'] ?? '').toString().toLowerCase().startsWith('radio'),
  );
  final hasDropdown = flatFields.any(
    (f) =>
        (f['type'] ?? '').toString().toLowerCase() == 'dropdown' ||
        (f['type'] ?? '').toString().toLowerCase() == 'api_dropdown',
  );
  final hasFile = flatFields.any(
    (f) =>
        (f['type'] ?? '').toString().toLowerCase() == 'file' ||
        (f['type'] ?? '').toString().toLowerCase() == 'image',
  );
  final hasGrid = flatFields.any(
    (f) =>
        (f['type'] ?? '').toString().toLowerCase().contains('grid') ||
        (f['type'] ?? '').toString().toLowerCase().contains('table'),
  );

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:flutter/scheduler.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import '/getx/validation_engine.dart';");
  buffer.writeln("import '/getx/api_executor.dart';");
  buffer.writeln("import '/getx/worker_manager.dart';");
  buffer.writeln("import '/getx/message_service.dart';");
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  if (hasDropdown) buffer.writeln("import '/widget/common_dropdown.dart';");
  if (hasFile) buffer.writeln("import 'dart:io';");
  if (hasGrid) buffer.writeln("import '/widget/common_grid.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase().replaceAll(' ', '_')}_repository.dart';",
  );

  // Model imports for API dropdowns
  final emittedModelFiles = <String>{};
  for (final field in flatFields) {
    if (!fieldNeedsGetxModel(field)) continue;
    final modelFile = resolveGetxModelFileBase(field);
    if (emittedModelFiles.add(modelFile)) {
      buffer.writeln("import '${getxModelImportPath(modelFile)}';");
    }
  }

  // -------------------------------------------------------------------------
  // Enums and controller class
  // -------------------------------------------------------------------------
  buffer.writeln();
  buffer.writeln(
    "// -----------------------------------------------------------------",
  );
  buffer.writeln("// API trigger enum (replaces raw strings)");
  buffer.writeln(
    "// -----------------------------------------------------------------",
  );
  buffer.writeln("enum ApiTrigger { onNext, onSubmit, onLoad }");
  buffer.writeln();

  buffer.writeln("class ${className}Controller extends GetxController {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln(
    "  ${className}Controller({${className}Repository? repository}) : repository = repository ?? Get.find<${className}Repository>();",
  );
  buffer.writeln();
  buffer.writeln("  final isLoading = false.obs;");
  buffer.writeln("  final isExecuting = false.obs;");
  buffer.writeln("  final isDirty = false.obs;");
  buffer.writeln("  final WorkerManager _workerManager = WorkerManager();");
  buffer.writeln("  final fieldErrors = <String, Rx<String>>{};");
  buffer.writeln("  final fieldVisibility = <String, RxBool>{};");
  buffer.writeln("  Map<String, dynamic>? routeArgs;");
  buffer.writeln();
  buffer.writeln("  // Message stream for UI (replaces Get.snackbar)");
  buffer.writeln(
    "  final _messageController = StreamController<MessageEvent>.broadcast();",
  );
  buffer.writeln(
    "  Stream<MessageEvent> get messageStream => _messageController.stream;",
  );
  buffer.writeln();

  stepMeta.writeStepConstants(buffer);
  buffer.writeln();

  // -------------------------------------------------------------------------
  // Field ID constants – no more hardcoded strings
  // -------------------------------------------------------------------------
  buffer.writeln("  // Field ID constants – use these instead of raw strings");
  for (final field in flatFields) {
    final id = field['id']?.toString();
    if (id != null && id.isNotEmpty) {
      final constName = 'kField${getPascalName(field)}';
      buffer.writeln("  static const String $constName = '$id';");
    }
  }
  buffer.writeln();

  final dropdownInitCalls = <String>[];
  final extraMethods = <String>[];

  // -------------------------------------------------------------------------
  // Generate field declarations (only necessary types)
  // -------------------------------------------------------------------------
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

    // Text fields
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
    }
    // Dropdowns
    else if (type == 'dropdown' || type == 'api_dropdown') {
      if (!isApiDropdown && staticOpts != null && staticOpts.isNotEmpty) {
        final itemsLiteral = _buildStaticDropdownOptions(staticOpts);
        buffer.writeln("  var selected$pascalName = Rxn<DropdownItem>();");
        buffer.writeln("  final ${name}Options = $itemsLiteral.obs;");
      } else if (isApiDropdown) {
        final modelClass = resolveGetxModelClassName(item);
        buffer.writeln("  var ${name}Options = <$modelClass>[].obs;");
        buffer.writeln("  var selected$pascalName = Rxn<$modelClass>();");
        buffer.writeln("  var isLoading$pascalName = false.obs;");
        final repoMethod = 'get${pascalName}Options';
        dropdownInitCalls.add("    load${pascalName}Options(),");
        extraMethods.addAll([
          "  Future<void> load${pascalName}Options() async {",
          "    if (isLoading$pascalName.value) return;",
          "    isLoading$pascalName.value = true;",
          "    try {",
          "      final data = await repository.$repoMethod();",
          "      SchedulerBinding.instance.addPostFrameCallback((_) {",
          "        ${name}Options.value = data.map((json) => $modelClass.fromJson(json)).toList();",
          "      });",
          "    } catch (e) {",
          "      _showError('Could not load $pascalName: \$e');",
          "    } finally {",
          "      isLoading$pascalName.value = false;",
          "    }",
          "  }",
          "",
        ]);
      } else {
        buffer.writeln("  var selected$pascalName = Rxn<DropdownItem>();");
        buffer.writeln("  final ${name}Options = <DropdownItem>[].obs;");
      }
    }
    // Radio
    else if (type == 'radio' || type == 'radio buttons') {
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optionsLiteral = _buildStaticRadioOptions(staticOpts);
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln("  final ${name}Options = $optionsLiteral;");
      } else {
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln("  final ${name}Options = <RadioOption<String>>[];");
      }
    }
    // Switch
    else if (type == 'switch') {
      final defaultValue =
          (item['defaultValue'] ?? 'false').toString().toLowerCase() == 'true';
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");
    }
    // Checkbox
    else if (type == 'checkbox') {
      final defaultValue =
          (item['defaultValue'] ?? 'false').toString().toLowerCase() == 'true';
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");
    }
    // File / Image
    else if (type == 'file' ||
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
    }
    // MultiSelect
    else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
      buffer.writeln("  final ${name}Selected = <String>[].obs;");
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optLiterals = staticOpts
            .map((o) {
              final v = o is Map
                  ? (o['value'] ?? o['key'] ?? o['title'] ?? '').toString()
                  : o.toString();
              return "'${v.replaceAll("'", "\\'")}'";
            })
            .join(', ');
        buffer.writeln("  final ${name}Options = <String>[$optLiterals];");
      } else {
        buffer.writeln("  final ${name}Options = <String>[];");
      }
    }
    // Slider
    else if (type == 'slider' || type == 'range slider') {
      final defaultValue =
          (item['defaultValue'] as num?)?.toDouble() ??
          (item['minValue'] as num?)?.toDouble() ??
          0.0;
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");
    }
    // Star Rating
    else if (type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("  var ${name}Value = 0.0.obs;");
    }
    // Grid / Table
    else if (type == 'grid' ||
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
    }
    // Repeater
    else if (type == 'repeater') {
      buffer.writeln("  final ${name}Items = <dynamic>[].obs;");
      extraMethods.addAll([
        "  void add${pascalName}Item() { ${name}Items.add({}); }",
        "  void remove${pascalName}Item(int index) {",
        "    if (index >= 0 && index < ${name}Items.length) ${name}Items.removeAt(index);",
        "  }",
        "",
      ]);
    }
    // Autocomplete
    else if (type == 'autocomplete') {
      buffer.writeln("  var selected${pascalName}Text = ''.obs;");
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optLiterals = staticOpts
            .map((o) {
              final v = o is Map
                  ? (o['value'] ?? o['key'] ?? o['title'] ?? '').toString()
                  : o.toString();
              return "'${v.replaceAll("'", "\\'")}'";
            })
            .join(', ');
        buffer.writeln("  final ${name}Options = <String>[$optLiterals];");
      } else {
        buffer.writeln("  final ${name}Options = <String>[];");
      }
    }
    // Signature
    else if (type == 'signature') {
      buffer.writeln("  var ${name}Signed = false.obs;");
      buffer.writeln("  var ${name}Data = ''.obs;");
      extraMethods.addAll([
        "  Future<void> capture${pascalName}Signature() async {",
        "    // TODO: open signature pad",
        "  }",
        "",
      ]);
    }
    // Formula
    else if (type == 'formula') {
      buffer.writeln("  var $name = ''.obs;");
    }
    // Layout components (no state)
    else if ([
      'label',
      'divider',
      'section',
      'card',
      'tabs',
      'accordion',
      'hidden',
      'row',
    ].contains(type)) {
      // Intentionally empty
    }
    // Fallback
    else {
      buffer.writeln("  var $name = ''.obs;");
    }
  }

  // -------------------------------------------------------------------------
  // onInit and _loadAllDropdowns
  // -------------------------------------------------------------------------
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  if (dropdownInitCalls.isNotEmpty) buffer.writeln("    _loadAllDropdowns();");
  buffer.writeln("  }");
  buffer.writeln();

  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("  Future<void> _loadAllDropdowns() async {");
    buffer.writeln("    isLoading.value = true;");
    buffer.writeln("    try {");
    buffer.writeln("      await Future.wait([");
    for (final call in dropdownInitCalls) buffer.writeln("        $call");
    buffer.writeln("      ]);");
    buffer.writeln("    } catch (e) {");
    buffer.writeln("      _showError('Error loading dropdowns: \$e');");
    buffer.writeln("    } finally {");
    buffer.writeln("      isLoading.value = false;");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  for (final line in extraMethods) buffer.writeln("  $line");

  // -------------------------------------------------------------------------
  // Message helpers (no Get.snackbar in controller)
  // -------------------------------------------------------------------------
  buffer.writeln("  void _showSuccess(String message) {");
  buffer.writeln("    _messageController.add(MessageEvent.success(message));");
  buffer.writeln("  }");
  buffer.writeln();
  buffer.writeln("  void _showError(String message) {");
  buffer.writeln("    _messageController.add(MessageEvent.error(message));");
  buffer.writeln("  }");
  buffer.writeln();

  // -------------------------------------------------------------------------
  // onClose – dispose all resources
  // -------------------------------------------------------------------------
  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    if (type == 'text' ||
        type == 'textfield' ||
        type == 'email' ||
        type == 'password') {
      buffer.writeln("    ${name}Controller.dispose();");
    }
  }
  buffer.writeln("    _workerManager.dispose();");
  buffer.writeln("    _messageController.close();");
  buffer.writeln("    super.onClose();");
  buffer.writeln("  }");
  buffer.writeln();

  // -------------------------------------------------------------------------
  // clearForm – reset all fields
  // -------------------------------------------------------------------------
  buffer.writeln("  void clearForm() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    if (type == 'text' || type == 'textfield') {
      buffer.writeln("    ${name}Controller.clear();");
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      buffer.writeln("    selected$pascalName.value = null;");
    } else if (type == 'radio') {
      buffer.writeln("    selected$pascalName.value = '';");
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("    ${name}Value.value = false;");
    } else if (type == 'slider' || type == 'range slider') {
      buffer.writeln("    ${name}Value.value = 0.0;");
    } else if (type == 'multiselect' || type == 'multi select') {
      buffer.writeln("    ${name}Selected.clear();");
    } else if (type == 'grid' || type == 'table') {
      buffer.writeln("    ${name}Rows.clear();");
    } else if (type == 'repeater') {
      buffer.writeln("    ${name}Items.clear();");
    } else if (type == 'autocomplete') {
      buffer.writeln("    selected${pascalName}Text.value = '';");
    } else if (type == 'signature') {
      buffer.writeln("    ${name}Signed.value = false;");
      buffer.writeln("    ${name}Data.value = '';");
    }
  }
  buffer.writeln("  }");
  buffer.writeln();

  // -------------------------------------------------------------------------
  // _formValue – retrieve current value by field ID
  // -------------------------------------------------------------------------
  buffer.writeln('  dynamic _formValue(String fieldId) {');
  for (final item in flatFields) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase();
    final useStatic = item['useStaticOptions'] == true;
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        item['dropdownApiUrl'] != null;

    if (type == 'text' ||
        type == 'textfield' ||
        type == 'email' ||
        type == 'password') {
      buffer.writeln(
        "    if (fieldId == '$id') return ${name}Controller.text;",
      );
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (isApiDropdown) {
        buffer.writeln(
          "    if (fieldId == '$id') return selected$pascalName.value?.id;",
        );
      } else {
        buffer.writeln(
          "    if (fieldId == '$id') return selected$pascalName.value?.key;",
        );
      }
    } else if (type == 'radio') {
      buffer.writeln(
        "    if (fieldId == '$id') return selected$pascalName.value;",
      );
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Value.value;");
    } else if (type == 'slider' ||
        type == 'range slider' ||
        type == 'starrating' ||
        type == 'rating') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Value.value;");
    } else if (type == 'multiselect' || type == 'multi select') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Selected;");
    } else if (type == 'autocomplete') {
      buffer.writeln(
        "    if (fieldId == '$id') return selected${pascalName}Text.value;",
      );
    } else if (type == 'signature') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Data.value;");
    } else if (type == 'formula') {
      buffer.writeln("    if (fieldId == '$id') return $name.value;");
    }
  }
  buffer.writeln('    return null;');
  buffer.writeln('  }');
  buffer.writeln();

  // -------------------------------------------------------------------------
  // DTO serialization (toJson)
  // -------------------------------------------------------------------------
  buffer.writeln('  Map<String, dynamic> toJson() {');
  buffer.writeln('    return {');
  for (final item in flatFields) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final name = getFieldName(item);
    final type = (item['type'] ?? '').toString().toLowerCase();
    if (type == 'text' ||
        type == 'textfield' ||
        type == 'email' ||
        type == 'password') {
      buffer.writeln("      '$id': ${name}Controller.text,");
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      final pascalName = getPascalName(item);
      buffer.writeln("      '$id': selected$pascalName.value?.id,");
    } else if (type == 'radio') {
      final pascalName = getPascalName(item);
      buffer.writeln("      '$id': selected$pascalName.value,");
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("      '$id': ${name}Value.value,");
    } else if (type == 'slider' ||
        type == 'range slider' ||
        type == 'starrating' ||
        type == 'rating') {
      buffer.writeln("      '$id': ${name}Value.value,");
    } else if (type == 'multiselect' || type == 'multi select') {
      buffer.writeln("      '$id': ${name}Selected.toList(),");
    } else if (type == 'autocomplete') {
      buffer.writeln("      '$id': selected${getPascalName(item)}Text.value,");
    } else if (type == 'signature') {
      buffer.writeln("      '$id': ${name}Data.value,");
    } else if (type == 'formula') {
      buffer.writeln("      '$id': $name.value,");
    }
  }
  buffer.writeln('    };');
  buffer.writeln('  }');
  buffer.writeln();

  // -------------------------------------------------------------------------
  // Validation using ValidationEngine (no manual code)
  // -------------------------------------------------------------------------
  buffer.writeln('  bool validateStep() {');
  if (stepMeta.validations.isEmpty) {
    buffer.writeln('    return true;');
  } else {
    buffer.writeln('    final engine = ValidationEngine();');
    for (final v in stepMeta.validations) {
      final field = v['field']?.toString() ?? '';
      final type = v['type']?.toString() ?? 'required';
      final message =
          v['message']?.toString().replaceAll("'", "\\'") ?? 'Required';
      if (field.isNotEmpty && type == 'required') {
        buffer.writeln("    engine.addRequiredRule('$field', '$message');");
      }
      // Add other validation types (email, minLength, etc.) as needed
    }
    buffer.writeln('    final result = engine.validate(_formValue);');
    buffer.writeln('    for (final entry in result.errors.entries) {');
    buffer.writeln(
      '      fieldErrors[entry.key] = fieldErrors[entry.key] ?? "".obs;',
    );
    buffer.writeln('      fieldErrors[entry.key]!.value = entry.value;');
    buffer.writeln('    }');
    buffer.writeln('    return result.isValid;');
  }
  buffer.writeln('  }');
  buffer.writeln();

  // -------------------------------------------------------------------------
  // API execution with enum trigger
  // -------------------------------------------------------------------------
  buffer.writeln(
    '  Future<void> executeStepApis({ApiTrigger trigger = ApiTrigger.onNext}) async {',
  );
  buffer.writeln('    // Implement API calls defined in step configuration');
  buffer.writeln('    // For each API call, use _runHttpApi');
  buffer.writeln('  }');
  buffer.writeln();
  buffer.writeln('  Future<dynamic> _runHttpApi({');
  buffer.writeln('    required String method,');
  buffer.writeln('    required String url,');
  buffer.writeln('    Map<String, String>? headers,');
  buffer.writeln('    dynamic body,');
  buffer.writeln('  }) async {');
  buffer.writeln('    return ApiExecutor.execute(');
  buffer.writeln('      method: method,');
  buffer.writeln('      url: url,');
  buffer.writeln('      headers: headers,');
  buffer.writeln('      body: body,');
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln();

  // -------------------------------------------------------------------------
  // onPrimaryAction – no snackbar, uses message stream
  // -------------------------------------------------------------------------
  buffer.writeln('  Future<void> onPrimaryAction() async {');
  buffer.writeln('    if (isExecuting.value) return;');
  buffer.writeln('    if (!validateStep()) return;');
  buffer.writeln('    isExecuting.value = true;');
  buffer.writeln('    try {');
  buffer.writeln(
    "      await executeStepApis(trigger: ${stepMeta.hasNextStep ? 'ApiTrigger.onNext' : 'ApiTrigger.onSubmit'});",
  );
  if (stepMeta.nextStep != null && stepMeta.nextStep!.isNotEmpty) {
    buffer.writeln("      Get.toNamed('/journey/${stepMeta.nextStep}');");
  } else {
    buffer.writeln("      _showSuccess('Journey completed.');");
  }
  buffer.writeln('    } catch (e, st) {');
  buffer.writeln("      _showError('Error: \$e');");
  buffer.writeln('    } finally {');
  buffer.writeln('      isExecuting.value = false;');
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln("}");

  return buffer.toString();
}
