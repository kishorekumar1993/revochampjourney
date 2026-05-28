// lib/codegenerator/getx/controller.dart
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
    '../model/$modelFileBase.dart';

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
// Controller generator – uses absolute /getx/ imports (fixed later)
// ============================================================================

String generatecontrollerClass(
  String className,
  List<dynamic> configList,
  String fileName, {
  Map<String, dynamic>? stepJson,
  bool extendBaseController = true,
}) {
  final buffer = StringBuffer();
  final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});

  // Flatten fields
  List<Map<String, dynamic>> flatFields = [];
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

  flattenFields(configList, flatFields);

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

  final hasRadio = flatFields.any(
    (f) => (f['type'] ?? '').toString().toLowerCase().startsWith('radio'),
  );
  final hasDropdown = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t == 'dropdown' || t == 'api_dropdown';
  });
  final hasFile = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t == 'file' ||
        t == 'image' ||
        t == 'fileupload' ||
        t == 'file upload';
  });
  final hasGrid = flatFields.any((f) {
    final t = (f['type'] ?? '').toString().toLowerCase();
    return t.contains('grid') || t.contains('table');
  });

  // Imports – using absolute /getx/ paths (will be fixed later)
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln("import '/getx/getx_exports.dart';");
  if (extendBaseController) {
    buffer.writeln("import '/getx/base_controller.dart';");
  }
  buffer.writeln("import '../../../../core/widgets/widgets.dart';");

  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  // if (hasDropdown)
  // buffer.writeln("import '../../../../core/widgets/widgets.dart';");
  if (hasFile) buffer.writeln("import 'dart:io';");
  if (hasGrid) buffer.writeln("import '/widget/common_grid.dart';");
  buffer.writeln(
    "import '../repository/${fileName.toLowerCase().replaceAll(' ', '_')}_repository.dart';",
  );

  final emittedModelFiles = <String>{};
  for (final field in flatFields) {
    if (!fieldNeedsGetxModel(field)) continue;
    final modelFile = resolveGetxModelFileBase(field);
    if (emittedModelFiles.add(modelFile)) {
      buffer.writeln("import '${getxModelImportPath(modelFile)}';");
    }
  }

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

  final superClass = extendBaseController ? 'BaseController' : 'GetxController';
  buffer.writeln("class ${className}Controller extends $superClass {");
  buffer.writeln("  final ${className}Repository repository;");
  buffer.writeln(
    "  ${className}Controller({${className}Repository? repository})",
  );
  buffer.writeln(
    "      : repository = repository ?? Get.find<${className}Repository>();",
  );
  buffer.writeln();
  buffer.writeln("  final isExecuting = false.obs;");
  buffer.writeln("  final isDirty = false.obs;");
  buffer.writeln("  final WorkerManager _workerManager = WorkerManager();");
  buffer.writeln("  final fieldErrors = <String, String>{}.obs;");
  buffer.writeln("  final fieldVisibility = <String, RxBool>{};");
  buffer.writeln("  Map<String, dynamic>? routeArgs;");
  buffer.writeln();

  // Add formKey
  buffer.writeln("  final formKey = GlobalKey<FormState>();");
  buffer.writeln();

  stepMeta.writeStepConstants(buffer);
  buffer.writeln();

  // Field ID constants
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

  // Field declarations
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

    if ([
      'text',
      'textfield',
      'phone',
      'textarea',
      'otp',
      'email',
      'password',
      'number',
      'integer',
      'int',
      'decimal',
      'double',
      'float',
    ].contains(type)) {
      buffer.writeln("  final ${name}Controller = TextEditingController();");
    } else if (['date', 'datetime', 'date time'].contains(type)) {
      buffer.writeln(
        "  final Rxn<DateTime> ${name}Controller = Rxn<DateTime>();",
      );
    } else if (type == 'time') {
      buffer.writeln(
        "  final Rxn<TimeOfDay> ${name}Controller = Rxn<TimeOfDay>();",
      );
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (!isApiDropdown && staticOpts != null && staticOpts.isNotEmpty) {
        final itemsLiteral = _buildStaticDropdownOptions(staticOpts);
        buffer.writeln("  var selected$pascalName = Rxn<DropdownItem>();");
        buffer.writeln("  final ${name}Options = $itemsLiteral.obs;");
      } else if (isApiDropdown) {
        final modelClass = resolveGetxModelClassName(item);
        buffer.writeln("  var ${name}Options = <$modelClass>[].obs;");
        buffer.writeln("  var selected$pascalName = Rxn<$modelClass>();");
        buffer.writeln("  var isLoading$pascalName = false.obs;");
        dropdownInitCalls.add("    load${pascalName}Options(),");
        extraMethods.addAll([
          "  Future<void> load${pascalName}Options() async {",
          "    if (isLoading$pascalName.value) return;",
          "    isLoading$pascalName.value = true;",
          "    try {",
          "      final data = await repository.get${pascalName}Options();",
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
    } else if (type == 'radio' || type == 'radio buttons') {
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optionsLiteral = _buildStaticRadioOptions(staticOpts);
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln("  final ${name}Options = $optionsLiteral;");
      } else {
        buffer.writeln("  var selected$pascalName = ''.obs;");
        buffer.writeln("  final ${name}Options = <RadioOption<String>>[];");
      }
    } else if (type == 'switch' || type == 'checkbox') {
      final defaultValue =
          (item['defaultValue'] ?? 'false').toString().toLowerCase() == 'true';
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");
    } else if (type == 'file' ||
        type == 'fileupload' ||
        type == 'file upload') {
      buffer.writeln("  var ${name}FileName = ''.obs;");
      buffer.writeln("  var ${name}FilePath = ''.obs;");
      extraMethods.addAll([
        "  Future<void> pick${pascalName}File() async {",
        "    // TODO: integrate file_picker",
        "  }",
        "",
      ]);
    } else if (type == 'image') {
      buffer.writeln("  var ${name}FileName = ''.obs;");
      buffer.writeln("  var ${name}FilePath = ''.obs;");
      extraMethods.addAll([
        "  Future<void> pick${pascalName}Image() async {",
        "    // TODO: integrate file_picker",
        "  }",
        "",
      ]);
    } else if (type == 'multiselect' ||
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
    } else if (type == 'slider' || type == 'range slider') {
      final defaultValue =
          (item['defaultValue'] as num?)?.toDouble() ??
          (item['minValue'] as num?)?.toDouble() ??
          0.0;
      buffer.writeln("  var ${name}Value = $defaultValue.obs;");
    } else if (type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("  var ${name}Value = 0.0.obs;");
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
    } else if (type == 'repeater') {
      buffer.writeln("  final ${name}Items = <dynamic>[].obs;");
      extraMethods.addAll([
        "  void add${pascalName}Item() { ${name}Items.add({}); }",
        "  void remove${pascalName}Item(int index) {",
        "    if (index >= 0 && index < ${name}Items.length) ${name}Items.removeAt(index);",
        "  }",
        "",
      ]);
    } else if (type == 'autocomplete') {
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
    } else if (type == 'signature') {
      buffer.writeln("  var ${name}Signed = false.obs;");
      buffer.writeln("  var ${name}Data = ''.obs;");
      extraMethods.addAll([
        "  Future<void> capture${pascalName}Signature() async {",
        "    // TODO: open signature pad",
        "  }",
        "",
      ]);
    } else if (type == 'formula') {
      buffer.writeln("  var $name = ''.obs;");
    } else if (![
      'label',
      'divider',
      'section',
      'card',
      'tabs',
      'accordion',
      'hidden',
      'row',
    ].contains(type)) {
      buffer.writeln("  var $name = ''.obs;");
    }
  }

  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  void onInit() {");
  buffer.writeln("    super.onInit();");
  if (dropdownInitCalls.isNotEmpty) buffer.writeln("    _loadAllDropdowns();");
  buffer.writeln("  }");
  buffer.writeln();

  if (dropdownInitCalls.isNotEmpty) {
    buffer.writeln("  Future<void> _loadAllDropdowns() async {");
    buffer.writeln("    isExecuting.value = true;");
    buffer.writeln("    try {");
    buffer.writeln("      await Future.wait([");
    for (final call in dropdownInitCalls) {
      buffer.writeln("        $call");
    }
    buffer.writeln("      ]);");
    buffer.writeln("    } catch (e) {");
    buffer.writeln("      _showError('Error loading dropdowns: \$e');");
    buffer.writeln("    } finally {");
    buffer.writeln("      isExecuting.value = false;");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln();
  }

  for (final line in extraMethods) {
    buffer.writeln("  $line");
  }

  buffer.writeln("  void _showSuccess(String message) {");
  buffer.writeln("    showSuccess(message);");
  buffer.writeln("  }");
  buffer.writeln();
  buffer.writeln("  void _showError(String message) {");
  buffer.writeln("    showError(message);");
  buffer.writeln("  }");
  buffer.writeln();

  buffer.writeln("  @override");
  buffer.writeln("  void onClose() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    if ([
      'text',
      'textfield',
      'email',
      'password',
      'phone',
      'textarea',
      'otp',
      'number',
      'integer',
      'int',
      'decimal',
      'double',
      'float',
    ].contains(type)) {
      buffer.writeln("    ${name}Controller.dispose();");
    }
  }
  buffer.writeln("    _workerManager.dispose();");
  buffer.writeln("    super.onClose();");
  buffer.writeln("  }");
  buffer.writeln();

  buffer.writeln("  void clearForm() {");
  for (final item in flatFields) {
    final name = getFieldName(item);
    final pascalName = getPascalName(item);
    final type = (item['type'] ?? '').toString().toLowerCase().trim();
    if ([
      'text',
      'textfield',
      'email',
      'password',
      'phone',
      'textarea',
      'otp',
      'number',
      'integer',
      'int',
      'decimal',
      'double',
      'float',
    ].contains(type)) {
      buffer.writeln("    ${name}Controller.clear();");
    } else if (['date', 'datetime', 'date time', 'time'].contains(type)) {
      buffer.writeln("    ${name}Controller.value = null;");
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      buffer.writeln("    selected$pascalName.value = null;");
    } else if (type == 'radio' || type == 'radio buttons') {
      buffer.writeln("    selected$pascalName.value = '';");
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("    ${name}Value.value = false;");
    } else if (type == 'slider' || type == 'range slider') {
      buffer.writeln("    ${name}Value.value = 0.0;");
    } else if (type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("    ${name}Value.value = 0.0;");
    } else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
      buffer.writeln("    ${name}Selected.clear();");
    } else if (type == 'grid' ||
        type == 'table' ||
        type == 'table/grid' ||
        type == 'table grid' ||
        type == 'table_grid') {
      buffer.writeln("    ${name}Rows.clear();");
    } else if (type == 'repeater') {
      buffer.writeln("    ${name}Items.clear();");
    } else if (type == 'autocomplete') {
      buffer.writeln("    selected${pascalName}Text.value = '';");
    } else if (type == 'signature') {
      buffer.writeln("    ${name}Signed.value = false;");
      buffer.writeln("    ${name}Data.value = '';");
    } else if (type == 'formula') {
      buffer.writeln("    $name.value = '';");
    }
  }
  buffer.writeln("    isDirty.value = false;");
  buffer.writeln("  }");
  buffer.writeln();

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

    if ([
      'text',
      'textfield',
      'email',
      'password',
      'phone',
      'textarea',
      'otp',
      'number',
      'integer',
      'int',
      'decimal',
      'double',
      'float',
    ].contains(type)) {
      buffer.writeln(
        "    if (fieldId == '$id') return ${name}Controller.text;",
      );
    } else if (['date', 'datetime', 'date time'].contains(type)) {
      buffer.writeln(
        "    if (fieldId == '$id') return ${name}Controller.value;",
      );
    } else if (type == 'time') {
      buffer.writeln(
        "    if (fieldId == '$id') return ${name}Controller.value;",
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
    } else if (type == 'radio' || type == 'radio buttons') {
      buffer.writeln(
        "    if (fieldId == '$id') return selected$pascalName.value;",
      );
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Value.value;");
    } else if (type == 'slider' ||
        type == 'range slider' ||
        type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("    if (fieldId == '$id') return ${name}Value.value;");
    } else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
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

  buffer.writeln('  Map<String, dynamic> toJson() {');
  buffer.writeln('    return {');
  for (final item in flatFields) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final name = getFieldName(item);
    final type = (item['type'] ?? '').toString().toLowerCase();
    final useStatic = item['useStaticOptions'] == true;
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
        !useStatic &&
        item['dropdownApiUrl'] != null;

    if ([
      'text',
      'textfield',
      'email',
      'password',
      'phone',
      'textarea',
      'otp',
      'number',
      'integer',
      'int',
      'decimal',
      'double',
      'float',
    ].contains(type)) {
      buffer.writeln("      '$id': ${name}Controller.text,");
    } else if (['date', 'datetime', 'date time'].contains(type)) {
      buffer.writeln(
        "      '$id': ${name}Controller.value?.toIso8601String(),",
      );
    } else if (type == 'time') {
      buffer.writeln(
        "      '$id': ${name}Controller.value != null "
        "? '${'\$'}{${name}Controller.value!.hour.toString().padLeft(2, '0')}:${'\$'}{${name}Controller.value!.minute.toString().padLeft(2, '0')}' "
        ": null,",
      );
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (isApiDropdown) {
        buffer.writeln(
          "      '$id': selected${getPascalName(item)}.value?.id,",
        );
      } else {
        buffer.writeln(
          "      '$id': selected${getPascalName(item)}.value?.key,",
        );
      }
    } else if (type == 'radio' || type == 'radio buttons') {
      buffer.writeln("      '$id': selected${getPascalName(item)}.value,");
    } else if (type == 'switch' || type == 'checkbox') {
      buffer.writeln("      '$id': ${name}Value.value,");
    } else if (type == 'slider' ||
        type == 'range slider' ||
        type == 'starrating' ||
        type == 'rating' ||
        type == 'star rating') {
      buffer.writeln("      '$id': ${name}Value.value,");
    } else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
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

  // ------------------------------------------------------------------------
  // FIXED validateStep() – no private access, uses stepMeta.validations directly
  // ------------------------------------------------------------------------
  buffer.writeln('  bool validateStep() {');
  if (stepMeta.validations.isEmpty) {
    buffer.writeln('    return true;');
  } else {
    buffer.writeln('    bool isValid = true;');
    buffer.writeln('    // Clear previous errors');
    // buffer.writeln('    for (final key in fieldErrors.keys.toList()) {');
    // buffer.writeln('      fieldErrors[key]?.value = "";');
    // buffer.writeln('    }');
    buffer.writeln('    fieldErrors.clear();');
    buffer.writeln();
    for (final v in stepMeta.validations) {
      final fieldId = v['field']?.toString() ?? '';
      if (fieldId.isEmpty) continue;
      final type = v['type']?.toString() ?? 'required';
      final message =
          v['message']?.toString().replaceAll("'", "\\'") ??
          'This field is required';
      if (type == 'required') {
        buffer.writeln("    final ${fieldId}_value = _formValue('$fieldId');");
        // buffer.writeln(
        //   "    if (${fieldId}_value == null || ${fieldId}_value.toString().trim().isEmpty) {",
        // );
        buffer.writeln(
          "    if (${fieldId}_value == null || "
          "(${fieldId}_value is String && ${fieldId}_value.toString().trim().isEmpty)) {",
        );
        buffer.writeln("      fieldErrors['$fieldId'] = '$message';");
        buffer.writeln("      isValid = false;");
        buffer.writeln("    }");
      } else if (type == 'email') {
        buffer.writeln(
          "    final ${fieldId}_value = _formValue('$fieldId')?.toString() ?? '';",
        );
        buffer.writeln(
          "    if (${fieldId}_value.isNotEmpty && !RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$').hasMatch(${fieldId}_value)) {",
        );
        buffer.writeln("      fieldErrors['$fieldId'] = '$message';");
        buffer.writeln("      isValid = false;");
        buffer.writeln("    }");
      } else if (type == 'minLength') {
        final length = v['length'] ?? 3;
        buffer.writeln(
          "    final ${fieldId}_value = _formValue('$fieldId')?.toString() ?? '';",
        );
        buffer.writeln("    if (${fieldId}_value.length < $length) {");
        buffer.writeln("      fieldErrors['$fieldId'] = '$message';");
        buffer.writeln("      isValid = false;");
        buffer.writeln("    }");
      } else if (type == 'maxLength') {
        final length = v['length'] ?? 100;
        buffer.writeln(
          "    final ${fieldId}_value = _formValue('$fieldId')?.toString() ?? '';",
        );
        buffer.writeln("    if (${fieldId}_value.length > $length) {");
        buffer.writeln("      fieldErrors['$fieldId'] = '$message';");
        buffer.writeln("      isValid = false;");
        buffer.writeln("    }");
      } else if (type == 'pattern') {
        final pattern = v['pattern']?.toString() ?? '';
        if (pattern.isNotEmpty) {
          buffer.writeln(
            "    final ${fieldId}_value = _formValue('$fieldId')?.toString() ?? '';",
          );
          buffer.writeln(
            "    if (${fieldId}_value.isNotEmpty && !RegExp(r'$pattern').hasMatch(${fieldId}_value)) {",
          );
          buffer.writeln("      fieldErrors['$fieldId'] = '$message';");
          buffer.writeln("      isValid = false;");
          buffer.writeln("    }");
        }
      }
    }
    buffer.writeln('    return isValid;');
  }
  buffer.writeln('  }');
  buffer.writeln();

  buffer.writeln(
    '  Future<void> executeStepApis({ApiTrigger trigger = ApiTrigger.onNext}) async {',
  );
  buffer.writeln('    // Implement API calls defined in step configuration');
  buffer.writeln('    // For each API call, use _runHttpApi');
  buffer.writeln('  }');
  buffer.writeln();

  buffer.writeln('  Future<void> onPrimaryAction() async {');
  buffer.writeln('    if (isExecuting.value) return;');
  buffer.writeln('    if (!validateStep()) return;');
  buffer.writeln('    await runAsync(() async {');
  buffer.writeln('      isExecuting.value = true;');
  buffer.writeln('      try {');
  buffer.writeln(
    "        await executeStepApis(trigger: ${stepMeta.hasNextStep ? 'ApiTrigger.onNext' : 'ApiTrigger.onSubmit'});",
  );
  if (stepMeta.nextStep != null && stepMeta.nextStep!.isNotEmpty) {
    buffer.writeln("        Get.toNamed('/journey/${stepMeta.nextStep}');");
  } else {
    buffer.writeln("        _showSuccess('Journey completed.');");
  }
  buffer.writeln('      } finally {');
  buffer.writeln('        isExecuting.value = false;');
  buffer.writeln('      }');
  buffer.writeln('    });');
  buffer.writeln('  }');
  buffer.writeln("}");

  return buffer.toString();
}
