import 'package:revojourneytryone/filegegnerator/journey_step_codegen.dart';
import 'package:revojourneytryone/getx/getx_model_naming.dart';

String generateviewClass(
  String className,
  List<dynamic> fields,
  String fileName, {
  Map<String, dynamic>? stepJson,
}) {
  final buffer = StringBuffer();
  final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});

  // ─── Recursive flatten ────────────────────────────────────────
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
  flattenFields(fields, flatFields);

  // ─── Name helpers ──────────────────────────────────────────────

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../controllers/${fileName.toLowerCase().replaceAll(' ', '_')}_controller.dart';",
  );
  buffer.writeln("import '/core/widgets/widgets.dart';");

  // ✅ Model imports derived from dropdowndata keys — not from label
  final emittedModelFiles = <String>{};
  for (final field in flatFields) {
    if (!fieldNeedsGetxModel(field)) continue;
    final modelFile = resolveGetxModelFileBase(field);
    if (emittedModelFiles.add(modelFile)) {
      buffer.writeln("import '${getxModelImportPath(modelFile)}';");
    }
  }

  buffer.writeln();
  buffer.writeln("DateTime? _parseDateInput(String input) {");
  buffer.writeln("  if (input.trim().isEmpty) return null;");
  buffer.writeln("  final parts = input.split('/');");
  buffer.writeln("  if (parts.length == 3) {");
  buffer.writeln("    final day = int.tryParse(parts[0]);");
  buffer.writeln("    final month = int.tryParse(parts[1]);");
  buffer.writeln("    final year = int.tryParse(parts[2]);");
  buffer.writeln("    if (day != null && month != null && year != null) {");
  buffer.writeln("      return DateTime(year, month, day);");
  buffer.writeln("    }");
  buffer.writeln("  }");
  buffer.writeln("  return DateTime.tryParse(input);");
  buffer.writeln("}");
  buffer.writeln();
  buffer.writeln("String _formatDateInput(DateTime date) {");
  buffer.writeln("  final d = date.day.toString().padLeft(2, '0');");
  buffer.writeln("  final m = date.month.toString().padLeft(2, '0');");
  buffer.writeln("  final y = date.year.toString();");
  buffer.writeln("  return '\$d/\$m/\$y';");
  buffer.writeln("}");
  buffer.writeln();
  buffer.writeln("class ${className}View extends StatelessWidget {");
  buffer.writeln("  const ${className}View({super.key});");
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  Widget build(BuildContext context) {");
  buffer.writeln("    final controller = Get.find<${className}Controller>();");
  buffer.writeln("    final formKey = GlobalKey<FormState>();");
  buffer.writeln();
  buffer.writeln("    return Scaffold(");
  buffer.writeln("      backgroundColor: const Color(0xFFF8FAFC),");
  buffer.writeln("      appBar: AppBar(");
  buffer.writeln(
    "        title: const Text('${stepMeta.escapedTitle}', style: TextStyle(fontWeight: FontWeight.w600)),",
  );
  buffer.writeln("        backgroundColor: Colors.transparent,");
  buffer.writeln("        foregroundColor: const Color(0xFF0F172A),");
  buffer.writeln("        elevation: 0,");
  buffer.writeln("        centerTitle: true,");
  buffer.writeln("      ),");
  buffer.writeln("      body: SafeArea(");
  buffer.writeln("        child: Center(");
  buffer.writeln("          child: ConstrainedBox(");
  buffer.writeln("            constraints: const BoxConstraints(maxWidth: 600),");
  buffer.writeln("            child: SingleChildScrollView(");
  buffer.writeln(
    "              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),",
  );
  buffer.writeln("              child: Container(");
  buffer.writeln("                padding: const EdgeInsets.all(24),");
  buffer.writeln("                decoration: BoxDecoration(");
  buffer.writeln("                  color: Colors.white,");
  buffer.writeln(
    "                  borderRadius: BorderRadius.circular(20),",
  );
  buffer.writeln(
    "                  border: Border.all(color: const Color(0xFFE2E8F0)),",
  );
  buffer.writeln("                ),");
  buffer.writeln("                child: Form(");
  buffer.writeln("                  key: formKey,");
  buffer.writeln(
    "                  autovalidateMode: AutovalidateMode.onUserInteraction,",
  );
  buffer.writeln("                  child: Column(");
  buffer.writeln("                    crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("                    children: [");
  stepMeta.writeFlutterStepHeader(buffer);

  void buildWidgets(List<dynamic> currentFields) {
    for (final rawField in currentFields) {
      if (rawField is! Map<String, dynamic>) continue;
      final field = rawField;

      final rawId =
          (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'field')
              .toString()
              .trim();
      final rawLabel = rawId;
      final name = camelCaseName(rawId);
      final capitalLabel = pascalCaseName(rawId);
      final type = (field['type'] ?? '').toString().toLowerCase().trim();
      final hint = (field['placeholder'] ?? field['hintText'] ?? '').toString();
      final isRequired = field['required'] == true;
      final isPassword = field['obscureText'] == true;
      final isReadOnly = field['readOnly'] == true;
      final rawKeyboard = (field['keyboardType'] ?? 'text')
          .toString()
          .toLowerCase();
      final keyboardType = _mapKeyboardType(rawKeyboard);
      final isNumber = rawKeyboard == 'number';
      final textInputAction = (field['textInputAction'] ?? 'done')
          .toString()
          .toLowerCase();
      final textCapitalization = (field['textCapitalization'] ?? 'none')
          .toString()
          .toLowerCase();
      final minLength = int.tryParse(field['minLength']?.toString() ?? '') ?? 0;
      final maxLength = int.tryParse(field['maxLength']?.toString() ?? '') ?? 0;
      final pattern = (field['validationPattern'] ?? '').toString().replaceAll(
        r'\',
        r'\\',
      );
      final errorMessage = (field['errorMessage'] ?? 'Invalid format')
          .toString();
      final staticOpts =
          (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      final useStatic = field['useStaticOptions'] == true;
      final isApiDropdown =
          (type == 'dropdown' || type == 'api_dropdown') &&
          !useStatic &&
          field['dropdownApiUrl'] != null;

      if (type == 'text' || type == 'textfield') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: isPassword,
          isReadOnly: isReadOnly,
          keyboardType: keyboardType,
          isNumber: isNumber,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'phone') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'phone',
          isNumber: true,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern.isNotEmpty ? pattern : r'^\+?[0-9]{7,15}$',
          errorMessage: errorMessage.isNotEmpty
              ? errorMessage
              : 'Enter a valid phone number',
        );
      } else if (type == 'date') {
        _writeDatePickerField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isReadOnly: isReadOnly,
        );
      } else if (type == 'datetime' || type == 'date time') {
        _writeDateTimePickerField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isReadOnly: isReadOnly,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'textarea') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'multiline',
          isNumber: false,
          textInputAction: 'newline',
          textCapitalization: textCapitalization,
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern,
          errorMessage: errorMessage,
          maxLines: 4,
          minLines: 3,
        );

        // ══════════════════════════════════════════════
        // dropdown ✅ FIXED: model from dropdowndata key
        // ══════════════════════════════════════════════
      } else if (type == 'dropdown' || type == 'api_dropdown') {
        if (isApiDropdown) {
          final dropdownmodel = resolveGetxModelClassName(field);
          final dropdownKey = (field['dropdownValue'] ?? 'title')
              .toString();
          buffer.writeln(
            "                Obx(() => AppDropdownField<$dropdownmodel>(",
          );
          buffer.writeln("                  label: '$rawLabel',");
          buffer.writeln("                  hint: '$hint',");
          buffer.writeln(
            "                  itemLabelBuilder: (item) => item.$dropdownKey?.toString() ?? '',",
          );
          buffer.writeln("                  items: controller.${name}Options,");
          buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,",
          );
          buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,",
          );
          buffer.writeln("                  errorText: null,");
          buffer.writeln("                )),");
        } else if (staticOpts != null && staticOpts.isNotEmpty) {
          final optionsList = staticOpts.map((o) {
            if (o is Map) {
              return "'${(o['value'] ?? o['label'] ?? o['title'] ?? o['key'] ?? o['id'] ?? '').toString().replaceAll("'", "\\'")}'";
            }
            return "'${o.toString().replaceAll("'", "\\'")}'";
          }).join(', ');

          buffer.writeln(
            "                Obx(() => AppDropdownField<String>(",
          );
          buffer.writeln("                  label: '$rawLabel',");
          buffer.writeln("                  hint: '$hint',");
          buffer.writeln("                  itemLabelBuilder: (item) => item,");
          buffer.writeln("                  items: [$optionsList],");
          buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,",
          );
          buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,",
          );
          buffer.writeln("                  errorText: null,");
          buffer.writeln("                )),");
        }
      } else if (type == 'radio' || type == 'radio buttons') {
        final optionsList = staticOpts != null
            ? staticOpts
                  .map((o) {
                    final val = o.toString().replaceAll("'", "\\'");
                    return "'$val'";
                  })
                  .join(', ')
            : '';

        buffer.writeln("                Obx(() => AppRadioGroupField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  errorText: null,");
        buffer.writeln(
          "                  value: controller.selected$capitalLabel.value?.toString(),",
        );
        buffer.writeln(
          "                  onChanged: (value) => controller.selected$capitalLabel.value = value ?? '',",
        );
        if (optionsList.isNotEmpty) {
          buffer.writeln("                  options: [$optionsList],");
        } else {
          buffer.writeln(
            "                  options: controller.${name}Options.map((e) => e.toString()).toList(),",
          );
        }
        buffer.writeln("                )),");
      } else if (type == 'switch') {
        buffer.writeln("                Obx(() => FormField<bool>(");
        buffer.writeln("                  initialValue: false,");
        buffer.writeln("                  validator: (value) {");
        if (isRequired) {
          buffer.writeln(
            "                    if (value != true) return '$rawLabel';",
          );
        }
        buffer.writeln("                    return null;");
        buffer.writeln("                  },");
        buffer.writeln("                  builder: (formState) => Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      SwitchListTile(");
        buffer.writeln(
          "                        title: const Text('$rawLabel'),",
        );
        buffer.writeln(
          "                        value: controller.${name}Value.value,",
        );
        buffer.writeln("                        onChanged: (val) {");
        buffer.writeln(
          "                          controller.${name}Value.value = val;",
        );
        buffer.writeln("                          formState.didChange(val);");
        buffer.writeln("                        },");
        buffer.writeln(
          "                        contentPadding: EdgeInsets.zero,",
        );
        buffer.writeln("                      ),");
        if (isRequired) {
          buffer.writeln("                      if (formState.hasError)");
          buffer.writeln("                        Padding(");
          buffer.writeln(
            "                          padding: const EdgeInsets.only(left: 4, bottom: 4),",
          );
          buffer.writeln("                          child: Text(");
          buffer.writeln(
            "                            formState.errorText ?? '',",
          );
          buffer.writeln(
            "                            style: const TextStyle(color: Colors.red, fontSize: 12),",
          );
          buffer.writeln("                          ),");
          buffer.writeln("                        ),");
        }
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                )),");
      } else if (type == 'file') {
        _writeFilePickerField(
          buffer,
          label: rawLabel,
          name: name,
          pickMethod: "pick${capitalLabel}File",
        );
      } else if (type == 'otp') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'number',
          isNumber: true,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength > 0 ? minLength : 6,
          maxLength: maxLength > 0 ? maxLength : 6,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'divider') {
        buffer.writeln("                Padding(");
        buffer.writeln(
          "                  padding: const EdgeInsets.symmetric(vertical: 12.0),",
        );
        buffer.writeln("                  child: Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      Text(");
        buffer.writeln("                        '$rawLabel',");
        buffer.writeln(
          "                        style: Theme.of(context).textTheme.bodyMedium,",
        );
        buffer.writeln("                      ),");
        buffer.writeln("                      const SizedBox(height: 8),");
        buffer.writeln("                      const Divider(),");
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                ),");
      } else if (type == 'checkbox') {
        buffer.writeln("                Obx(() => AppCheckboxField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  value: controller.${name}Value.value,");
        buffer.writeln(
          "                  onChanged: (val) => controller.${name}Value.value = val ?? false,",
        );
        buffer.writeln("                  errorText: null,");
        buffer.writeln("                )),");
      } else if (type == 'number' || type == 'integer' || type == 'int') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'number',
          isNumber: true,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'decimal' || type == 'double' || type == 'float') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'decimalPad',
          isNumber: true,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'email') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: false,
          isReadOnly: isReadOnly,
          keyboardType: 'emailAddress',
          isNumber: false,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern.isNotEmpty ? pattern : r'^[\w\.-]+@[\w\.-]+\.\w+$',
          errorMessage: errorMessage.isNotEmpty
              ? errorMessage
              : 'Enter a valid email',
        );
      } else if (type == 'password') {
        _writeTextFormField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isPassword: true,
          isReadOnly: isReadOnly,
          keyboardType: 'text',
          isNumber: false,
          textInputAction: textInputAction,
          textCapitalization: 'none',
          minLength: minLength,
          maxLength: maxLength,
          pattern: pattern,
          errorMessage: errorMessage,
        );
      } else if (type == 'time') {
        _writeTimePickerField(
          buffer,
          label: rawLabel,
          name: name,
          hint: hint,
          isRequired: isRequired,
          isReadOnly: isReadOnly,
        );
      } else if (type == 'multiselect' ||
          type == 'multi select' ||
          type == 'multi_select') {
        final optionsList = staticOpts != null && staticOpts.isNotEmpty
            ? staticOpts
                  .map((o) {
                    final val = o.toString().replaceAll("'", "\\'");
                    return "'$val'";
                  })
                  .join(', ')
            : '';

        buffer.writeln("                Obx(() => AppMultiSelectField(");
        buffer.writeln("                  label: '$rawLabel',");
        if (optionsList.isNotEmpty) {
          buffer.writeln("                  options: [$optionsList],");
        } else {
          buffer.writeln(
            "                  options: controller.${name}Options.map((e) => e.toString()).toList(),",
          );
        }
        buffer.writeln(
          "                  selectedValues: controller.${name}Selected.toList(),",
        );
        buffer.writeln("                  errorText: null,");
        buffer.writeln("                  onChanged: (values) {");
        buffer.writeln("                    controller.${name}Selected.assignAll(values);");
        buffer.writeln("                  },");
        buffer.writeln("                )),");
      } else if (type == 'slider' || type == 'range slider') {
        final minVal = (field['minValue'] as num?)?.toDouble() ?? 0.0;
        final maxVal = (field['maxValue'] as num?)?.toDouble() ?? 100.0;

        buffer.writeln("                Obx(() => Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln("                    Row(");
        buffer.writeln(
          "                      mainAxisAlignment: MainAxisAlignment.spaceBetween,",
        );
        buffer.writeln("                      children: [");
        buffer.writeln(
          "                        Text('$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),",
        );
        buffer.writeln(
          "                        Text('\${controller.${name}Value.value.toStringAsFixed(0)}',",
        );
        buffer.writeln(
          "                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),",
        );
        buffer.writeln("                      ],");
        buffer.writeln("                    ),");
        buffer.writeln("                    Slider(");
        buffer.writeln(
          "                      value: controller.${name}Value.value,",
        );
        buffer.writeln("                      min: $minVal,");
        buffer.writeln("                      max: $maxVal,");
        buffer.writeln(
          "                      onChanged: (val) => controller.${name}Value.value = val,",
        );
        buffer.writeln("                    ),");
        buffer.writeln("                  ],");
        buffer.writeln("                )),");
      } else if (type == 'label') {
        buffer.writeln("                Padding(");
        buffer.writeln(
          "                  padding: const EdgeInsets.symmetric(vertical: 4.0),",
        );
        buffer.writeln("                  child: Text(");
        buffer.writeln("                    '$rawLabel',");
        buffer.writeln(
          "                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),",
        );
        buffer.writeln("                  ),");
        buffer.writeln("                ),");
      } else if (type == 'hidden') {
        continue;
      } else if (type == 'image') {
        _writeFilePickerField(
          buffer,
          label: rawLabel,
          name: name,
          pickMethod: "pick${capitalLabel}Image",
        );
      } else if (type == 'starrating' ||
          type == 'rating' ||
          type == 'star rating') {
        final maxStars = (field['maxValue'] as num?)?.toInt() ?? 5;
        buffer.writeln("                Obx(() => Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln(
          "                    Text('$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),",
        );
        buffer.writeln("                    const SizedBox(height: 8),");
        buffer.writeln("                    Row(");
        buffer.writeln(
          "                      children: List.generate($maxStars, (index) {",
        );
        buffer.writeln("                        final star = index + 1;");
        buffer.writeln("                        return GestureDetector(");
        buffer.writeln(
          "                          onTap: () => controller.${name}Value.value = star.toDouble(),",
        );
        buffer.writeln("                          child: Icon(");
        buffer.writeln(
          "                            star <= controller.${name}Value.value.round() ? Icons.star : Icons.star_border,",
        );
        buffer.writeln("                            color: Colors.amber,");
        buffer.writeln("                            size: 32,");
        buffer.writeln("                          ),");
        buffer.writeln("                        );");
        buffer.writeln("                      }),");
        buffer.writeln("                    ),");
        buffer.writeln("                  ],");
        buffer.writeln("                )),");
      } else if (type == 'section') {
        buffer.writeln("                Padding(");
        buffer.writeln(
          "                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),",
        );
        buffer.writeln("                  child: Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      Text(");
        buffer.writeln("                        '$rawLabel',");
        buffer.writeln(
          "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),",
        );
        buffer.writeln("                      ),");
        buffer.writeln("                      const SizedBox(height: 4),");
        buffer.writeln("                      const Divider(thickness: 1.5),");
        buffer.writeln("                      const SizedBox(height: 8),");
        final nested = field['nestedFields'] as List<dynamic>? ?? [];
        if (nested.isNotEmpty) buildWidgets(nested);
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                ),");
      } else if (type == 'card') {
        buffer.writeln("                Card(");
        buffer.writeln("                  elevation: 2,");
        buffer.writeln(
          "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),",
        );
        buffer.writeln("                  child: Padding(");
        buffer.writeln(
          "                    padding: const EdgeInsets.all(16.0),",
        );
        buffer.writeln("                    child: Column(");
        buffer.writeln(
          "                      crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                      children: [");
        buffer.writeln("                        Text(");
        buffer.writeln("                          '$rawLabel',");
        buffer.writeln(
          "                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),",
        );
        buffer.writeln("                        ),");
        buffer.writeln("                        const SizedBox(height: 12),");
        final nested = field['nestedFields'] as List<dynamic>? ?? [];
        if (nested.isNotEmpty) {
          buildWidgets(nested);
        } else {
          buffer.writeln("                        // No child fields defined");
        }
        buffer.writeln("                      ],");
        buffer.writeln("                    ),");
        buffer.writeln("                  ),");
        buffer.writeln("                ),");
      } else if (type == 'tabs') {
        final nested = field['nestedFields'] as List<dynamic>? ?? [];
        final tabOptions = nested.isNotEmpty
            ? nested
                  .map((t) => ((t as Map)['label'] ?? 'Tab').toString())
                  .toList()
            : (staticOpts != null && staticOpts.isNotEmpty
                  ? staticOpts.map((o) => o.toString()).toList()
                  : ['Tab 1', 'Tab 2']);
        final tabLength = tabOptions.length;
        final tabItems = tabOptions
            .map((t) => "Tab(text: '${t.replaceAll("'", "\\'")}')")
            .join(', ');
        buffer.writeln("                DefaultTabController(");
        buffer.writeln("                  length: $tabLength,");
        buffer.writeln("                  child: Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        if (rawLabel.isNotEmpty) {
          buffer.writeln(
            "                      Text('$rawLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),",
          );
          buffer.writeln("                      const SizedBox(height: 8),");
        }
        buffer.writeln(
          "                      const TabBar(tabs: [$tabItems]),",
        );
        buffer.writeln("                      SizedBox(");
        buffer.writeln("                        height: 200,");
        buffer.writeln("                        child: TabBarView(children: [");
        for (int i = 0; i < tabLength; i++) {
          buffer.writeln("                          SingleChildScrollView(");
          buffer.writeln(
            "                            padding: const EdgeInsets.all(16.0),",
          );
          buffer.writeln("                            child: Column(");
          buffer.writeln(
            "                              crossAxisAlignment: CrossAxisAlignment.start,",
          );
          buffer.writeln("                              children: [");
          if (nested.isNotEmpty && i < nested.length) {
            final tabNested =
                (nested[i] as Map)['nestedFields'] as List<dynamic>? ?? [];
            if (tabNested.isNotEmpty) buildWidgets(tabNested);
          } else {
            buffer.writeln(
              "                                const Center(child: Text('// No content')),",
            );
          }
          buffer.writeln("                              ],");
          buffer.writeln("                            ),");
          buffer.writeln("                          ),");
        }
        buffer.writeln("                        ]),");
        buffer.writeln("                      ),");
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                ),");
      } else if (type == 'accordion') {
        buffer.writeln("                ExpansionTile(");
        buffer.writeln(
          "                  title: Text('$rawLabel', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),",
        );
        buffer.writeln("                  shape: RoundedRectangleBorder(");
        buffer.writeln(
          "                    side: BorderSide(color: Colors.grey.shade300),",
        );
        buffer.writeln(
          "                    borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln("                  ),");
        buffer.writeln(
          "                  collapsedShape: RoundedRectangleBorder(",
        );
        buffer.writeln(
          "                    side: BorderSide(color: Colors.grey.shade300),",
        );
        buffer.writeln(
          "                    borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln("                  ),");
        buffer.writeln("                  children: const [");
        buffer.writeln("                    Padding(");
        buffer.writeln("                      padding: EdgeInsets.all(16.0),");
        buffer.writeln("                      child: Column(");
        buffer.writeln(
          "                        crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                        children: [");
        final nested = field['nestedFields'] as List<dynamic>? ?? [];
        if (nested.isNotEmpty) buildWidgets(nested);
        buffer.writeln("                        ],");
        buffer.writeln("                      ),");
        buffer.writeln("                    ),");
        buffer.writeln("                  ],");
        buffer.writeln("                ),");
      } else if (type == 'grid' ||
          type == 'table' ||
          type == 'table/grid' ||
          type == 'table grid' ||
          type == 'table_grid') {
        final config = field['componentConfig'] as Map<String, dynamic>? ?? {};
        final columns =
            (config['columns'] as List<dynamic>?) ??
            (field['columns'] as List<dynamic>?) ??
            [];
        final hasColumns = columns.isNotEmpty;
        buffer.writeln("                Obx(() => Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln("                    Row(");
        buffer.writeln(
          "                      mainAxisAlignment: MainAxisAlignment.spaceBetween,",
        );
        buffer.writeln("                      children: [");
        buffer.writeln(
          "                        Text('$rawLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),",
        );
        buffer.writeln("                        ElevatedButton.icon(");
        buffer.writeln(
          "                          onPressed: () => controller.add${capitalLabel}Row(),",
        );
        buffer.writeln(
          "                          icon: const Icon(Icons.add, size: 18),",
        );
        buffer.writeln(
          "                          label: const Text('Add Row'),",
        );
        buffer.writeln("                        ),");
        buffer.writeln("                      ],");
        buffer.writeln("                    ),");
        buffer.writeln("                    const SizedBox(height: 8),");
        buffer.writeln("                    SingleChildScrollView(");
        buffer.writeln(
          "                      scrollDirection: Axis.horizontal,",
        );
        buffer.writeln("                      child: DataTable(");
        buffer.write("                        columns: [");
        if (hasColumns) {
          for (final col in columns) {
            final colLabel = col is Map
                ? (col['label'] ?? col['id'] ?? col['fieldId'] ?? 'Column')
                      .toString()
                : col.toString();
            buffer.write(
              "DataColumn(label: Text('${colLabel.replaceAll("'", "\\'")}')), ",
            );
          }
        } else {
          buffer.write(
            "const DataColumn(label: Text('#')), const DataColumn(label: Text('Value')), const DataColumn(label: Text('Actions')), ",
          );
        }
        buffer.writeln("],");
        buffer.writeln(
          "                        rows: controller.${name}Rows.asMap().entries.map((entry) {",
        );
        buffer.writeln("                          final i = entry.key;");
        buffer.writeln("                          final row = entry.value;");
        buffer.writeln("                          return DataRow(cells: [");
        if (hasColumns) {
          for (final col in columns) {
            final fieldId = col is Map
                ? (col['fieldId'] ?? col['id'] ?? col['label'] ?? 'value')
                      .toString()
                : col.toString();
            buffer.writeln("                            DataCell(");
            buffer.writeln("                              TextFormField(");
            buffer.writeln(
              "                                initialValue: row['${fieldId.replaceAll("'", "\\'")}']?.toString() ?? '',",
            );
            buffer.writeln(
              "                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),",
            );
            buffer.writeln(
              "                                onChanged: (val) => controller.update${capitalLabel}Cell(i, '${fieldId.replaceAll("'", "\\'")}', val),",
            );
            buffer.writeln("                              ),");
            buffer.writeln("                            ),");
          }
        } else {
          buffer.writeln(
            "                            DataCell(Text('\${i + 1}')),",
          );
          buffer.writeln("                            DataCell(");
          buffer.writeln("                              TextFormField(");
          buffer.writeln(
            "                                initialValue: row.toString(),",
          );
          buffer.writeln(
            "                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),",
          );
          buffer.writeln(
            "                                onChanged: (val) => controller.update${capitalLabel}Cell(i, 'value', val),",
          );
          buffer.writeln("                              ),");
          buffer.writeln("                            ),");
        }
        buffer.writeln("                            DataCell(Row(children: [");
        buffer.writeln(
          "                              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => controller.delete${capitalLabel}Row(i)),",
        );
        buffer.writeln("                            ])),");
        buffer.writeln("                          ]);");
        buffer.writeln("                        }).toList(),");
        buffer.writeln("                      ),");
        buffer.writeln("                    ),");
        buffer.writeln("                  ],");
        buffer.writeln("                )),");
      } else if (type == 'repeater') {
        buffer.writeln("                Obx(() => Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln("                    Row(");
        buffer.writeln(
          "                      mainAxisAlignment: MainAxisAlignment.spaceBetween,",
        );
        buffer.writeln("                      children: [");
        buffer.writeln(
          "                        Text('$rawLabel${isRequired ? ' *' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),",
        );
        buffer.writeln("                        ElevatedButton.icon(");
        buffer.writeln(
          "                          onPressed: () => controller.add${capitalLabel}Item(),",
        );
        buffer.writeln(
          "                          icon: const Icon(Icons.add, size: 18),",
        );
        buffer.writeln("                          label: const Text('Add'),");
        buffer.writeln("                        ),");
        buffer.writeln("                      ],");
        buffer.writeln("                    ),");
        buffer.writeln("                    const SizedBox(height: 8),");
        buffer.writeln(
          "                    ...controller.${name}Items.asMap().entries.map((entry) {",
        );
        buffer.writeln("                      final i = entry.key;");
        buffer.writeln("                      return Card(");
        buffer.writeln(
          "                        margin: const EdgeInsets.only(bottom: 8),",
        );
        buffer.writeln("                        child: ListTile(");
        buffer.writeln(
          "                          title: Text('$rawLabel \${i + 1}'),",
        );
        buffer.writeln("                          trailing: IconButton(");
        buffer.writeln(
          "                            icon: const Icon(Icons.delete, color: Colors.red),",
        );
        buffer.writeln(
          "                            onPressed: () => controller.remove${capitalLabel}Item(i),",
        );
        buffer.writeln("                          ),");
        buffer.writeln(
          "                          // TODO: Add repeater item fields",
        );
        buffer.writeln("                        ),");
        buffer.writeln("                      );");
        buffer.writeln("                    }).toList(),");
        buffer.writeln("                  ],");
        buffer.writeln("                )),");
      } else if (type == 'timeline') {
        buffer.writeln("                Obx(() => Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln(
          "                    Text('$rawLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),",
        );
        buffer.writeln("                    const SizedBox(height: 8),");
        buffer.writeln(
          "                    ...controller.${name}Steps.asMap().entries.map((entry) {",
        );
        buffer.writeln("                      final i = entry.key;");
        buffer.writeln("                      final step = entry.value;");
        buffer.writeln(
          "                      final isLast = i == controller.${name}Steps.length - 1;",
        );
        buffer.writeln("                      return IntrinsicHeight(");
        buffer.writeln("                        child: Row(");
        buffer.writeln(
          "                          crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                          children: [");
        buffer.writeln("                            Column(");
        buffer.writeln("                              children: [");
        buffer.writeln("                                Container(");
        buffer.writeln(
          "                                  width: 24, height: 24,",
        );
        buffer.writeln(
          "                                  decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),",
        );
        buffer.writeln(
          "                                  child: Center(child: Text('\${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),",
        );
        buffer.writeln("                                ),");
        buffer.writeln(
          "                                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),",
        );
        buffer.writeln("                              ],");
        buffer.writeln("                            ),");
        buffer.writeln(
          "                            const SizedBox(width: 12),",
        );
        buffer.writeln("                            Expanded(");
        buffer.writeln("                              child: Padding(");
        buffer.writeln(
          "                                padding: const EdgeInsets.only(bottom: 16.0),",
        );
        buffer.writeln(
          "                                child: Text(step.toString(), style: const TextStyle(fontSize: 14)),",
        );
        buffer.writeln("                              ),");
        buffer.writeln("                            ),");
        buffer.writeln("                          ],");
        buffer.writeln("                        ),");
        buffer.writeln("                      );");
        buffer.writeln("                    }).toList(),");
        buffer.writeln("                  ],");
        buffer.writeln("                )),");
      } else if (type == 'autocomplete') {
        buffer.writeln("                Autocomplete<String>(");
        buffer.writeln(
          "                  optionsBuilder: (TextEditingValue textEditingValue) {",
        );
        buffer.writeln(
          "                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();",
        );
        buffer.writeln(
          "                    return controller.${name}Options.where((opt) =>",
        );
        buffer.writeln(
          "                      opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));",
        );
        buffer.writeln("                  },");
        buffer.writeln(
          "                  onSelected: (val) => controller.selected${capitalLabel}Text.value = val,",
        );
        buffer.writeln(
          "                  fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {",
        );
        buffer.writeln("                    return AppTextField(");
        buffer.writeln("                      label: '$rawLabel',");
        buffer.writeln("                      hint: '$hint',");
        buffer.writeln("                      controller: textController,");
        buffer.writeln("                      focusNode: focusNode,");
        buffer.writeln("                      errorText: null,");
        buffer.writeln("                      validator: (value) {");
        if (isRequired) {
          buffer.writeln(
            "                        if (value == null || value.isEmpty) return '$rawLabel is required';",
          );
        }
        buffer.writeln("                        return null;");
        buffer.writeln("                      },");
        buffer.writeln("                    );");
        buffer.writeln("                  },");
        buffer.writeln("                ),");
      } else if (type == 'signature') {
        buffer.writeln("                Obx(() => FormField<bool>(");
        buffer.writeln("                  initialValue: false,");
        buffer.writeln("                  validator: (value) {");
        if (isRequired) {
          buffer.writeln(
            "                    if (value != true) return '$rawLabel is required';",
          );
        }
        buffer.writeln("                    return null;");
        buffer.writeln("                  },");
        buffer.writeln("                  builder: (formState) => Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln(
          "                      Text('$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),",
        );
        buffer.writeln("                      const SizedBox(height: 8),");
        buffer.writeln("                      GestureDetector(");
        buffer.writeln("                        onTap: () async {");
        buffer.writeln(
          "                          await controller.capture${capitalLabel}Signature();",
        );
        buffer.writeln(
          "                          formState.didChange(controller.${name}Signed.value);",
        );
        buffer.writeln("                        },");
        buffer.writeln("                        child: Container(");
        buffer.writeln("                          width: double.infinity,");
        buffer.writeln("                          height: 120,");
        buffer.writeln("                          decoration: BoxDecoration(");
        buffer.writeln("                            border: Border.all(");
        buffer.writeln(
          "                              color: formState.hasError ? Colors.red : Colors.grey.shade400,",
        );
        buffer.writeln("                            ),");
        buffer.writeln(
          "                            borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln("                          ),");
        buffer.writeln(
          "                          child: controller.${name}Signed.value",
        );
        buffer.writeln(
          "                              ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 40))",
        );
        buffer.writeln(
          "                              : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [",
        );
        buffer.writeln(
          "                                  Icon(Icons.draw, color: Colors.grey),",
        );
        buffer.writeln(
          "                                  SizedBox(height: 4),",
        );
        buffer.writeln(
          "                                  Text('Tap to sign', style: TextStyle(color: Colors.grey)),",
        );
        buffer.writeln("                                ])),");
        buffer.writeln("                        ),");
        buffer.writeln("                      ),");
        if (isRequired) {
          buffer.writeln("                      if (formState.hasError)");
          buffer.writeln("                        Padding(");
          buffer.writeln(
            "                          padding: const EdgeInsets.only(top: 6, left: 4),",
          );
          buffer.writeln("                          child: Text(");
          buffer.writeln(
            "                            formState.errorText ?? '',",
          );
          buffer.writeln(
            "                            style: const TextStyle(color: Colors.red, fontSize: 12),",
          );
          buffer.writeln("                          ),");
          buffer.writeln("                        ),");
        }
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                )),");
      } else if (type == 'row') {
        buffer.writeln("                Wrap(");
        buffer.writeln("                  spacing: 12, runSpacing: 12,");
        buffer.writeln("                  children: [");
        final nested = field['nestedFields'] as List<dynamic>? ?? [];
        for (final child in nested) {
          if (child is! Map) continue;
          final colSpan =
              int.tryParse(
                child['componentConfig']?['colSpan']?.toString() ?? '',
              ) ??
              12;
          buffer.writeln(
            "                    LayoutBuilder(builder: (context, constraints) {",
          );
          buffer.writeln(
            "                      final w = constraints.maxWidth;",
          );
          buffer.writeln(
            "                      return SizedBox(width: w > 760 ? w * ($colSpan / 12) : double.infinity,",
          );
          buffer.writeln(
            "                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [",
          );
          buildWidgets([child]);
          buffer.writeln("                        ]),");
          buffer.writeln("                      );");
          buffer.writeln("                    }),");
        }
        buffer.writeln("                  ],");
        buffer.writeln("                ),");
      } else if (type == 'formula') {
        buffer.writeln("                Obx(() => AppTextField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln(
          "                  controller: TextEditingController(text: controller.$name.value),",
        );
        buffer.writeln("                  readOnly: true,");
        buffer.writeln("                  errorText: null,");
        buffer.writeln("                  validator: (value) => null,");
        buffer.writeln("                )),");
      } else {
        buffer.writeln(
          "                // TODO: unsupported field type '$type' for '$rawLabel'",
        );
      }

      buffer.writeln("                const SizedBox(height: 16),");
    }
  }

  buildWidgets(fields);

  stepMeta.writeFlutterActionButtons(
    buffer,
    onPressedHandler: '() => controller.onPrimaryAction()',
  );
  buffer.writeln("                    ],");
  buffer.writeln("                  ),");
  buffer.writeln("                ),");
  buffer.writeln("              ),");
  buffer.writeln("            ),");
  buffer.writeln("          ),");
  buffer.writeln("        ),");
  buffer.writeln("      ),");
  buffer.writeln("    );");
  buffer.writeln("  }");
  buffer.writeln("}");

  return buffer.toString();
}

