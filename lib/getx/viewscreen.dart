String generateviewClass(
  String className,
  List<Map<String, dynamic>> fields,
  String fileName,
) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import 'package:get/get.dart';");
  buffer.writeln(
    "import '../controllers/${fileName.toLowerCase()}_controller.dart';",
  );
  buffer.writeln("import '../../../widget/common_text_form.dart';");
  buffer.writeln("import '../../../widget/common_radiobutton.dart';");
  buffer.writeln("import '../../../widget/common_dropdown_search.dart';");

  final dropdownModels = <String>{}; // ✅ Collect required dropdown model names

  // // ✅ Now write dynamic model imports
  // for (final model in dropdownModels) {
  //   buffer.writeln(
  //     "import '../model/${model.toLowerCase().toString().replaceAll(" ", "_")}_model.dart';",
  //   );
  // }
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

  buffer.writeln("class ${className}View extends StatelessWidget {");
  buffer.writeln("  const ${className}View({super.key});");

  buffer.writeln("  @override");
  buffer.writeln("  Widget build(BuildContext context) {");
  buffer.writeln("    final controller = Get.find<${className}Controller>();");
  buffer.writeln("    final _formKey = GlobalKey<FormState>();");

  buffer.writeln("    return Scaffold(");
  buffer.writeln("      appBar: AppBar(title: Text('$className Form')),");

  buffer.writeln("      body: Padding(");
  buffer.writeln("        padding: const EdgeInsets.all(16.0),");
  buffer.writeln("        child: Form(");
  buffer.writeln("          key: _formKey,");
  buffer.writeln(
    "          autovalidateMode: AutovalidateMode.onUserInteraction,",
  );
  buffer.writeln("          child: SingleChildScrollView(");
  buffer.writeln("            child: Column(");
  buffer.writeln("              crossAxisAlignment: CrossAxisAlignment.start,");
  buffer.writeln("              children: [");

  for (var field in fields) {
    final fieldLabel = (field['label'] ?? 'Field').toString();
    final fieldName = fieldLabel.replaceAll(RegExp(r'\s+'), '');
    // final capitalLabel = capitalize(label);

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


    // // final name = capitalname.replaceAll(RegExp(r'\s+'), '');
    // final labelnew = (field['label'] ?? '').toString().trim();
    // // final name = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    // final labelname = labelnew[0].toLowerCase() + labelnew.substring(1);
    // final name = labelname.replaceAll(RegExp(r'\s+'), '');

    // final capitalLabel = capitalize(name);
    final rawLabel = (field['label'] ?? '').toString().trim();
    final name = camelCaseName(rawLabel);
    final capitalLabel = pascalCaseName(rawLabel);

    if (type == 'TextField') {
      buffer.writeln("                CustomTextFormField(");
      buffer.writeln("                  label: '$fieldLabel',");
      buffer.writeln("                  hint: '$hint',");
      buffer.writeln("                  isMandatory: $isRequired,");
      buffer.writeln(
        "                  controller: controller.${name}Controller,",
      );
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
      buffer.writeln("                  validator: (value) {");
      buffer.writeln("                    try {");

      if (isRequired) {
        buffer.writeln(
          "                      if (value == null || value.isEmpty) return '$fieldLabel is required';",
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

      String? dropdownmodel;
      // apidata.forEach((key, value) {
      //   String type = getType(value, key);
      //   print('  final123 $type? $key');
      //   if (value is List) {
      //     if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      //       dropdownmodel = capitalize(key);

      //       return 'List<${capitalize(key)}>';
      //     }
      //   }
      // });
      if (apidata is Map<String, dynamic>) {
        for (final entry in apidata.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List &&
              value.isNotEmpty &&
              value.first is Map<String, dynamic>) {
            dropdownmodel = capitalize(key);
            break;
          }
        }
      }
      // 2️⃣ now handle static vs dynamic
      final staticOpts = field['staticOptions'] as List<dynamic>?;
      if (staticOpts != null && staticOpts.isNotEmpty) {

        buffer.writeln("""
  Obx(() => DropdownSearch<DropdownItem>(
    hint: '$fieldLabel',
    label:'$fieldLabel',
    
    isMandatory: $isRequired,
    labelType: LabelType.top,
    itemAsString: (item) => item.value,
    items: controller.${name}Options,
    value: controller.selected$capitalLabel.value,
    onChanged: (val) => controller.selected$capitalLabel.value = val,
    ${isRequired ? """
    validator: (value) {
      if (value == null) return '$fieldLabel is required';
      return null;
    },""" : ""}
  )),
""");
      } else {
        final dropdownKey = field['dropdownValue'] ?? 'name';

        buffer.writeln("""
  Obx(() => DropdownSearch<$dropdownmodel>(
    hint: '$fieldLabel',
    label:'$fieldLabel',
    isMandatory: $isRequired,
    labelType: LabelType.top,
    itemAsString: (item) => item?.$dropdownKey ?? '',
    items: controller.${name}Options,
    value: controller.selected$capitalLabel.value,
    onChanged: (val) => controller.selected$capitalLabel.value = val,
    ${isRequired ? """
    validator: (value) {
      if (value == null) return '$fieldLabel is required';
      return null;
    },""" : ""}
  )),
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

    buffer.writeln("                SizedBox(height: 16),");
  }

  buffer.writeln("                SizedBox(height: 20),");
  buffer.writeln("                Center(");
  buffer.writeln("                  child: ElevatedButton(");
  buffer.writeln("                    onPressed: () {");
  buffer.writeln(
    "                      if (_formKey.currentState?.validate() ?? false) {",
  );
  buffer.writeln("                        // TODO: Submit logic");
  buffer.writeln("                      }");
  buffer.writeln("                    },");
  buffer.writeln("                    child: Text('Submit'),");
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

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// 🔹 Helpers
String normalizeLabel(String label) =>
    label.trim().replaceAll(RegExp(r'\s+'), '');

String camelCaseName(String label) {
  final normalized = normalizeLabel(label);
  return normalized.isEmpty
      ? ''
      : normalized[0].toLowerCase() + normalized.substring(1);
}



String pascalCaseName(String label) {
  final normalized = normalizeLabel(label);
  return normalized.isEmpty
      ? ''
      : normalized[0].toUpperCase() + normalized.substring(1);
}
