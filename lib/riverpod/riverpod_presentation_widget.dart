String generateriverpodviewWidgetClass(
  String className,
  List<Map<String, dynamic>> fields,
  String fileName,
) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:flutter/material.dart';");
  // buffer.writeln(
  //   "import '../controllers/${fileName.toLowerCase()}_controller.dart';",
  // );
  buffer.writeln("import '../../../utils/widget/common_text_form.dart';");
  buffer.writeln("import '../../../utils/widget/common_radiobutton.dart';");
  buffer.writeln("import '../../../utils/widget/common_dropdown_search.dart';");

  final dropdownModels = <String>{}; // ✅ Collect required dropdown model names

  void parseField(Map<String, dynamic> field) {
    final type = field['type'] ?? '';
    if (type == 'Dropdown') {
      final staticOpts = field['staticOptions'] as List<dynamic>?;
      // only add if there are NO staticOptions (i.e. we need a model)
      if (staticOpts == null || staticOpts.isEmpty) {
        final label = (field['label'] ?? '').toString().trim();
        dropdownModels.add(label);
      }
      // dropdownModels.add(label); // ✅ Add model name to set
    }
  }

  // ✅ Preprocess fields to collect model imports
  for (Map<String, dynamic> item in fields) {
    parseField(item);
  }

  // 2️⃣ Now import each model *once*
  for (final model in dropdownModels) {
    final fileName = model.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    buffer.writeln("import '../model/${fileName}_model.dart';");
  }

  for (var field in fields) {
    final fieldLabel = (field['label'] ?? 'Field').toString();
    final fieldName = fieldLabel.replaceAll(RegExp(r'\s+'), '');

    final controllerName = fieldName[0].toLowerCase() + fieldName.substring(1);
    final hint = field['hintText'] ?? '';
    final isRequired = field['required'] == true;
    final isPassword = field['obscureText'] ?? false;
    final isReadOnly = field['readOnly'] ?? false;
    final keyboardType = (field['keyboardType'] ?? 'text');
    final isNumber = keyboardType == 'number';
    final textInputAction = (field['textInputAction'] ?? 'done').toLowerCase();
    final textCapitalization =
        (field['textCapitalization'] ?? 'none').toLowerCase();
    final minLength = field['minLength'] ?? 0;
    final maxLength = field['maxLength'] ?? 0;
    final pattern = (field['validationPattern'] ?? '').toString().replaceAll(
      r'\',
      r'\\',
    );
    final errorMessage = field['errorMessage'] ?? 'Invalid format';
    final type = field['type'];
    // final name = capitalname.replaceAll(RegExp(r'\s+'), '');
    final labelnew = (field['label'] ?? '').toString().trim();
    // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final labelname = labelnew[0].toLowerCase() + labelnew.substring(1);
    final name = labelname.replaceAll(RegExp(r'\s+'), '');

    final capitalLabel = capitalize(name);

    if (type == 'TextField') {
      final widgetClassName = '$className${name.pascalCase}Widget';

      buffer.writeln('class $widgetClassName extends ConsumerWidget {');
      buffer.writeln('  const $widgetClassName({super.key});\n');

      buffer.writeln('  @override');
      buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');

      buffer.writeln('    return CustomTextFormField(');
      buffer.writeln("      label: '$fieldLabel',");

      if (hint != null && hint.isNotEmpty) {
        buffer.writeln("      hint: '$hint',");
      }

      if (isRequired) {
        buffer.writeln("      isMandatory: true,");
      }

      buffer.writeln("      controller: controller.${name}Controller,");
      if (keyboardType != "text") {
        buffer.writeln("      keyboardType: TextInputType.$keyboardType,");
      }
      if (isPassword) {
        buffer.writeln("      isPassword: true,");
      }

      if (isNumber) {
        buffer.writeln("      isNumber: true,");
      }

      if (isReadOnly) {
        buffer.writeln("      readOnly: true,");
      }
      if (textInputAction != "done") {
        buffer.writeln(
          "      textInputAction: TextInputAction.$textInputAction,",
        );
      }

      if (textCapitalization != "none") {
        buffer.writeln(
          "      textCapitalization: TextCapitalization.$textCapitalization,",
        );
      }
      // ✅ Generate validator only if required
      if (isRequired || minLength > 0 || maxLength > 0 || pattern.isNotEmpty) {
        buffer.writeln("      validator: (value) {");
        buffer.writeln("        try {");

        if (isRequired) {
          buffer.writeln(
            "          if (value == null || value.trim().isEmpty) return '$fieldLabel is required';",
          );
        }

        if (minLength > 0) {
          buffer.writeln(
            "          if (value != null && value.length < $minLength) return 'Minimum $minLength characters required';",
          );
        }

        if (maxLength > 0) {
          buffer.writeln(
            "          if (value != null && value.length > $maxLength) return 'Maximum $maxLength characters allowed';",
          );
        }

        if (pattern.isNotEmpty) {
          buffer.writeln(
            "          if (!RegExp(r'$pattern').hasMatch(value ?? '')) return '$errorMessage';",
          );
        }

        buffer.writeln("          return null;");
        buffer.writeln("        } catch (e) {");
        buffer.writeln("          return 'Invalid input';");
        buffer.writeln("        }");
        buffer.writeln("      },");
      }

      buffer.writeln("    );");
      buffer.writeln("  }");
      buffer.writeln("}");
    } else if (type == 'Date') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$fieldLabel',");
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
          "                      if (value == null || value.isEmpty) return '$fieldLabel is required';",
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
    } else if (type == 'Date Time') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$fieldLabel',");
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
          "                      if (value == null || value.isEmpty) return '$fieldLabel is required';",
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
    } else if (type == 'Dropdown') {
      var apidata = field['dropdowndata'];
      final label = (field['label'] ?? '').toString().trim()
      // .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '');
      final labelname = label[0].toLowerCase() + label.substring(1);
      final name = labelname.replaceAll(RegExp(r'\s+'), '');

      String? listdata;
      if (apidata is Map<String, dynamic>) {
        for (final entry in apidata.entries) {
          final key = entry.key;
          final value = entry.value;
          listdata = key;

          if (value is List &&
              value.isNotEmpty &&
              value.first is Map<String, dynamic>) {
            // dropdownmodel = capitalize(key);
            break;
          }
        }
      }
      // 2️⃣ now handle static vs dynamic
      final staticOpts = field['staticOptions'] as List<dynamic>?;

      if (staticOpts != null && staticOpts.isNotEmpty) {
        // build a Dart literal list from your staticOptions
        final literalItems = staticOpts
            .map((opt) {
              final k = (opt['key'] as String).replaceAll("'", "\\'");
              final v = (opt['value'] as String).replaceAll("'", "\\'");
              return "DropdownItem(key: '$k', value: '$v')";
            })
            .join(', ');

        buffer.writeln("""
      Obx(() => DropdownSearch<DropdownItem>(
        hint: '$fieldLabel',
        isMandatory: $isRequired,
        labelType: LabelType.top,
        itemAsString: (item) => item.value,
        // static list baked in:
        // items: <DropdownItem>[$literalItems],
        items: controller.${name}Options,
        value: controller.selected$capitalLabel.value,
        onChanged: (val) => controller.selected$capitalLabel.value = val,
      )),
    """);
      } else {
        buffer.writeln("""     Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              // Trigger API load
              ref.watch(productNameNotifierProvider);

              final ${name}List = ref.watch(${name}Provider);
              final selected$name = ref.watch(selected${name}Provider);
              final selected${name}Notifier = ref.read(
                selected${name}Provider.notifier,
              );

              final dropdownItems =
                  (${name}List.$listdata ?? [])
                      .map(
                        (product) => DropdownItem(
                          key: product.id.toString(),
                          value: product.title ?? 'Unnamed',
                        ),
                      )
                      .toList();

              final selectedItem = dropdownItems.firstWhereOrNull(
                (item) => item.key == selected$name?.id?.toString(),
              );
              return DropdownSearch<DropdownItem>(
                label: "$fieldLabel",
                hint: '$fieldLabel',
                isMandatory: $isRequired,
                labelType: LabelType.top,
                items: dropdownItems,
                value: selectedItem,
                itemAsString: (item) => item.value,
                      // ✅ Add validator if mandatory
     
                      validator: (value) {
       
                     if (value == null) return '$fieldLabel is required';
       
                        return null;
                        },
                onChanged: (selected) {
                  if (selected != null) {
                    final product = ${name}List.$listdata?.firstWhereOrNull(
                      (p) => p.id.toString() == selected.key,
                    );
              
                    selected${name}Notifier.state = product;
                  }
                },
              );
            },
          ),
     """);
      }
    } else if (type == 'Radio Buttons') {
      final capitalname = capitalLabel.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );

      buffer.writeln("                Obx(() => CustomRadioGroup<String>(");
      buffer.writeln("                  label: '$fieldLabel',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
        "                  selectedValue: controller.selected$capitalname.value,",
      );
      buffer.writeln(
        "                  onChanged: (value) => controller.selected$capitalname.value = value!,",
      );

      buffer.writeln(
        "                  options: controller.${controllerName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}Options,",
      );
      // ✅ Add validator if mandatory
      if (isRequired) {
        buffer.writeln("                  validator: (value) {");
        buffer.writeln(
          "                    if (value == null || value.isEmpty) return '$fieldLabel is required';",
        );
        buffer.writeln("                    return null;");
        buffer.writeln("                  },");
      }
      buffer.writeln("                )),");
    }
  }

  return buffer.toString();
}

String getType(dynamic value, String key) {
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is List) {
    if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      return 'List<${capitalize(key)}>';
    }
    return 'List<dynamic>';
  }
  if (value is Map<String, dynamic>) {
    return capitalize(key);
  }
  return 'dynamic';
}

extension StringCase on String {
  String get pascalCase => this[0].toUpperCase() + substring(1);
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