// ─── Shared helpers ───────────────────────────────────────────────
void _writeTextFormField(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String hint,
  required bool isRequired,
  required bool isPassword,
  required bool isReadOnly,
  required String keyboardType,
  required bool isNumber,
  required String textInputAction,
  required String textCapitalization,
  required int minLength,
  required int maxLength,
  required String pattern,
  required String errorMessage,
  int? maxLines,
  int? minLines,
}) {
  buffer.writeln("                AppTextField(");
  buffer.writeln("                  label: '$label',");
  buffer.writeln("                  hint: '$hint',");
  buffer.writeln("                  controller: controller.${name}Controller,");
  buffer.writeln(
    "                  keyboardType: TextInputType.$keyboardType,",
  );
  buffer.writeln("                  obscureText: $isPassword,");
  buffer.writeln("                  readOnly: $isReadOnly,");
  buffer.writeln(
    "                  textInputAction: TextInputAction.$textInputAction,",
  );
  buffer.writeln(
    "                  textCapitalization: TextCapitalization.$textCapitalization,",
  );
  if (maxLength > 0) {
    buffer.writeln("                  maxLength: $maxLength,");
  }
  if (maxLines != null) {
    buffer.writeln("                  maxLines: $maxLines,");
  }
  if (minLines != null) {
    buffer.writeln("                  minLines: $minLines,");
  }
  buffer.writeln("                  errorText: null,");
  buffer.writeln("                  validator: (value) {");
  buffer.writeln("                    try {");
  if (isRequired) {
    buffer.writeln(
      "                      if (value == null || value.isEmpty) return '$label is required';",
    );
  }
  if (minLength > 0) {
    buffer.writeln(
      "                      if (value != null && value.length < $minLength) return 'Minimum $minLength characters';",
    );
  }
  if (maxLength > 0) {
    buffer.writeln(
      "                      if (value != null && value.length > $maxLength) return 'Maximum $maxLength characters';",
    );
  }
  if (pattern.isNotEmpty) {
    buffer.writeln(
      "                      if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';",
    );
  }
  buffer.writeln("                      return null;");
  buffer.writeln("                    } catch (e) {");
  buffer.writeln("                      return 'Invalid input';");
  buffer.writeln("                    }");
  buffer.writeln("                  },");
  buffer.writeln("                ),");
}

