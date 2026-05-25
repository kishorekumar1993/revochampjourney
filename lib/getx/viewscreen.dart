String generateviewClass(
  String className,
  List<Map<String, dynamic>> fields,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Recursive flatten ────────────────────────────────────────
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
  flattenFields(fields, flatFields);

  // ─── Name helpers ──────────────────────────────────────────────

  // ✅ Derive model class from dropdowndata key — not from label
  // "recipes":[...] → "RecipeModel", "todos":[...] → "TodoModel"
  String resolveModelClass(Map<String, dynamic> field) {
    final dropdowndata = field['dropdowndata'];
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
          final singular = singularize(entry.key);
          return capitalize(singular); // ✅ removed 'Model'
        }
      }
    }
    // Fallback – also without Model suffix
    final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
        .toString()
        .trim();
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return capitalize(n);
  }

  // String resolveModelClass(Map<String, dynamic> field) {
  //   final dropdowndata = field['dropdowndata'];
  //   if (dropdowndata is Map<String, dynamic>) {
  //     for (final entry in dropdowndata.entries) {
  //       final v = entry.value;
  //       if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
  //         final singular = singularize(entry.key);
  //         return '${capitalize(singular)}Model';
  //       }
  //     }
  //   }
  //   final raw = (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
  //       .toString()
  //       .trim();
  //   final n = raw.replaceAll(RegExp(r'\s+'), '');
  //   return '${capitalize(n)}Model';
  // }

  // "RecipeModel" → "recipe"  (for import file name)
  String modelClassToFileName(String modelClass) {
    final base = modelClass.endsWith('Model')
        ? modelClass.substring(0, modelClass.length - 5)
        : modelClass;
    final snake = base.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
    return snake.startsWith('_') ? snake.substring(1) : snake;
  }

  // ─── Conditional imports ───────────────────────────────────────
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
    "import '../controllers/${fileName.toLowerCase().replaceAll(' ', '_')}_controller.dart';",
  );
  buffer.writeln("import '/widget/common_text_form.dart';");
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  if (hasDropdown) {
    buffer.writeln("import '/widget/common_dropdown_search.dart';");
  }

  // ✅ Model imports derived from dropdowndata keys — not from label
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
        final modelClass = resolveModelClass(field);
        final modelFile = modelClassToFileName(modelClass);
        if (emittedModelFiles.add(modelFile)) {
          buffer.writeln("import '../model/${modelFile}_model.dart';");
        }
      }
    }
  }

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
  buffer.writeln("      appBar: AppBar(title: const Text('$className Form')),");
  buffer.writeln("      body: Padding(");
  buffer.writeln("        padding: const EdgeInsets.all(16.0),");
  buffer.writeln("        child: Form(");
  buffer.writeln("          key: formKey,");
  buffer.writeln(
    "          autovalidateMode: AutovalidateMode.onUserInteraction,",
  );
  buffer.writeln("          child: SingleChildScrollView(");
  buffer.writeln("            child: Column(");
  buffer.writeln("              crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("              children: [");

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
        buffer.writeln("                CustomTextFormField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln(
          "                  controller: controller.${name}Controller,",
        );
        buffer.writeln("                  isDatePicker: true,");
        buffer.writeln("                  readOnly: $isReadOnly,");
        buffer.writeln("                  validator: (value) {");
        buffer.writeln("                    try {");
        if (isRequired) {
          buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';",
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
      } else if (type == 'datetime' || type == 'date time') {
        buffer.writeln("                CustomTextFormField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln(
          "                  controller: controller.${name}Controller,",
        );
        buffer.writeln("                  isDateTimePicker: true,");
        buffer.writeln("                  readOnly: $isReadOnly,");
        buffer.writeln("                  validator: (value) {");
        buffer.writeln("                    try {");
        if (isRequired) {
          buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';",
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
      } else if (type == 'textarea') {
        buffer.writeln("                CustomTextFormField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln(
          "                  controller: controller.${name}Controller,",
        );
        buffer.writeln("                  maxLines: 4,");
        if (maxLength > 0) {
          buffer.writeln("                  maxLength: $maxLength,");
        }
        buffer.writeln("                  readOnly: $isReadOnly,");
        buffer.writeln(
          "                  keyboardType: TextInputType.multiline,",
        );
        buffer.writeln(
          "                  textInputAction: TextInputAction.newline,",
        );
        buffer.writeln("                  validator: (value) {");
        buffer.writeln("                    try {");
        if (isRequired) {
          buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';",
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

        // ══════════════════════════════════════════════
        // dropdown ✅ FIXED: model from dropdowndata key
        // ══════════════════════════════════════════════
      } else if (type == 'dropdown' || type == 'api_dropdown') {
        if (isApiDropdown) {
          final dropdownmodel = resolveModelClass(field); // e.g., "Post"
          // final dropdownKey = (field['dropdownValue'] ?? 'name').toString();
          final dropdownKey = (field['dropdownValue'] ?? 'title')
              .toString(); // better default
          buffer.writeln(
            "                Obx(() => DropdownSearch<$dropdownmodel>(",
          );
          buffer.writeln("                  hint: '$rawLabel',");
          buffer.writeln("                  label: '$rawLabel',");
          buffer.writeln("                  isMandatory: $isRequired,");
          buffer.writeln("                  labelType: LabelType.top,");
          // Using item.property (non‑nullable item)
          buffer.writeln(
            "                  itemAsString: (item) => item.$dropdownKey?.toString() ?? '',",
          );
          buffer.writeln("                  items: controller.${name}Options,");
          buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,",
          );
          buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,",
          );
          if (isRequired) {
            buffer.writeln("                  validator: (value) {");
            buffer.writeln(
              "                    if (value == null) return '$rawLabel is required';",
            );
            buffer.writeln("                    return null;");
            buffer.writeln("                  },");
          }
          buffer.writeln("                )),");
        } else if (staticOpts != null && staticOpts.isNotEmpty) {
          final optionsList = staticOpts
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
                final val = o.toString().replaceAll("'", "\\'");
                return "DropdownItem(key: '$val', value: '$val')";
              })
              .join(', ');

          buffer.writeln(
            "                Obx(() => DropdownSearch<DropdownItem>(",
          );
          buffer.writeln("                  hint: '$rawLabel',");
          buffer.writeln("                  label: '$rawLabel',");
          buffer.writeln("                  isMandatory: $isRequired,");
          buffer.writeln("                  labelType: LabelType.top,");
          buffer.writeln(
            "                  itemAsString: (item) => item.value,",
          );
          buffer.writeln("                  items: [$optionsList],");
          buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,",
          );
          buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,",
          );
          if (isRequired) {
            buffer.writeln("                  validator: (value) {");
            buffer.writeln(
              "                    if (value == null) return '$rawLabel is required';",
            );
            buffer.writeln("                    return null;");
            buffer.writeln("                  },");
          }
          buffer.writeln("                )),");
        }
      } else if (type == 'radio' || type == 'radio buttons') {
        final optionsList = staticOpts != null
            ? staticOpts
                  .map((o) {
                    final val = o.toString().replaceAll("'", "\\'");
                    return "RadioOption<String>(value: '$val', label: '$val')";
                  })
                  .join(', ')
            : '';

        buffer.writeln("                Obx(() => CustomRadioGroup<String>(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln(
          "                  selectedValue: controller.selected$capitalLabel.value,",
        );
        buffer.writeln(
          "                  onChanged: (value) => controller.selected$capitalLabel.value = value!,",
        );
        if (optionsList.isNotEmpty) {
          buffer.writeln("                  options: [$optionsList],");
        } else {
          buffer.writeln(
            "                  options: controller.${name}Options,",
          );
        }
        if (isRequired) {
          buffer.writeln("                  validator: (value) {");
          buffer.writeln(
            "                    if (value == null || value.isEmpty) return '$rawLabel is required';",
          );
          buffer.writeln("                    return null;");
          buffer.writeln("                  },");
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
        buffer.writeln("                Obx(() => FormField<String>(");
        buffer.writeln(
          "                  validator: (_) => $isRequired && controller.${name}FileName.value.isEmpty",
        );
        buffer.writeln(
          "                      ? '$rawLabel is required' : null,",
        );
        buffer.writeln("                  builder: (formState) => Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      Text(");
        buffer.writeln(
          "                        '$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),",
        );
        buffer.writeln("                      ),");
        buffer.writeln("                      const SizedBox(height: 8),");
        buffer.writeln("                      GestureDetector(");
        buffer.writeln("                        onTap: () async {");
        buffer.writeln(
          "                          await controller.pick${capitalLabel}File();",
        );
        buffer.writeln(
          "                          formState.didChange(controller.${name}FileName.value);",
        );
        buffer.writeln("                        },");
        buffer.writeln("                        child: Container(");
        buffer.writeln("                          width: double.infinity,");
        buffer.writeln(
          "                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),",
        );
        buffer.writeln("                          decoration: BoxDecoration(");
        buffer.writeln(
          "                            border: Border.all(color: formState.hasError ? Colors.red : Colors.grey),",
        );
        buffer.writeln(
          "                            borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln("                          ),");
        buffer.writeln("                          child: Row(");
        buffer.writeln("                            children: [");
        buffer.writeln(
          "                              const Icon(Icons.upload_file, color: Colors.grey),",
        );
        buffer.writeln(
          "                              const SizedBox(width: 8),",
        );
        buffer.writeln("                              Expanded(");
        buffer.writeln("                                child: Text(");
        buffer.writeln(
          "                                  controller.${name}FileName.value.isEmpty",
        );
        buffer.writeln(
          "                                      ? 'Tap to upload $rawLabel'",
        );
        buffer.writeln(
          "                                      : controller.${name}FileName.value,",
        );
        buffer.writeln(
          "                                  style: TextStyle(color: Colors.grey[700]),",
        );
        buffer.writeln(
          "                                  overflow: TextOverflow.ellipsis,",
        );
        buffer.writeln("                                ),");
        buffer.writeln("                              ),");
        buffer.writeln("                            ],");
        buffer.writeln("                          ),");
        buffer.writeln("                        ),");
        buffer.writeln("                      ),");
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
        buffer.writeln("                    ],");
        buffer.writeln("                  ),");
        buffer.writeln("                )),");
      } else if (type == 'otp') {
        buffer.writeln("                Column(");
        buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                  children: [");
        buffer.writeln("                    Text(");
        buffer.writeln(
          "                      '$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),",
        );
        buffer.writeln("                    ),");
        buffer.writeln("                    const SizedBox(height: 8),");
        buffer.writeln("                    CustomTextFormField(");
        buffer.writeln("                      label: '',");
        buffer.writeln("                      hint: '$hint',");
        buffer.writeln("                      isMandatory: $isRequired,");
        buffer.writeln(
          "                      controller: controller.${name}Controller,",
        );
        buffer.writeln(
          "                      keyboardType: TextInputType.number,",
        );
        buffer.writeln("                      maxLines: 1,");
        buffer.writeln("                      validator: (value) {");
        buffer.writeln("                        try {");
        if (isRequired) {
          buffer.writeln(
            "                          if (value == null || value.isEmpty) return '$rawLabel is required';",
          );
        }
        if (minLength > 0 || maxLength > 0) {
          if (minLength > 0) {
            buffer.writeln(
              "                          if (value != null && value.length < $minLength) return 'Minimum $minLength digits';",
            );
          }
          if (maxLength > 0) {
            buffer.writeln(
              "                          if (value != null && value.length > $maxLength) return 'Maximum $maxLength digits';",
            );
          }
        } else {
          buffer.writeln(
            "                          if (value != null && value.length != 6) return 'Enter a valid 6-digit code';",
          );
        }
        if (pattern.isNotEmpty) {
          buffer.writeln(
            "                          if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';",
          );
        }
        buffer.writeln("                          return null;");
        buffer.writeln("                        } catch (e) {");
        buffer.writeln("                          return 'Invalid input';");
        buffer.writeln("                        }");
        buffer.writeln("                      },");
        buffer.writeln("                    ),");
        buffer.writeln("                  ],");
        buffer.writeln("                ),");
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
        buffer.writeln("                      CheckboxListTile(");
        buffer.writeln(
          "                        title: Text('$rawLabel${isRequired ? ' *' : ''}'),",
        );
        buffer.writeln(
          "                        value: controller.${name}Value.value,",
        );
        buffer.writeln("                        onChanged: (val) {");
        buffer.writeln(
          "                          controller.${name}Value.value = val ?? false;",
        );
        buffer.writeln(
          "                          formState.didChange(val ?? false);",
        );
        buffer.writeln("                        },");
        buffer.writeln(
          "                        contentPadding: EdgeInsets.zero,",
        );
        buffer.writeln(
          "                        controlAffinity: ListTileControlAffinity.leading,",
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
        buffer.writeln("                CustomTextFormField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln(
          "                  controller: controller.${name}Controller,",
        );
        buffer.writeln("                  isTimePicker: true,");
        buffer.writeln("                  readOnly: $isReadOnly,");
        buffer.writeln("                  validator: (value) {");
        buffer.writeln("                    try {");
        if (isRequired) {
          buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';",
          );
        }
        buffer.writeln("                      return null;");
        buffer.writeln("                    } catch (e) {");
        buffer.writeln("                      return 'Invalid input';");
        buffer.writeln("                    }");
        buffer.writeln("                  },");
        buffer.writeln("                ),");
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

        buffer.writeln("                Obx(() => FormField<List<String>>(");
        buffer.writeln("                  initialValue: const [],");
        buffer.writeln("                  validator: (value) {");
        if (isRequired) {
          buffer.writeln(
            "                    if (value == null || value.isEmpty) return '$rawLabel is required';",
          );
        }
        buffer.writeln("                    return null;");
        buffer.writeln("                  },");
        buffer.writeln("                  builder: (formState) => Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      Text(");
        buffer.writeln(
          "                        '$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),",
        );
        buffer.writeln("                      ),");
        buffer.writeln("                      const SizedBox(height: 8),");
        if (optionsList.isNotEmpty) {
          buffer.writeln(
            "                      ...[$optionsList].map((option) => CheckboxListTile(",
          );
        } else {
          buffer.writeln(
            "                      ...controller.${name}Options.map((option) => CheckboxListTile(",
          );
        }
        buffer.writeln("                        title: Text(option),");
        buffer.writeln(
          "                        value: controller.${name}Selected.contains(option),",
        );
        buffer.writeln("                        onChanged: (val) {");
        buffer.writeln("                          if (val == true) {");
        buffer.writeln(
          "                            controller.${name}Selected.add(option);",
        );
        buffer.writeln("                          } else {");
        buffer.writeln(
          "                            controller.${name}Selected.remove(option);",
        );
        buffer.writeln("                          }");
        buffer.writeln(
          "                          formState.didChange(controller.${name}Selected.toList());",
        );
        buffer.writeln("                        },");
        buffer.writeln(
          "                        contentPadding: EdgeInsets.zero,",
        );
        buffer.writeln(
          "                        controlAffinity: ListTileControlAffinity.leading,",
        );
        buffer.writeln("                      )).toList(),");
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
        buffer.writeln("                Obx(() => FormField<String>(");
        buffer.writeln(
          "                  validator: (_) => $isRequired && controller.${name}FileName.value.isEmpty",
        );
        buffer.writeln(
          "                      ? '$rawLabel is required' : null,",
        );
        buffer.writeln("                  builder: (formState) => Column(");
        buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,",
        );
        buffer.writeln("                    children: [");
        buffer.writeln("                      Text(");
        buffer.writeln(
          "                        '$rawLabel${isRequired ? ' *' : ''}',",
        );
        buffer.writeln(
          "                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),",
        );
        buffer.writeln("                      ),");
        buffer.writeln("                      const SizedBox(height: 8),");
        buffer.writeln("                      GestureDetector(");
        buffer.writeln("                        onTap: () async {");
        buffer.writeln(
          "                          await controller.pick${capitalLabel}Image();",
        );
        buffer.writeln(
          "                          formState.didChange(controller.${name}FileName.value);",
        );
        buffer.writeln("                        },");
        buffer.writeln("                        child: Container(");
        buffer.writeln("                          width: double.infinity,");
        buffer.writeln("                          height: 120,");
        buffer.writeln("                          decoration: BoxDecoration(");
        buffer.writeln(
          "                            border: Border.all(color: formState.hasError ? Colors.red : Colors.grey),",
        );
        buffer.writeln(
          "                            borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln("                          ),");
        buffer.writeln(
          "                          child: controller.${name}FileName.value.isEmpty",
        );
        buffer.writeln(
          "                              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [",
        );
        buffer.writeln(
          "                                  const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),",
        );
        buffer.writeln(
          "                                  const SizedBox(height: 8),",
        );
        buffer.writeln(
          "                                  Text('Tap to select $rawLabel', style: TextStyle(color: Colors.grey[600])),",
        );
        buffer.writeln("                                ])");
        buffer.writeln("                              : ClipRRect(");
        buffer.writeln(
          "                                  borderRadius: BorderRadius.circular(8),",
        );
        buffer.writeln(
          "                                  child: Image.network(controller.${name}FileName.value, fit: BoxFit.cover, width: double.infinity),",
        );
        buffer.writeln("                                ),");
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
        buffer.writeln("                    return CustomTextFormField(");
        buffer.writeln("                      label: '$rawLabel',");
        buffer.writeln("                      hint: '$hint',");
        buffer.writeln("                      isMandatory: $isRequired,");
        buffer.writeln("                      controller: textController,");
        buffer.writeln("                      focusNode: focusNode,");
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
        buffer.writeln("                Obx(() => CustomTextFormField(");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  hint: '$hint',");
        buffer.writeln("                  isMandatory: false,");
        buffer.writeln(
          "                  controller: TextEditingController(text: controller.$name.value),",
        );
        buffer.writeln("                  readOnly: true,");
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

  buffer.writeln("                const SizedBox(height: 20),");
  buffer.writeln("                Center(");
  buffer.writeln("                  child: ElevatedButton(");
  buffer.writeln("                    onPressed: () {");
  buffer.writeln(
    "                      if (formKey.currentState?.validate() ?? false) {",
  );
  buffer.writeln("                        // TODO: Submit logic");
  buffer.writeln("                      }");
  buffer.writeln("                    },");
  buffer.writeln("                    child: const Text('Submit'),");
  buffer.writeln("                  ),");
  buffer.writeln("                ),");
  buffer.writeln("              ],");
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
}) {
  buffer.writeln("                CustomTextFormField(");
  buffer.writeln("                  label: '$label',");
  buffer.writeln("                  hint: '$hint',");
  buffer.writeln("                  isMandatory: $isRequired,");
  buffer.writeln("                  controller: controller.${name}Controller,");
  buffer.writeln(
    "                  keyboardType: TextInputType.$keyboardType,",
  );
  buffer.writeln("                  isPassword: $isPassword,");
  buffer.writeln("                  isNumber: $isNumber,");
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
