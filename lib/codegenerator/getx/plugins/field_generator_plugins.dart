import 'package:revojourneytryone/codegenerator/getx/getx_model_naming.dart';

abstract class FieldGeneratorPlugin {
  bool matches(String type);
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  );

  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  );
}

// Helper for AppTextField generation
void writeTextFormFieldHelper(
  StringBuffer buffer, {
  required String label,
  required String name,
  required String hint,
  required bool isPassword,
  required bool isReadOnly,
  required String keyboardType,
  required String textInputAction,
  required String textCapitalization,
  required String errorRef,
  String? inputFormatters,
  int? maxLength,
  int? maxLines,
  int? minLines,
}) {
  buffer.writeln("                  AppTextField(");
  buffer.writeln("                    label: '$label',");
  buffer.writeln("                    hint: '$hint',");
  buffer.writeln("                    controller: controller.${name}Controller,");
  buffer.writeln("                    keyboardType: TextInputType.$keyboardType,");
  buffer.writeln("                    obscureText: $isPassword,");
  buffer.writeln("                    readOnly: $isReadOnly,");
  buffer.writeln("                    textInputAction: TextInputAction.$textInputAction,");
  buffer.writeln("                    textCapitalization: TextCapitalization.$textCapitalization,");
  if (maxLength != null && maxLength > 0) {
    buffer.writeln("                    maxLength: $maxLength,");
  }
  if (maxLines != null) {
    buffer.writeln("                    maxLines: $maxLines,");
  }
  if (minLines != null) {
    buffer.writeln("                    minLines: $minLines,");
  }
  if (inputFormatters != null) {
    buffer.writeln("                    inputFormatters: [$inputFormatters],");
  }
  buffer.writeln("                    errorText: $errorRef,");
  buffer.writeln("                  );");
}

class TextFieldPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return [
      'text', 'textfield', 'phone', 'email', 'password', 'textarea',
      'number', 'integer', 'int', 'decimal', 'double', 'float', 'otp'
    ].contains(type);
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final type = (field['type'] ?? '').toString().toLowerCase().trim();

    if (type == 'phone') {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'phone',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
        inputFormatters: 'FilteringTextInputFormatter.digitsOnly',
      );
    } else if (type == 'email') {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'emailAddress',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
      );
    } else if (type == 'password') {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: true,
        isReadOnly: isReadOnly,
        keyboardType: 'text',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
      );
    } else if (type == 'textarea') {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'multiline',
        textInputAction: 'newline',
        textCapitalization: 'sentences',
        errorRef: errorRef,
        maxLines: 4,
        minLines: 3,
      );
    } else if (['number', 'integer', 'int'].contains(type)) {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'number',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
      );
    } else if (['decimal', 'double', 'float'].contains(type)) {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'decimalPad',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
      );
    } else if (type == 'otp') {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: false,
        isReadOnly: isReadOnly,
        keyboardType: 'number',
        textInputAction: textInputAction,
        textCapitalization: 'none',
        errorRef: errorRef,
        maxLength: maxLength > 0 ? maxLength : 6,
      );
    } else {
      writeTextFormFieldHelper(
        buffer,
        label: rawLabel,
        name: name,
        hint: hint,
        isPassword: isPassword,
        isReadOnly: isReadOnly,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        errorRef: errorRef,
      );
    }
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Controller.text;");
    buffer.writeln("                if (val.isEmpty) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val);");
    buffer.writeln("              }),");
  }
}

class DatePickerPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'date';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  AppDatePickerField(");
    buffer.writeln("                    label: '$rawLabel',");
    buffer.writeln("                    hint: '${hint.isNotEmpty ? hint : 'Select date'}',");
    buffer.writeln("                    value: controller.${name}Controller.value,");
    buffer.writeln("                    errorText: $errorRef,");
    buffer.writeln("                    enabled: ${!isReadOnly},");
    buffer.writeln("                    onChanged: (picked) {");
    buffer.writeln("                      if (picked != null) {");
    buffer.writeln("                        controller.${name}Controller.value = picked;");
    buffer.writeln("                      }");
    buffer.writeln("                    },");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Controller.value;");
    buffer.writeln("                if (val == null) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', '\${val.year}-\${val.month.toString().padLeft(2, '0')}-\${val.day.toString().padLeft(2, '0')}');");
    buffer.writeln("              }),");
  }
}

class DateTimePickerPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'datetime' || type == 'date time';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  GestureDetector(");
    buffer.writeln("                    onTap: ${isReadOnly ? 'null' : '() async {'}");
    if (!isReadOnly) {
      buffer.writeln("                      final date = await showDatePicker(");
      buffer.writeln("                        context: context,");
      buffer.writeln("                        initialDate: controller.${name}Controller.value ?? DateTime.now(),");
      buffer.writeln("                        firstDate: DateTime(1900),");
      buffer.writeln("                        lastDate: DateTime(2100),");
      buffer.writeln("                      );");
      buffer.writeln("                      if (date == null) return;");
      buffer.writeln("                      final time = await showTimePicker(");
      buffer.writeln("                        context: context,");
      buffer.writeln("                        initialTime: controller.${name}Controller.value != null");
      buffer.writeln("                            ? TimeOfDay.fromDateTime(controller.${name}Controller.value!)");
      buffer.writeln("                            : TimeOfDay.now(),");
      buffer.writeln("                      );");
      buffer.writeln("                      if (time == null) return;");
      buffer.writeln("                      controller.${name}Controller.value = DateTime(");
      buffer.writeln("                        date.year,");
      buffer.writeln("                        date.month,");
      buffer.writeln("                        date.day,");
      buffer.writeln("                        time.hour,");
      buffer.writeln("                        time.minute,");
      buffer.writeln("                      );");
      buffer.writeln("                    },");
    }
    buffer.writeln("                    child: AbsorbPointer(");
    buffer.writeln("                      child: InputDecorator(");
    buffer.writeln("                        decoration: InputDecoration(");
    buffer.writeln("                          labelText: '$rawLabel',");
    buffer.writeln("                          hintText: '${hint.isNotEmpty ? hint : 'Select date and time'}',");
    buffer.writeln("                          errorText: $errorRef,");
    buffer.writeln("                          suffixIcon: const Icon(Icons.calendar_month_rounded),");
    buffer.writeln("                        ),");
    buffer.writeln("                        child: Text(controller.${name}Controller.value != null ? _formatDateTime(controller.${name}Controller.value!) : '', style: theme.textTheme.bodyLarge),");
    buffer.writeln("                      ),");
    buffer.writeln("                    ),");
    buffer.writeln("                  );");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Controller.value;");
    buffer.writeln("                if (val == null) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', '\${val.year}-\${val.month.toString().padLeft(2, '0')}-\${val.day.toString().padLeft(2, '0')}');");
    buffer.writeln("              }),");
  }
}

class TimePickerPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'time';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  GestureDetector(");
    buffer.writeln("                    onTap: ${isReadOnly ? 'null' : '() async {'}");
    if (!isReadOnly) {
      buffer.writeln("                      final picked = await showTimePicker(");
      buffer.writeln("                        context: context,");
      buffer.writeln("                        initialTime: controller.${name}Controller.value ?? TimeOfDay.now(),");
      buffer.writeln("                      );");
      buffer.writeln("                      if (picked != null) {");
      buffer.writeln("                        controller.${name}Controller.value = picked;");
      buffer.writeln("                      }");
      buffer.writeln("                    },");
    }
    buffer.writeln("                    child: AbsorbPointer(");
    buffer.writeln("                      child: InputDecorator(");
    buffer.writeln("                        decoration: InputDecoration(");
    buffer.writeln("                          labelText: '$rawLabel',");
    buffer.writeln("                          hintText: '${hint.isNotEmpty ? hint : 'Select time'}',");
    buffer.writeln("                          errorText: $errorRef,");
    buffer.writeln("                          suffixIcon: const Icon(Icons.access_time_rounded),");
    buffer.writeln("                        ),");
    buffer.writeln("                        child: Text(controller.${name}Controller.value?.format(context) ?? '', style: theme.textTheme.bodyLarge),");
    buffer.writeln("                      ),");
    buffer.writeln("                    ),");
    buffer.writeln("                  );");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Controller.value;");
    buffer.writeln("                if (val == null) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', '\${val.hour.toString().padLeft(2, '0')}:\${val.minute.toString().padLeft(2, '0')}');");
    buffer.writeln("              }),");
  }
}

class DropdownPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'dropdown' || type == 'api_dropdown';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final useStatic = field['useStaticOptions'] == true;
    final isApiDropdown = !useStatic && field['dropdownApiUrl'] != null;

    if (isApiDropdown) {
      final dropdownmodel = resolveGetxModelClassName(field);
      final dropdownKey = (field['dropdownValue'] ?? 'title').toString();
      buffer.writeln("                  AppDropdownField<$dropdownmodel>(");
      buffer.writeln("                    label: '$rawLabel',");
      buffer.writeln("                    hint: '$hint',");
      buffer.writeln("                    itemLabelBuilder: (item) => item.$dropdownKey?.toString() ?? '',");
      buffer.writeln("                    items: controller.${name}Options.value,");
      buffer.writeln("                    value: controller.selected$capitalLabel.value,");
      buffer.writeln("                    onChanged: (val) => controller.selected$capitalLabel.value = val,");
      buffer.writeln("                    errorText: $errorRef,");
      buffer.writeln("                  ),");
    } else {
      buffer.writeln("                  AppDropdownField<DropdownItem>(");
      buffer.writeln("                    label: '$rawLabel',");
      buffer.writeln("                    hint: '$hint',");
      buffer.writeln("                    itemLabelBuilder: (item) => item.value,");
      buffer.writeln("                    items: controller.${name}Options,");
      buffer.writeln("                    value: controller.selected$capitalLabel.value,");
      buffer.writeln("                    onChanged: (val) => controller.selected$capitalLabel.value = val,");
      buffer.writeln("                    errorText: $errorRef,");
      buffer.writeln("                  ),");
    }
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    final useStatic = field['useStaticOptions'] == true;
    final isApiDropdown = field['dropdownApiUrl'] != null && !useStatic;

    buffer.writeln("              Obx(() {");
    if (isApiDropdown) {
      final dropdownKey = (field['dropdownValue'] ?? 'title').toString();
      buffer.writeln("                final val = controller.selected$capitalLabel.value != null");
      buffer.writeln("                    ? controller.selected$capitalLabel.value!.$dropdownKey?.toString() ?? ''");
      buffer.writeln("                    : '';");
    } else {
      buffer.writeln("                final val = controller.selected$capitalLabel.value != null");
      buffer.writeln("                    ? controller.selected$capitalLabel.value!.value");
      buffer.writeln("                    : '';");
    }
    buffer.writeln("                if (val.isEmpty) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val);");
    buffer.writeln("              }),");
  }
}

class RadioButtonPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'radio' || type == 'radio buttons';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  AppRadioGroupField(");
    buffer.writeln("                    label: '$rawLabel',");
    buffer.writeln("                    errorText: $errorRef,");
    buffer.writeln("                    value: controller.selected$capitalLabel.value?.toString(),");
    buffer.writeln("                    onChanged: (value) => controller.selected$capitalLabel.value = value ?? '',");
    buffer.writeln("                    options: controller.${name}Options.value.map((e) => e.toString()).toList(),");
    buffer.writeln("                  ),"); // changed from ; to , to fit in Wrap/Column properly
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.selected$capitalLabel.value;");
    buffer.writeln("                if (val == null || val.toString().isEmpty) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val.toString());");
    buffer.writeln("              }),");
  }
}

class SwitchPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'switch';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  SwitchListTile(");
    buffer.writeln("                    title: Text('$rawLabel'),");
    buffer.writeln("                    value: controller.${name}Value.value,");
    buffer.writeln("                    onChanged: (val) => controller.${name}Value.value = val,");
    buffer.writeln("                    contentPadding: EdgeInsets.zero,");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Value.value;");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val ? 'Yes' : 'No');");
    buffer.writeln("              }),");
  }
}

class CheckboxPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'checkbox';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  AppCheckboxField(");
    buffer.writeln("                    label: '$rawLabel',");
    buffer.writeln("                    value: controller.${name}Value.value,");
    buffer.writeln("                    onChanged: (val) => controller.${name}Value.value = val ?? false,");
    buffer.writeln("                    errorText: $errorRef,");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Value.value;");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val ? 'Yes' : 'No');");
    buffer.writeln("              }),");
  }
}

class FilePickerPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'file' || type == 'image';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final type = (field['type'] ?? '').toString().toLowerCase().trim();
    final pickMethod = type == 'image' ? "pick${capitalLabel}Image" : "pick${capitalLabel}File";

    buffer.writeln("                  Container(");
    buffer.writeln("                    padding: const EdgeInsets.all(16),");
    buffer.writeln("                    decoration: BoxDecoration(");
    buffer.writeln("                      borderRadius: BorderRadius.circular(16),");
    buffer.writeln("                      color: Colors.grey.shade50,");
    buffer.writeln("                      border: Border.all(color: Colors.grey.shade200),");
    buffer.writeln("                    ),");
    buffer.writeln("                    child: Tooltip(");
    buffer.writeln("                      message: 'Upload $rawLabel',");
    buffer.writeln("                      child: AppFileUploadField(");
    buffer.writeln("                        label: '$rawLabel',");
    buffer.writeln("                        value: controller.${name}FileName.value.isEmpty ? null : controller.${name}FileName.value,");
    buffer.writeln("                        hint: 'Tap Browse to select file',");
    buffer.writeln("                        errorText: $errorRef,");
    buffer.writeln("                        onChanged: (_) async {");
    buffer.writeln("                          await controller.$pickMethod();");
    buffer.writeln("                        },");
    buffer.writeln("                      ),");
    buffer.writeln("                    ),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}FileName.value;");
    buffer.writeln("                if (val.isEmpty) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val);");
    buffer.writeln("              }),");
  }
}

class MultiSelectPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'multiselect' || type == 'multi select' || type == 'multi_select';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final staticOpts = (field['options'] as List<dynamic>?) ?? (field['staticOptions'] as List<dynamic>?);

    buffer.writeln("                  AppMultiSelectField(");
    buffer.writeln("                    label: '$rawLabel',");
    if (staticOpts != null && staticOpts.isNotEmpty) {
      buffer.writeln("                    options: controller.${name}Options,");
    } else {
      buffer.writeln("                    options: controller.${name}Options.value.map((e) => e.toString()).toList(),");
    }
    buffer.writeln("                    selectedValues: controller.${name}Selected.toList(),");
    buffer.writeln("                    errorText: $errorRef,");
    buffer.writeln("                    onChanged: (values) {");
    buffer.writeln("                      controller.${name}Selected.assignAll(values);");
    buffer.writeln("                    },");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Selected.join(', ');");
    buffer.writeln("                if (val.isEmpty) return const SizedBox.shrink();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val);");
    buffer.writeln("              }),");
  }
}

class SliderPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'slider' || type == 'range slider';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final minVal = (field['minValue'] as num?)?.toDouble() ?? 0.0;
    final maxVal = (field['maxValue'] as num?)?.toDouble() ?? 100.0;

    buffer.writeln("                  Column(");
    buffer.writeln("                    crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                    children: [");
    buffer.writeln("                      Row(");
    buffer.writeln("                        mainAxisAlignment: MainAxisAlignment.spaceBetween,");
    buffer.writeln("                        children: [");
    buffer.writeln("                          Text('$rawLabel${isRequired ? ' *' : ''}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),");
    buffer.writeln("                          Text('\${controller.${name}Value.value.toStringAsFixed(0)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),");
    buffer.writeln("                        ],");
    buffer.writeln("                      ),");
    buffer.writeln("                      Slider(");
    buffer.writeln("                        value: controller.${name}Value.value,");
    buffer.writeln("                        min: $minVal,");
    buffer.writeln("                        max: $maxVal,");
    buffer.writeln("                        onChanged: (val) => controller.${name}Value.value = val,");
    buffer.writeln("                      ),");
    buffer.writeln("                    ],");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Value.value.toStringAsFixed(0);");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', val);");
    buffer.writeln("              }),");
  }
}

class LabelPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'label';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  Padding(");
    buffer.writeln("                    padding: const EdgeInsets.symmetric(vertical: 4.0),");
    buffer.writeln("                    child: Text(");
    buffer.writeln("                      '$rawLabel',");
    buffer.writeln("                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),");
    buffer.writeln("                    ),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class StarRatingPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'starrating' || type == 'rating' || type == 'star rating';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final maxStars = (field['maxValue'] as num?)?.toInt() ?? 5;

    buffer.writeln("                  Column(");
    buffer.writeln("                    crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                    children: [");
    buffer.writeln("                      Text('$rawLabel${isRequired ? ' *' : ''}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),");
    buffer.writeln("                      const SizedBox(height: 8),");
    buffer.writeln("                      Row(");
    buffer.writeln("                        children: List.generate($maxStars, (index) {");
    buffer.writeln("                          final star = index + 1;");
    buffer.writeln("                          return GestureDetector(");
    buffer.writeln("                            onTap: () => controller.${name}Value.value = star.toDouble(),");
    buffer.writeln("                            child: Icon(");
    buffer.writeln("                              star <= controller.${name}Value.value.round() ? Icons.star : Icons.star_border,");
    buffer.writeln("                              color: Colors.amber,");
    buffer.writeln("                              size: 32,");
    buffer.writeln("                            ),");
    buffer.writeln("                          );");
    buffer.writeln("                        }),");
    buffer.writeln("                      ),");
    buffer.writeln("                    ],");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
  ) {
    buffer.writeln("              Obx(() {");
    buffer.writeln("                final val = controller.${name}Value.value.round().toString();");
    buffer.writeln("                return _buildSummaryRow('$rawLabel', ' Stars');");
    buffer.writeln("              }),");
  }
}

class SectionPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'section';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  Padding(");
    buffer.writeln("                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),");
    buffer.writeln("                    child: Column(");
    buffer.writeln("                      crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                      children: [");
    buffer.writeln("                        Text(");
    buffer.writeln("                          '$rawLabel',");
    buffer.writeln("                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),");
    buffer.writeln("                        ),");
    buffer.writeln("                        const SizedBox(height: 4),");
    buffer.writeln("                        Divider(thickness: 1.5, color: theme.colorScheme.outline),");
    buffer.writeln("                        const SizedBox(height: 8),");
    final nested = field['nestedFields'] as List<dynamic>? ?? [];
    if (nested.isNotEmpty) {
      buildWidgetsRecursive(nested);
    }
    buffer.writeln("                      ],");
    buffer.writeln("                    ),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class CardPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'card';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  Card(");
    buffer.writeln("                    elevation: 2,");
    buffer.writeln("                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),");
    buffer.writeln("                    child: Padding(");
    buffer.writeln("                      padding: const EdgeInsets.all(16.0),");
    buffer.writeln("                      child: Column(");
    buffer.writeln("                        crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                        children: [");
    buffer.writeln("                          Text(");
    buffer.writeln("                            '$rawLabel',");
    buffer.writeln("                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),");
    buffer.writeln("                          ),");
    buffer.writeln("                          const SizedBox(height: 12),");
    final nested = field['nestedFields'] as List<dynamic>? ?? [];
    if (nested.isNotEmpty) {
      buildWidgetsRecursive(nested);
    } else {
      buffer.writeln("                          // No child fields defined");
    }
    buffer.writeln("                        ],");
    buffer.writeln("                      ),");
    buffer.writeln("                    ),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class TabsPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'tabs';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final nested = field['nestedFields'] as List<dynamic>? ?? [];
    final staticOpts = (field['options'] as List<dynamic>?) ?? (field['staticOptions'] as List<dynamic>?);
    final tabOptions = nested.isNotEmpty
        ? nested.map((t) => ((t as Map)['label'] ?? 'Tab').toString()).toList()
        : (staticOpts != null && staticOpts.isNotEmpty
            ? staticOpts.map((o) => o.toString()).toList()
            : ['Tab 1', 'Tab 2']);
    final tabLength = tabOptions.length;
    final tabItems = tabOptions.map((t) => "Tab(text: '${t.replaceAll("'", "\\'")}')").join(', ');

    buffer.writeln("                  DefaultTabController(");
    buffer.writeln("                    length: $tabLength,");
    buffer.writeln("                    child: Column(");
    buffer.writeln("                      crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                      children: [");
    if (rawLabel.isNotEmpty) {
      buffer.writeln("                        Text('$rawLabel', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),");
      buffer.writeln("                        const SizedBox(height: 8),");
    }
    buffer.writeln("                        TabBar(tabs: [$tabItems]),");
    buffer.writeln("                        const SizedBox(height: 12),");
    buffer.writeln("                        SizedBox(");
    buffer.writeln("                          height: 250,");
    buffer.writeln("                          child: TabBarView(");
    buffer.writeln("                            children: [");
    if (nested.isNotEmpty) {
      for (final t in nested) {
        final tFields = (t as Map)['fields'] as List<dynamic>? ?? [];
        buffer.writeln("                              Padding(");
        buffer.writeln("                                padding: const EdgeInsets.all(8.0),");
        buffer.writeln("                                child: Column(");
        buffer.writeln("                                  crossAxisAlignment: CrossAxisAlignment.start,");
        buffer.writeln("                                  children: [");
        buildWidgetsRecursive(tFields);
        buffer.writeln("                                  ],");
        buffer.writeln("                                ),");
        buffer.writeln("                              ),");
      }
    } else {
      for (final tab in tabOptions) {
        buffer.writeln("                              Center(child: Text('${tab.replaceAll("'", "\\'")} Content')),");
      }
    }
    buffer.writeln("                            ],");
    buffer.writeln("                          ),");
    buffer.writeln("                        ),");
    buffer.writeln("                      ],");
    buffer.writeln("                    ),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class AccordionPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'accordion' || type == 'collapse';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final nested = field['nestedFields'] as List<dynamic>? ?? [];
    buffer.writeln("                  ExpansionTile(");
    buffer.writeln("                    title: Text('$rawLabel'),");
    buffer.writeln("                    children: [");
    buffer.writeln("                      Padding(");
    buffer.writeln("                        padding: const EdgeInsets.all(12.0),");
    buffer.writeln("                        child: Column(");
    buffer.writeln("                          crossAxisAlignment: CrossAxisAlignment.start,");
    buffer.writeln("                          children: [");
    if (nested.isNotEmpty) {
      buildWidgetsRecursive(nested);
    } else {
      buffer.writeln("                            const Text('No nested fields'),");
    }
    buffer.writeln("                          ],");
    buffer.writeln("                        ),");
    buffer.writeln("                      ),");
    buffer.writeln("                    ],");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class RowColPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'row' || type == 'column';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    final nested = field['nestedFields'] as List<dynamic>? ?? [];
    buffer.writeln("                  Wrap(");
    buffer.writeln("                    spacing: 16,");
    buffer.writeln("                    runSpacing: 16,");
    buffer.writeln("                    children: [");
    for (final child in nested) {
      if (child is! Map) continue;
      final childMap = child as Map<String, dynamic>;
      final config = childMap['componentConfig'] as Map?;
      final colSpan = int.tryParse(config?['colSpan']?.toString() ?? '') ?? 12;
      buffer.writeln("                      LayoutBuilder(builder: (context, constraints) {");
      buffer.writeln("                        final w = constraints.maxWidth;");
      buffer.writeln("                        return SizedBox(width: w > 760 ? w * ($colSpan / 12) : double.infinity,");
      buffer.writeln("                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [");
      buildWidgetsRecursive([childMap]);
      buffer.writeln("                          ]),");
      buffer.writeln("                        );");
      buffer.writeln("                      }),");
    }
    buffer.writeln("                    ],");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class FormulaPlugin extends FieldGeneratorPlugin {
  @override
  bool matches(String type) {
    return type == 'formula';
  }

  @override
  void generateWidget(
    StringBuffer buffer,
    Map<String, dynamic> field,
    String name,
    String capitalLabel,
    String rawLabel,
    String hint,
    bool isRequired,
    bool isPassword,
    bool isReadOnly,
    String keyboardType,
    String textInputAction,
    String textCapitalization,
    int maxLength,
    String errorRef,
    String className,
    void Function(List<dynamic> currentFields) buildWidgetsRecursive,
  ) {
    buffer.writeln("                  InputDecorator(");
    buffer.writeln("                    decoration: InputDecoration(");
    buffer.writeln("                      labelText: '$rawLabel',");
    buffer.writeln("                      hintText: '$hint',");
    buffer.writeln("                      errorText: $errorRef,");
    buffer.writeln("                    ),");
    buffer.writeln("                    child: Text(controller.$name.value, style: theme.textTheme.bodyLarge),");
    buffer.writeln("                  ),");
  }

  @override
  void generateSummaryRow(StringBuffer buffer, Map<String, dynamic> field, String name, String capitalLabel, String rawLabel) {}
}

class FieldGeneratorRegistry {
  static final List<FieldGeneratorPlugin> plugins = [
    TextFieldPlugin(),
    DatePickerPlugin(),
    DateTimePickerPlugin(),
    TimePickerPlugin(),
    DropdownPlugin(),
    RadioButtonPlugin(),
    SwitchPlugin(),
    CheckboxPlugin(),
    FilePickerPlugin(),
    MultiSelectPlugin(),
    SliderPlugin(),
    LabelPlugin(),
    StarRatingPlugin(),
    SectionPlugin(),
    CardPlugin(),
    TabsPlugin(),
    AccordionPlugin(),
    RowColPlugin(),
    FormulaPlugin(),
  ];

  static FieldGeneratorPlugin? find(String type) {
    final t = type.toLowerCase().trim();
    for (final p in plugins) {
      if (p.matches(t)) return p;
    }
    return null;
  }
}