void _writeDatePickerField(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String hint,
  required bool isReadOnly,
}) {
  buffer.writeln("                Obx(() => AppDatePickerField(");
  buffer.writeln("                  label: '$label',");
  buffer.writeln("                  hint: '${hint.isNotEmpty ? hint : 'Select date'}',");
  buffer.writeln(
    "                  value: _parseDateInput(controller.${name}Controller.text),",
  );
  buffer.writeln("                  errorText: null,");
  buffer.writeln("                  enabled: ${!isReadOnly},");
  buffer.writeln("                  onChanged: (picked) {");
  buffer.writeln("                    if (picked != null) {");
  buffer.writeln(
    "                      controller.${name}Controller.text = _formatDateInput(picked);",
  );
  buffer.writeln("                    }");
  buffer.writeln("                  },");
  buffer.writeln("                )),");
}

void _writeTimePickerField(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String hint,
  required bool isRequired,
  required bool isReadOnly,
}) {
  buffer.writeln("                GestureDetector(");
  buffer.writeln("                  onTap: ${isReadOnly ? 'null' : '() async {'}");
  if (!isReadOnly) {
    buffer.writeln(
      "                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());",
    );
    buffer.writeln(
      "                    if (picked != null) controller.${name}Controller.text = picked.format(context);",
    );
    buffer.writeln("                  },");
  }
  buffer.writeln("                  child: AbsorbPointer(");
  buffer.writeln("                    child: AppTextField(");
  buffer.writeln("                      label: '$label',");
  buffer.writeln("                      hint: '${hint.isNotEmpty ? hint : 'Select time'}',");
  buffer.writeln("                      controller: controller.${name}Controller,");
  buffer.writeln("                      readOnly: true,");
  buffer.writeln("                      errorText: null,");
  buffer.writeln(
    "                      suffixIcon: const Icon(Icons.access_time_rounded),",
  );
  buffer.writeln("                      validator: (value) {");
  if (isRequired) {
    buffer.writeln(
      "                        if (value == null || value.isEmpty) return '$label is required';",
    );
  }
  buffer.writeln("                        return null;");
  buffer.writeln("                      },");
  buffer.writeln("                    ),");
  buffer.writeln("                  ),");
  buffer.writeln("                ),");
}

