String generateviewClass(
  String className,
  List<Map<String, dynamic>> fields,
  String fileName,
) {
  final buffer = StringBuffer();

  // ─── Conditional imports ───────────────────────────────────────
  final hasRadio = fields.any((f) =>
      (f['type'] ?? '').toString().toLowerCase().startsWith('radio'));
  final hasDropdown = fields.any((f) =>
      (f['type'] ?? '').toString().toLowerCase() == 'dropdown');

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../controllers/${fileName.toLowerCase()}_controller.dart';",
  );
  buffer.writeln("import '/widget/common_text_form.dart';");
  if (hasRadio) buffer.writeln("import '/widget/common_radiobutton.dart';");
  if (hasDropdown)
    buffer.writeln("import '/widget/common_dropdown_search.dart';");

  // ─── Collect dynamic dropdown model imports ────────────────────
  final dropdownModels = <String>{};
  for (final field in fields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown') {
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if (staticOpts == null || staticOpts.isEmpty) {
        final label = (field['label'] ?? '').toString().trim();
        dropdownModels.add(label);
      }
    }
  }
  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../model/${modelFile}_model.dart';");
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
  buffer.writeln(
      "      appBar: AppBar(title: const Text('$className Form')),");
  buffer.writeln("      body: Padding(");
  buffer.writeln("        padding: const EdgeInsets.all(16.0),");
  buffer.writeln("        child: Form(");
  buffer.writeln("          key: formKey,");
  buffer.writeln(
      "          autovalidateMode: AutovalidateMode.onUserInteraction,");
  buffer.writeln("          child: SingleChildScrollView(");
  buffer.writeln("            child: Column(");
  buffer.writeln(
      "              crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("              children: [");

  for (final field in fields) {
    final rawLabel = (field['label'] ?? 'Field').toString().trim();
    final name = camelCaseName(rawLabel);
    final capitalLabel = pascalCaseName(rawLabel);
    final type = (field['type'] ?? '').toString().toLowerCase().trim();
    final hint =
        (field['placeholder'] ?? field['hintText'] ?? '').toString();
    final isRequired = field['required'] == true;
    final isPassword = field['obscureText'] == true;
    final isReadOnly = field['readOnly'] == true;
    final rawKeyboard =
        (field['keyboardType'] ?? 'text').toString().toLowerCase();
    final keyboardType = _mapKeyboardType(rawKeyboard);
    final isNumber = rawKeyboard == 'number';
    final textInputAction =
        (field['textInputAction'] ?? 'done').toString().toLowerCase();
    final textCapitalization =
        (field['textCapitalization'] ?? 'none').toString().toLowerCase();
    final minLength = (field['minLength'] ?? 0) as int;
    final maxLength = (field['maxLength'] ?? 0) as int;
    final pattern = (field['validationPattern'] ?? '')
        .toString()
        .replaceAll(r'\', r'\\');
    final errorMessage =
        (field['errorMessage'] ?? 'Invalid format').toString();
    final staticOpts = (field['options'] as List<dynamic>?) ??
        (field['staticOptions'] as List<dynamic>?);

    // ══════════════════════════════════════════════
    //  text | textfield
    // ══════════════════════════════════════════════
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

    // ══════════════════════════════════════════════
    //  phone
    // ══════════════════════════════════════════════
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

    // ══════════════════════════════════════════════
    //  date
    // ══════════════════════════════════════════════
    } else if (type == 'date') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
          "                  controller: controller.${name}Controller,");
      buffer.writeln("                  isDatePicker: true,");
      buffer.writeln("                  readOnly: $isReadOnly,");
      buffer.writeln("                  validator: (value) {");
      buffer.writeln("                    try {");
      if (isRequired) {
        buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';");
      }
      if (pattern.isNotEmpty) {
        buffer.writeln(
            "                      if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';");
      }
      buffer.writeln("                      return null;");
      buffer.writeln("                    } catch (e) {");
      buffer.writeln("                      return 'Invalid input';");
      buffer.writeln("                    }");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

    // ══════════════════════════════════════════════
    //  datetime / date time
    // ══════════════════════════════════════════════
    } else if (type == 'datetime' || type == 'date time') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
          "                  controller: controller.${name}Controller,");
      buffer.writeln("                  isDateTimePicker: true,");
      buffer.writeln("                  readOnly: $isReadOnly,");
      buffer.writeln("                  validator: (value) {");
      buffer.writeln("                    try {");
      if (isRequired) {
        buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';");
      }
      if (pattern.isNotEmpty) {
        buffer.writeln(
            "                      if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';");
      }
      buffer.writeln("                      return null;");
      buffer.writeln("                    } catch (e) {");
      buffer.writeln("                      return 'Invalid input';");
      buffer.writeln("                    }");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

    // ══════════════════════════════════════════════
    //  textarea
    // ══════════════════════════════════════════════
    } else if (type == 'textarea') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
          "                  controller: controller.${name}Controller,");
      buffer.writeln("                  maxLines: 4,");
      buffer.writeln("                  readOnly: $isReadOnly,");
      buffer.writeln(
          "                  keyboardType: TextInputType.multiline,");
      buffer.writeln(
          "                  textInputAction: TextInputAction.newline,");
      buffer.writeln("                  validator: (value) {");
      buffer.writeln("                    try {");
      if (isRequired) {
        buffer.writeln(
            "                      if (value == null || value.isEmpty) return '$rawLabel is required';");
      }
      buffer.writeln("                      return null;");
      buffer.writeln("                    } catch (e) {");
      buffer.writeln("                      return 'Invalid input';");
      buffer.writeln("                    }");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

    // ══════════════════════════════════════════════
    //  dropdown
    // ══════════════════════════════════════════════
    } else if (type == 'dropdown') {
      if (staticOpts != null && staticOpts.isNotEmpty) {
        final optionsList = staticOpts.map((o) {
          final val = o.toString().replaceAll("'", "\\'");
          return "DropdownItem(key: '$val', value: '$val')";
        }).join(', ');

        buffer.writeln(
            "                Obx(() => DropdownSearch<DropdownItem>(");
        buffer.writeln("                  hint: '$rawLabel',");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln("                  labelType: LabelType.top,");
        buffer.writeln(
            "                  itemAsString: (item) => item.value,");
        buffer.writeln("                  items: [$optionsList],");
        buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,");
        buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,");
        if (isRequired) {
          buffer.writeln("                  validator: (value) {");
          buffer.writeln(
              "                    if (value == null) return '$rawLabel is required';");
          buffer.writeln("                    return null;");
          buffer.writeln("                  },");
        }
        buffer.writeln("                )),");
      } else {
        final dropdownKey =
            (field['dropdownValue'] ?? 'name').toString();
        String? dropdownmodel;
        final apidata = field['dropdowndata'];
        if (apidata is Map<String, dynamic>) {
          for (final entry in apidata.entries) {
            final v = entry.value;
            if (v is List &&
                v.isNotEmpty &&
                v.first is Map<String, dynamic>) {
              dropdownmodel = capitalize(entry.key);
              break;
            }
          }
        }
        dropdownmodel ??= '${capitalLabel}Model';

        buffer.writeln(
            "                Obx(() => DropdownSearch<$dropdownmodel>(");
        buffer.writeln("                  hint: '$rawLabel',");
        buffer.writeln("                  label: '$rawLabel',");
        buffer.writeln("                  isMandatory: $isRequired,");
        buffer.writeln("                  labelType: LabelType.top,");
        buffer.writeln(
            "                  itemAsString: (item) => item?.$dropdownKey ?? '',");
        buffer.writeln(
            "                  items: controller.${name}Options,");
        buffer.writeln(
            "                  value: controller.selected$capitalLabel.value,");
        buffer.writeln(
            "                  onChanged: (val) => controller.selected$capitalLabel.value = val,");
        if (isRequired) {
          buffer.writeln("                  validator: (value) {");
          buffer.writeln(
              "                    if (value == null) return '$rawLabel is required';");
          buffer.writeln("                    return null;");
          buffer.writeln("                  },");
        }
        buffer.writeln("                )),");
      }

    // ══════════════════════════════════════════════
    //  radio | radio buttons  ✅ FIXED
    // ══════════════════════════════════════════════
    } else if (type == 'radio' || type == 'radio buttons') {
      // ✅ Wrap each string in RadioOption<String> — NOT raw strings
      final optionsList = staticOpts != null
          ? staticOpts.map((o) {
              final val = o.toString().replaceAll("'", "\\'");
              return "RadioOption<String>(value: '$val', label: '$val')";
            }).join(', ')
          : '';

      buffer.writeln(
          "                Obx(() => CustomRadioGroup<String>(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
          "                  selectedValue: controller.selected$capitalLabel.value,");
      buffer.writeln(
          "                  onChanged: (value) => controller.selected$capitalLabel.value = value!,");
      if (optionsList.isNotEmpty) {
        buffer.writeln(
            "                  options: [$optionsList],");
      } else {
        buffer.writeln(
            "                  options: controller.${name}Options,");
      }
      if (isRequired) {
        buffer.writeln("                  validator: (value) {");
        buffer.writeln(
            "                    if (value == null || value.isEmpty) return '$rawLabel is required';");
        buffer.writeln("                    return null;");
        buffer.writeln("                  },");
      }
      buffer.writeln("                )),");

    // ══════════════════════════════════════════════
    //  switch
    // ══════════════════════════════════════════════
    } else if (type == 'switch') {
      buffer.writeln("                Obx(() => FormField<bool>(");
      buffer.writeln("                  initialValue: false,");
      buffer.writeln("                  validator: (value) {");
      if (isRequired) {
        buffer.writeln(
            "                    if (value != true) return '$rawLabel';");
      }
      buffer.writeln("                    return null;");
      buffer.writeln("                  },");
      buffer.writeln(
          "                  builder: (formState) => Column(");
      buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                    children: [");
      buffer.writeln("                      SwitchListTile(");
      buffer.writeln(
          "                        title: const Text('$rawLabel'),");
      buffer.writeln(
          "                        value: controller.${name}Value.value,");
      buffer.writeln("                        onChanged: (val) {");
      buffer.writeln(
          "                          controller.${name}Value.value = val;");
      buffer.writeln(
          "                          formState.didChange(val);");
      buffer.writeln("                        },");
      buffer.writeln(
          "                        contentPadding: EdgeInsets.zero,");
      buffer.writeln("                      ),");
      if (isRequired) {
        buffer.writeln(
            "                      if (formState.hasError)");
        buffer.writeln("                        Padding(");
        buffer.writeln(
            "                          padding: const EdgeInsets.only(left: 4, bottom: 4),");
        buffer.writeln("                          child: Text(");
        buffer.writeln(
            "                            formState.errorText ?? '',");
        buffer.writeln(
            "                            style: const TextStyle(color: Colors.red, fontSize: 12),");
        buffer.writeln("                          ),");
        buffer.writeln("                        ),");
      }
      buffer.writeln("                    ],");
      buffer.writeln("                  ),");
      buffer.writeln("                )),");

    // ══════════════════════════════════════════════
    //  file
    // ══════════════════════════════════════════════
    } else if (type == 'file') {
      buffer.writeln("                Obx(() => FormField<String>(");
      buffer.writeln(
          "                  validator: (_) => $isRequired && controller.${name}FileName.value.isEmpty");
      buffer.writeln(
          "                      ? '$rawLabel is required' : null,");
      buffer.writeln(
          "                  builder: (formState) => Column(");
      buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                    children: [");
      buffer.writeln("                      Text(");
      buffer.writeln(
          "                        '$rawLabel${isRequired ? ' *' : ''}',");
      buffer.writeln(
          "                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),");
      buffer.writeln("                      ),");
      buffer.writeln("                      const SizedBox(height: 8),");
      buffer.writeln("                      GestureDetector(");
      buffer.writeln("                        onTap: () async {");
      buffer.writeln(
          "                          await controller.pick${capitalLabel}File();");
      buffer.writeln(
          "                          formState.didChange(controller.${name}FileName.value);");
      buffer.writeln("                        },");
      buffer.writeln("                        child: Container(");
      buffer.writeln(
          "                          width: double.infinity,");
      buffer.writeln(
          "                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),");
      buffer.writeln(
          "                          decoration: BoxDecoration(");
      buffer.writeln(
          "                            border: Border.all(color: formState.hasError ? Colors.red : Colors.grey),");
      buffer.writeln(
          "                            borderRadius: BorderRadius.circular(8),");
      buffer.writeln("                          ),");
      buffer.writeln("                          child: Row(");
      buffer.writeln("                            children: [");
      buffer.writeln(
          "                              const Icon(Icons.upload_file, color: Colors.grey),");
      buffer.writeln(
          "                              const SizedBox(width: 8),");
      buffer.writeln("                              Expanded(");
      buffer.writeln("                                child: Text(");
      buffer.writeln(
          "                                  controller.${name}FileName.value.isEmpty");
      buffer.writeln(
          "                                      ? 'Tap to upload $rawLabel'");
      buffer.writeln(
          "                                      : controller.${name}FileName.value,");
      buffer.writeln(
          "                                  style: TextStyle(color: Colors.grey[700]),");
      buffer.writeln(
          "                                  overflow: TextOverflow.ellipsis,");
      buffer.writeln("                                ),");
      buffer.writeln("                              ),");
      buffer.writeln("                            ],");
      buffer.writeln("                          ),");
      buffer.writeln("                        ),");
      buffer.writeln("                      ),");
      buffer.writeln(
          "                      if (formState.hasError)");
      buffer.writeln("                        Padding(");
      buffer.writeln(
          "                          padding: const EdgeInsets.only(top: 6, left: 4),");
      buffer.writeln("                          child: Text(");
      buffer.writeln(
          "                            formState.errorText ?? '',");
      buffer.writeln(
          "                            style: const TextStyle(color: Colors.red, fontSize: 12),");
      buffer.writeln("                          ),");
      buffer.writeln("                        ),");
      buffer.writeln("                    ],");
      buffer.writeln("                  ),");
      buffer.writeln("                )),");

    // ══════════════════════════════════════════════
    //  otp  ✅ FIXED: removed maxLength (not a param)
    // ══════════════════════════════════════════════
    } else if (type == 'otp') {
      buffer.writeln("                Column(");
      buffer.writeln(
          "                  crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                  children: [");
      buffer.writeln("                    Text(");
      buffer.writeln(
          "                      '$rawLabel${isRequired ? ' *' : ''}',");
      buffer.writeln(
          "                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),");
      buffer.writeln("                    ),");
      buffer.writeln("                    const SizedBox(height: 8),");
      buffer.writeln("                    CustomTextFormField(");
      buffer.writeln("                      label: '',");
      buffer.writeln("                      hint: '$hint',");
      buffer.writeln("                      isMandatory: $isRequired,");
      buffer.writeln(
          "                      controller: controller.${name}Controller,");
      buffer.writeln(
          "                      keyboardType: TextInputType.number,");
      buffer.writeln(
          "                      maxLines: 1,"); // ✅ maxLength removed
      buffer.writeln("                      validator: (value) {");
      buffer.writeln("                        try {");
      if (isRequired) {
        buffer.writeln(
            "                          if (value == null || value.isEmpty) return '$rawLabel is required';");
        buffer.writeln(
            "                          if (value.length != 6) return 'Enter a valid 6-digit code';");
      }
      buffer.writeln("                          return null;");
      buffer.writeln("                        } catch (e) {");
      buffer.writeln("                          return 'Invalid input';");
      buffer.writeln("                        }");
      buffer.writeln("                      },");
      buffer.writeln("                    ),");
      buffer.writeln("                  ],");
      buffer.writeln("                ),");

    // ══════════════════════════════════════════════
    //  divider
    // ══════════════════════════════════════════════
    } else if (type == 'divider') {
      buffer.writeln("                Padding(");
      buffer.writeln(
          "                  padding: const EdgeInsets.symmetric(vertical: 12.0),");
      buffer.writeln("                  child: Column(");
      buffer.writeln(
          "                    crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                    children: [");
      buffer.writeln("                      Text(");
      buffer.writeln("                        '$rawLabel',");
      buffer.writeln(
          "                        style: Theme.of(context).textTheme.bodyMedium,");
      buffer.writeln("                      ),");
      buffer.writeln("                      const SizedBox(height: 8),");
      buffer.writeln("                      const Divider(),");
      buffer.writeln("                    ],");
      buffer.writeln("                  ),");
      buffer.writeln("                ),");

    } else {
      buffer.writeln(
          "                // TODO: unsupported field type '$type' for '$rawLabel'");
    }

    buffer.writeln("                const SizedBox(height: 16),");
  }

  // ─── Submit button ────────────────────────────────────────────
  buffer.writeln("                const SizedBox(height: 20),");
  buffer.writeln("                Center(");
  buffer.writeln("                  child: ElevatedButton(");
  buffer.writeln("                    onPressed: () {");
  buffer.writeln(
      "                      if (formKey.currentState?.validate() ?? false) {");
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

// ─── Shared helper ────────────────────────────────────────────────
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
  buffer.writeln(
      "                  controller: controller.${name}Controller,");
  buffer.writeln(
      "                  keyboardType: TextInputType.$keyboardType,");
  buffer.writeln("                  isPassword: $isPassword,");
  buffer.writeln("                  isNumber: $isNumber,");
  buffer.writeln("                  readOnly: $isReadOnly,");
  buffer.writeln(
      "                  textInputAction: TextInputAction.$textInputAction,");
  buffer.writeln(
      "                  textCapitalization: TextCapitalization.$textCapitalization,");
  buffer.writeln("                  validator: (value) {");
  buffer.writeln("                    try {");
  if (isRequired) {
    buffer.writeln(
        "                      if (value == null || value.isEmpty) return '$label is required';");
  }
  if (minLength > 0) {
    buffer.writeln(
        "                      if (value != null && value.length < $minLength) return 'Minimum $minLength characters';");
  }
  if (maxLength > 0) {
    buffer.writeln(
        "                      if (value != null && value.length > $maxLength) return 'Maximum $maxLength characters';");
  }
  if (pattern.isNotEmpty) {
    buffer.writeln(
        "                      if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';");
  }
  buffer.writeln("                      return null;");
  buffer.writeln("                    } catch (e) {");
  buffer.writeln("                      return 'Invalid input';");
  buffer.writeln("                    }");
  buffer.writeln("                  },");
  buffer.writeln("                ),");
}

// ─── Maps JSON keyboardType → Flutter TextInputType ──────────────
String _mapKeyboardType(String raw) {
  switch (raw) {
    case 'number':
    case 'numeric':
      return 'number';
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