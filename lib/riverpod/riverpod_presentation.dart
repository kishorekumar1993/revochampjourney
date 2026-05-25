String generateriverpodviewClass(
  String className,
  List<dynamic> configList,
  String fileName,
) {
  final buffer = StringBuffer();

// ─── Shared helpers ───────────────────────────────────────────────
String camel(String label) {
  final n = label.trim().replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? '' : n[0].toLowerCase() + n.substring(1);
}

String pascal(String label) {
  final n = label.trim().replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? '' : n[0].toUpperCase() + n.substring(1);
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

String mapKeyboardType(String raw) {
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
  // ─── Recursive flatten ─────────────────────────────────────────
  void flattenFields(dynamic source, List<Map<String, dynamic>> result) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) flattenFields(item, result);
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

  // ✅ FIX 1: flattenFields instead of raw fields loop
  final flatFields = <Map<String, dynamic>>[];
  flattenFields(configList, flatFields);

  // ─── Collect API dropdown model imports ───────────────────────
  // ✅ FIX 2: label first, lowercase type, isApiDropdown guard
  final dropdownModels = <String>{};
  final entityImports = <String>{};

  for (final field in flatFields) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type == 'dropdown' || type == 'api_dropdown') {
      final useStatic = field['useStaticOptions'] == true;
      final hasApiUrl = field['dropdownApiUrl'] != null;
      final staticOpts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?);
      if (!useStatic && hasApiUrl) {
        final label =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();
        dropdownModels.add(label);
        entityImports.add(label);
      } else if (!useStatic && (staticOpts == null || staticOpts.isEmpty)) {
        final label =
            (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'model')
                .toString()
                .trim();
        dropdownModels.add(label);
      }
    }
  }

  // ─── Imports ──────────────────────────────────────────────────
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
  buffer.writeln("import 'package:collection/collection.dart';");
  buffer.writeln("import '../../../utils/widget/common_text_form.dart';");
  buffer.writeln("import '../../../utils/widget/common_radiobutton.dart';");
  buffer.writeln(
      "import '../../../utils/widget/common_dropdown_search.dart';");
  buffer.writeln(
      "import '../provider/${fileName.toLowerCase().replaceAll(' ', '_')}_provider.dart';");

  // ✅ FIX 3: entity imports from flatFields scan
  for (final model in dropdownModels) {
    final modelFile = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../model/${modelFile}_model.dart';");
  }
  buffer.writeln();

  // ─── Screen class ─────────────────────────────────────────────
  buffer.writeln(
      "class ${className}Screen extends ConsumerStatefulWidget {");
  buffer.writeln("  const ${className}Screen({super.key});");
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln(
      "  ${className}ScreenState createState() => ${className}ScreenState();");
  buffer.writeln("}");
  buffer.writeln();
  buffer.writeln(
      "class ${className}ScreenState extends ConsumerState<${className}Screen> {");
  buffer.writeln("  final _formKey = GlobalKey<FormState>();");
  buffer.writeln();

  // ─── TextEditingController declarations ───────────────────────
  // ✅ FIX 4: iterate flatFields, lowercase type check
  for (final item in flatFields) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;

    final name = camel(rawLabel);
    final capitalLabel = pascal(rawLabel);

    switch (type) {
      case 'text':
      case 'textfield':
      case 'textarea':
      case 'email':
      case 'password':
      case 'phone':
      case 'otp':
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
        buffer.writeln(
            "  final ${name}Controller = TextEditingController();");
        break;

      case 'checkbox':
        buffer.writeln("  bool is${capitalLabel}Checked = false;");
        break;

      case 'radio':
      case 'radio buttons':
        final staticOptions =
            (item['staticOptions'] as List<dynamic>?) ?? [];
        final formattedOptions = staticOptions.map((e) {
          if (e is Map) {
            final k = (e['key'] ?? e['value'] ?? '')
                .toString()
                .replaceAll("'", "\\'");
            final v = (e['value'] ?? e['label'] ?? '')
                .toString()
                .replaceAll("'", "\\'");
            return "RadioOption<String>(value: '$k', label: '$v')";
          }
          final val = e.toString().replaceAll("'", "\\'");
          return "RadioOption<String>(value: '$val', label: '$val')";
        }).join(', ');
        buffer.writeln(
            "  String? selected$capitalLabel;");
        buffer.writeln(
            "  final List<RadioOption<String>> ${name}Options = [$formattedOptions];");
        break;
    }
  }

  // ─── dispose ──────────────────────────────────────────────────
  buffer.writeln();
  buffer.writeln("  @override");
  buffer.writeln("  void dispose() {");
  for (final item in flatFields) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final rawLabel =
        (item['label'] ?? item['id'] ?? item['fieldId'] ?? '')
            .toString()
            .trim();
    if (rawLabel.isEmpty) continue;
    final name = camel(rawLabel);

    switch (type) {
      case 'text':
      case 'textfield':
      case 'textarea':
      case 'email':
      case 'password':
      case 'phone':
      case 'otp':
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
    }
  }
  buffer.writeln("    super.dispose();");
  buffer.writeln("  }");
  buffer.writeln();

  // ─── build ────────────────────────────────────────────────────
  buffer.writeln("  @override");
  buffer.writeln("  Widget build(BuildContext context) {");
  buffer.writeln("    return Scaffold(");
  buffer.writeln(
      "      appBar: AppBar(title: const Text('$className Form')),");
  buffer.writeln("      body: Padding(");
  buffer.writeln("        padding: const EdgeInsets.all(16.0),");
  buffer.writeln("        child: Form(");
  buffer.writeln("          key: _formKey,");
  buffer.writeln(
      "          autovalidateMode: AutovalidateMode.onUserInteraction,");
  buffer.writeln("          child: SingleChildScrollView(");
  buffer.writeln("            child: Column(");
  buffer.writeln(
      "              crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("              children: [");

  // ─── Field widgets ────────────────────────────────────────────
  // ✅ FIX 5: iterate flatFields, full type coverage, isApiDropdown guard
  for (final field in flatFields) {
    final rawLabel =
        (field['label'] ?? field['id'] ?? field['fieldId'] ?? 'Field')
            .toString()
            .trim();
    final name = camel(rawLabel);
    final capitalLabel = pascal(rawLabel);
    final type = (field['type'] ?? '').toString().toLowerCase().trim();
    final hint = (field['placeholder'] ?? field['hintText'] ?? '').toString();
    final isRequired = field['required'] == true;
    final isPassword = field['obscureText'] == true;
    final isReadOnly = field['readOnly'] == true;
    final rawKeyboard =
        (field['keyboardType'] ?? 'text').toString().toLowerCase();
    final keyboardType = mapKeyboardType(rawKeyboard);
    final isNumber = rawKeyboard == 'number';
    final textInputAction =
        (field['textInputAction'] ?? 'done').toString().toLowerCase();
    final textCapitalization =
        (field['textCapitalization'] ?? 'none').toString().toLowerCase();
    final minLength =
        int.tryParse(field['minLength']?.toString() ?? '') ?? 0;
    final maxLength =
        int.tryParse(field['maxLength']?.toString() ?? '') ?? 0;
    final pattern = (field['validationPattern'] ?? '')
        .toString()
        .replaceAll(r'\', r'\\');
    final errorMessage =
        (field['errorMessage'] ?? 'Invalid format').toString();

    // ✅ isApiDropdown guard
    final useStatic = field['useStaticOptions'] == true;
    final hasApiUrl = field['dropdownApiUrl'] != null;
    final staticOpts = (field['options'] as List<dynamic>?) ??
        (field['staticOptions'] as List<dynamic>?);
    final isApiDropdown =
        (type == 'dropdown' || type == 'api_dropdown') &&
            !useStatic &&
            hasApiUrl;

    // ── text / textfield / email / password / phone / number ────
    if (type == 'text' ||
        type == 'textfield' ||
        type == 'email' ||
        type == 'password' ||
        type == 'phone' ||
        type == 'otp' ||
        type == 'number' ||
        type == 'integer' ||
        type == 'int' ||
        type == 'decimal' ||
        type == 'double' ||
        type == 'float') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      if (hint.isNotEmpty) buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
          "                  controller: ${name}Controller,");
      buffer.writeln(
          "                  keyboardType: TextInputType.$keyboardType,");
      if (isPassword) buffer.writeln("                  isPassword: true,");
      if (isNumber) buffer.writeln("                  isNumber: true,");
      if (isReadOnly) buffer.writeln("                  readOnly: true,");
      if (textInputAction != 'done') {
        buffer.writeln(
            "                  textInputAction: TextInputAction.$textInputAction,");
      }
      if (textCapitalization != 'none') {
        buffer.writeln(
            "                  textCapitalization: TextCapitalization.$textCapitalization,");
      }
      if (maxLength > 0) {
        buffer.writeln("                  maxLength: $maxLength,");
      }
      if (isRequired || minLength > 0 || maxLength > 0 || pattern.isNotEmpty) {
        buffer.writeln("                  validator: (value) {");
        buffer.writeln("                    try {");
        if (isRequired) {
          buffer.writeln(
              "                      if (value == null || value.trim().isEmpty) return '$rawLabel is required';");
        }
        if (minLength > 0) {
          buffer.writeln(
              "                      if (value != null && value.length < $minLength) return 'Minimum $minLength characters required';");
        }
        if (maxLength > 0) {
          buffer.writeln(
              "                      if (value != null && value.length > $maxLength) return 'Maximum $maxLength characters allowed';");
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
      }
      buffer.writeln("                ),");

      // ── textarea ──────────────────────────────────────────────
    } else if (type == 'textarea') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln("                  controller: ${name}Controller,");
      buffer.writeln("                  maxLines: 4,");
      buffer.writeln(
          "                  keyboardType: TextInputType.multiline,");
      buffer.writeln(
          "                  textInputAction: TextInputAction.newline,");
      if (maxLength > 0) {
        buffer.writeln("                  maxLength: $maxLength,");
      }
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

      // ── date / datetime / time ────────────────────────────────
    } else if (type == 'date' ||
        type == 'datetime' ||
        type == 'date time' ||
        type == 'time') {
      final pickerProp = type == 'time'
          ? 'isTimePicker'
          : type == 'date'
              ? 'isDatePicker'
              : 'isDateTimePicker';
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$rawLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln("                  controller: ${name}Controller,");
      buffer.writeln("                  $pickerProp: true,");
      buffer.writeln("                  readOnly: $isReadOnly,");
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

      // ── dropdown ──────────────────────────────────────────────
      // ✅ FIX 6: isApiDropdown checked FIRST
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (isApiDropdown) {
        // ── API dropdown with Riverpod Consumer ───────────────
        final dropdowndata = field['dropdowndata'];
        String listKey = 'data';
        String entityClass = '${capitalLabel}Model';

        if (dropdowndata is Map<String, dynamic>) {
          for (final entry in dropdowndata.entries) {
            final v = entry.value;
            if (v is List &&
                v.isNotEmpty &&
                v.first is Map<String, dynamic>) {
              listKey = entry.key;
              entityClass =
                  '${capitalize(singularize(entry.key))}Model';
              break;
            }
          }
        }

        final dropdownValue =
            (field['dropdownValue'] ?? 'title').toString();
        final lower = camel(rawLabel);

        buffer.writeln("                Consumer(");
        buffer.writeln(
            "                  builder: (context, ref, child) {");
        buffer.writeln(
            "                    final ${lower}Items = ref.watch(${lower}DropdownProvider);");
        buffer.writeln(
            "                    final selected$capitalLabel = ref.watch(selected${capitalLabel}Provider);");
        buffer.writeln();
        buffer.writeln(
            "                    return DropdownSearch<$entityClass>(");
        buffer.writeln("                      label: '$rawLabel',");
        buffer.writeln("                      hint: '$hint',");
        buffer.writeln("                      isMandatory: $isRequired,");
        buffer.writeln("                      labelType: LabelType.top,");
        buffer.writeln(
            "                      items: ${lower}Items,");
        buffer.writeln(
            "                      value: selected$capitalLabel,");
        buffer.writeln(
            "                      itemAsString: (item) => item.$dropdownValue?.toString() ?? '',");
        if (isRequired) {
          buffer.writeln("                      validator: (value) {");
          buffer.writeln(
              "                        if (value == null) return '$rawLabel is required';");
          buffer.writeln("                        return null;");
          buffer.writeln("                      },");
        }
        buffer.writeln("                      onChanged: (selected) {");
        buffer.writeln(
            "                        ref.read(selected${capitalLabel}Provider.notifier).select(selected!);");
        buffer.writeln("                      },");
        buffer.writeln("                    );");
        buffer.writeln("                  },");
        buffer.writeln("                ),");
      } else if (staticOpts != null && staticOpts.isNotEmpty) {
        // ── Static dropdown ───────────────────────────────────
        final literalItems = staticOpts.map((opt) {
          if (opt is Map) {
            final k = (opt['key'] ?? opt['value'] ?? '')
                .toString()
                .replaceAll("'", "\\'");
            final v = (opt['value'] ?? opt['label'] ?? '')
                .toString()
                .replaceAll("'", "\\'");
            return "DropdownItem(key: '$k', value: '$v')";
          }
          final val = opt.toString().replaceAll("'", "\\'");
          return "DropdownItem(key: '$val', value: '$val')";
        }).join(', ');

        buffer.writeln("                Consumer(");
        buffer.writeln(
            "                  builder: (context, ref, child) {");
        buffer.writeln(
            "                    final selected$capitalLabel = ref.watch(selected${capitalLabel}Provider);");
        buffer.writeln(
            "                    return DropdownSearch<DropdownItem>(");
        buffer.writeln("                      label: '$rawLabel',");
        buffer.writeln("                      hint: '$hint',");
        buffer.writeln("                      isMandatory: $isRequired,");
        buffer.writeln("                      labelType: LabelType.top,");
        buffer.writeln(
            "                      itemAsString: (item) => item.value,");
        buffer.writeln(
            "                      items: const [$literalItems],");
        buffer.writeln(
            "                      value: selected$capitalLabel,");
        buffer.writeln(
            "                      onChanged: (val) => ref.read(selected${capitalLabel}Provider.notifier).select(val!),");
        if (isRequired) {
          buffer.writeln("                      validator: (value) {");
          buffer.writeln(
              "                        if (value == null) return '$rawLabel is required';");
          buffer.writeln("                        return null;");
          buffer.writeln("                      },");
        }
        buffer.writeln("                    );");
        buffer.writeln("                  },");
        buffer.writeln("                ),");
      }

      // ── radio ──────────────────────────────────────────────────
    } else if (type == 'radio' || type == 'radio buttons') {
      buffer.writeln("                Consumer(");
      buffer.writeln("                  builder: (context, ref, child) {");
      buffer.writeln(
          "                    final selected$capitalLabel = ref.watch(selected${capitalLabel}Provider);");
      buffer.writeln(
          "                    return CustomRadioGroup<String>(");
      buffer.writeln("                      label: '$rawLabel',");
      buffer.writeln("                      isMandatory: $isRequired,");
      buffer.writeln(
          "                      selectedValue: selected$capitalLabel,");
      buffer.writeln(
          "                      onChanged: (value) => ref.read(selected${capitalLabel}Provider.notifier).set(value ?? ''),");
      buffer.writeln(
          "                      options: ${name}Options,");
      if (isRequired) {
        buffer.writeln("                      validator: (value) {");
        buffer.writeln(
            "                        if (value == null || value.isEmpty) return '$rawLabel is required';");
        buffer.writeln("                        return null;");
        buffer.writeln("                      },");
      }
      buffer.writeln("                    );");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

      // ── checkbox ───────────────────────────────────────────────
    } else if (type == 'checkbox') {
      buffer.writeln("                Consumer(");
      buffer.writeln("                  builder: (context, ref, child) {");
      buffer.writeln(
          "                    final ${name}Value = ref.watch(${name}Provider);");
      buffer.writeln("                    return CheckboxListTile(");
      buffer.writeln(
          "                      title: Text('$rawLabel${isRequired ? ' *' : ''}'),");
      buffer.writeln(
          "                      value: ${name}Value,");
      buffer.writeln("                      onChanged: (val) {");
      buffer.writeln(
          "                        ref.read(${name}Provider.notifier).set(val ?? false);");
      buffer.writeln("                      },");
      buffer.writeln(
          "                      contentPadding: EdgeInsets.zero,");
      buffer.writeln(
          "                      controlAffinity: ListTileControlAffinity.leading,");
      buffer.writeln("                    );");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

      // ── switch ──────────────────────────────────────────────────
    } else if (type == 'switch') {
      buffer.writeln("                Consumer(");
      buffer.writeln("                  builder: (context, ref, child) {");
      buffer.writeln(
          "                    final ${name}Value = ref.watch(${name}Provider);");
      buffer.writeln("                    return SwitchListTile(");
      buffer.writeln("                      title: Text('$rawLabel'),");
      buffer.writeln(
          "                      value: ${name}Value,");
      buffer.writeln(
          "                      onChanged: (val) => ref.read(${name}Provider.notifier).set(val),");
      buffer.writeln(
          "                      contentPadding: EdgeInsets.zero,");
      buffer.writeln("                    );");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

      // ── slider ─────────────────────────────────────────────────
    } else if (type == 'slider' || type == 'range slider') {
      final minVal =
          (field['minValue'] ?? field['min'] as num?)?.toDouble() ?? 0.0;
      final maxVal =
          (field['maxValue'] ?? field['max'] as num?)?.toDouble() ?? 100.0;
      buffer.writeln("                Consumer(");
      buffer.writeln("                  builder: (context, ref, child) {");
      buffer.writeln(
          "                    final ${name}Value = ref.watch(${name}Provider);");
      buffer.writeln("                    return Column(");
      buffer.writeln(
          "                      crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                      children: [");
      buffer.writeln("                        Row(");
      buffer.writeln(
          "                          mainAxisAlignment: MainAxisAlignment.spaceBetween,");
      buffer.writeln("                          children: [");
      buffer.writeln(
          "                            Text('$rawLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),");
      buffer.writeln(
          "                            Text('\$${name}Value', style: const TextStyle(fontWeight: FontWeight.bold)),");
      buffer.writeln("                          ],");
      buffer.writeln("                        ),");
      buffer.writeln("                        Slider(");
      buffer.writeln(
          "                          value: ${name}Value.toDouble(),");
      buffer.writeln("                          min: $minVal,");
      buffer.writeln("                          max: $maxVal,");
      buffer.writeln(
          "                          onChanged: (val) => ref.read(${name}Provider.notifier).set(val),");
      buffer.writeln("                        ),");
      buffer.writeln("                      ],");
      buffer.writeln("                    );");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

      // ── multiselect ────────────────────────────────────────────
    } else if (type == 'multiselect' ||
        type == 'multi select' ||
        type == 'multi_select') {
      final opts = (field['options'] as List<dynamic>?) ??
          (field['staticOptions'] as List<dynamic>?) ??
          [];
      final optLiterals = opts.map((o) {
        final val = o.toString().replaceAll("'", "\\'");
        return "'$val'";
      }).join(', ');

      buffer.writeln("                Consumer(");
      buffer.writeln("                  builder: (context, ref, child) {");
      buffer.writeln(
          "                    final ${name}Selected = ref.watch(${name}Provider);");
      buffer.writeln("                    return Column(");
      buffer.writeln(
          "                      crossAxisAlignment: CrossAxisAlignment.start,");
      buffer.writeln("                      children: [");
      buffer.writeln(
          "                        Text('$rawLabel${isRequired ? ' *' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),");
      buffer.writeln("                        const SizedBox(height: 8),");
      buffer.writeln(
          "                        ...[$optLiterals].map((option) => CheckboxListTile(");
      buffer.writeln("                          title: Text(option),");
      buffer.writeln(
          "                          value: ${name}Selected.contains(option),");
      buffer.writeln("                          onChanged: (val) {");
      buffer.writeln(
          "                            ref.read(${name}Provider.notifier).toggle(option);");
      buffer.writeln("                          },");
      buffer.writeln(
          "                          contentPadding: EdgeInsets.zero,");
      buffer.writeln(
          "                          controlAffinity: ListTileControlAffinity.leading,");
      buffer.writeln("                        )).toList(),");
      buffer.writeln("                      ],");
      buffer.writeln("                    );");
      buffer.writeln("                  },");
      buffer.writeln("                ),");

      // ── layout types — skip ────────────────────────────────────
    } else if ([
      'label',
      'divider',
      'section',
      'card',
      'tabs',
      'accordion',
      'hidden',
      'row'
    ].contains(type)) {
      continue;
    } else {
      buffer.writeln(
          "                // TODO: unsupported type '$type' for '$rawLabel'");
    }

    buffer.writeln("                const SizedBox(height: 16),");
  }

  // ─── Submit button ────────────────────────────────────────────
  buffer.writeln("                const SizedBox(height: 20),");
  buffer.writeln("                Center(");
  buffer.writeln("                  child: ElevatedButton(");
  buffer.writeln("                    onPressed: () {");
  buffer.writeln(
      "                      if (_formKey.currentState?.validate() ?? false) {");
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