void _writeDateTimePickerField(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String hint,
  required bool isRequired,
  required bool isReadOnly,
  required String pattern,
  required String errorMessage,
}) {
  buffer.writeln("                GestureDetector(");
  buffer.writeln("                  onTap: ${isReadOnly ? 'null' : '() async {'}");
  if (!isReadOnly) {
    buffer.writeln(
      "                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));",
    );
    buffer.writeln("                    if (date == null) return;");
    buffer.writeln(
      "                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());",
    );
    buffer.writeln("                    if (time == null) return;");
    buffer.writeln(
      "                    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);",
    );
    buffer.writeln(
      "                    controller.${name}Controller.text = '\${_formatDateInput(dt)} \${time.format(context)}';",
    );
    buffer.writeln("                  },");
  }
  buffer.writeln("                  child: AbsorbPointer(");
  buffer.writeln("                    child: AppTextField(");
  buffer.writeln("                      label: '$label',");
  buffer.writeln(
    "                      hint: '${hint.isNotEmpty ? hint : 'Select date and time'}',",
  );
  buffer.writeln("                      controller: controller.${name}Controller,");
  buffer.writeln("                      readOnly: true,");
  buffer.writeln("                      errorText: null,");
  buffer.writeln(
    "                      suffixIcon: const Icon(Icons.calendar_month_rounded),",
  );
  buffer.writeln("                      validator: (value) {");
  if (isRequired) {
    buffer.writeln(
      "                        if (value == null || value.isEmpty) return '$label is required';",
    );
  }
  if (pattern.isNotEmpty) {
    buffer.writeln(
      "                        if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';",
    );
  }
  buffer.writeln("                        return null;");
  buffer.writeln("                      },");
  buffer.writeln("                    ),");
  buffer.writeln("                  ),");
  buffer.writeln("                ),");
}

void _writeFilePickerField(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String pickMethod,
}) {
  buffer.writeln("                Obx(() => AppFileUploadField(");
  buffer.writeln("                  label: '$label',");
  buffer.writeln(
    "                  value: controller.${name}FileName.value.isEmpty ? null : controller.${name}FileName.value,",
  );
  buffer.writeln("                  hint: 'Tap Browse to select file',");
  buffer.writeln("                  errorText: null,");
  buffer.writeln("                  onChanged: (_) async {");
  buffer.writeln("                    await controller.$pickMethod();");
  buffer.writeln("                  },");
  buffer.writeln("                )),");
}

String _mapKeyboardType(String raw) {
  switch (raw) {
    case 'number':
    case 'numeric':
    case 'integer':
    case 'int':
      return 'number';
    case 'decimal':
    case 'double':
    case 'float':
    case 'decimalPad':
      return 'decimalPad';
    case 'phone':
      return 'phone';
    case 'email':
    case 'emailAddress':
      return 'emailAddress';
    case 'url':
      return 'url';
    case 'multiline':
      return 'multiline';
    default:
      return 'text';
  }
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
