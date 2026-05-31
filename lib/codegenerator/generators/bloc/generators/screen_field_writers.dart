// lib/bloc/generators/screen/screen_field_writers.dart

class ScreenFieldWriters {
  final String featureName;
  final List<Map<String, dynamic>> flatFields;

  ScreenFieldWriters({
    required this.featureName,
    required this.flatFields,
  });

  List<Map<String, dynamic>> get asyncFields =>
      flatFields.where(isApiDropdown).toList();

  bool get hasAsync => asyncFields.isNotEmpty;

  void writeFieldClass(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final type = (field['type'] ?? '').toString().toLowerCase();

    if (type == 'text' ||
        type == 'textfield' ||
        type == 'textarea' ||
        type == 'email' ||
        type == 'phone' ||
        type == 'number' ||
        type == 'integer' ||
        type == 'int' ||
        type == 'decimal' ||
        type == 'double' ||
        type == 'password' ||
        type == 'otp' ||
        type == 'formula') {
      writeTextField(buf, field, stateName, blocName);
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (isApiDropdown(field)) {
        writeApiDropdown(buf, field, stateName, blocName);
      } else {
        writeStaticDropdown(buf, field, stateName, blocName);
      }
    } else if (type == 'radio' || type == 'radio buttons') {
      writeRadioGroup(buf, field, stateName, blocName);
    } else if (type == 'date' ||
        type == 'datetime' ||
        type == 'date time' ||
        type == 'time') {
      writeDatePicker(buf, field, stateName, blocName);
    } else if (type == 'checkbox' || type == 'switch') {
      writeCheckbox(buf, field, stateName, blocName);
    } else if (type == 'file' || type == 'image') {
      writeFileUpload(buf, field, stateName, blocName);
    } else if (type == 'multiselect' || type == 'multi_select') {
      writeMultiSelect(buf, field, stateName, blocName);
    } else if (type == 'table_grid' || type == 'data_grid') {
      writeDataGrid(buf, field, stateName, blocName);
    } else if (type == 'divider') {
      writeDivider(buf, field);
    } else {
      writePlaceholder(buf, field);
    }
  }

  void writeTextField(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final className = '${cap(fieldKey)}Field';
    final label = field['label'] ?? fieldKey;
    final hint = field['placeholder'] ?? '';
    final isArea = (field['type'] == 'textarea');
    final maxLen = field['maxLength'];
    final readOnly = field['readOnly'] == true;
    final enabled = field['disable'] != true;
    final obscure = field['obscureText'] == true;
    final rawType = (field['type'] ?? '').toString().toLowerCase();
    final kbType = rawType == 'otp'
        ? 'TextInputType.number'
        : flutterKeyboardType(field['keyboardType'] ?? '');
    final capType = flutterCapitalization(field['textCapitalization'] ?? '');
    final inputAction = flutterInputAction(field['textInputAction'] ?? '');

    buf.writeln('class _$className extends StatefulWidget {');
    buf.writeln('  const _$className({super.key});');
    buf.writeln('  @override');
    buf.writeln('  State<_$className> createState() => _${className}State();');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('class _${className}State extends State<_$className> {');
    buf.writeln('  late final TextEditingController _controller;');
    buf.writeln('  @override');
    buf.writeln('  void initState() {');
    buf.writeln('    super.initState();');
    buf.writeln('    _controller = TextEditingController(');
    buf.writeln(
      "        text: context.read<$blocName>().state.formValues['$fieldKey']?.toString() ?? '');",
    );
    buf.writeln('  }');
    buf.writeln('  @override');
    buf.writeln('  void dispose() {');
    buf.writeln('    _controller.dispose();');
    buf.writeln('    super.dispose();');
    buf.writeln('  }');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocConsumer<$blocName, $stateName>(');
    buf.writeln(
      "      listenWhen: (previous, current) => previous.formValues['$fieldKey'] != current.formValues['$fieldKey'],",
    );
    buf.writeln('      listener: (context, state) {');
    buf.writeln(
      "        final newValue = state.formValues['$fieldKey']?.toString() ?? '';",
    );
    buf.writeln(
      '        if (_controller.text != newValue) _controller.text = newValue;',
    );
    buf.writeln('      },');
    buf.writeln("      buildWhen: (previous, current) => false,");
    buf.writeln('      builder: (context, state) {');
    buf.writeln('        return AppTextField(');
    buf.writeln('          controller: _controller,');
    buf.writeln("          label: '${escape(label)}',");
    if (hint.isNotEmpty) buf.writeln("          hint: '${escape(hint)}',");
    buf.writeln('          errorText: null,');
    if (readOnly) buf.writeln('          readOnly: true,');
    if (!enabled) buf.writeln('          enabled: false,');
    if (obscure) buf.writeln('          obscureText: true,');
    if (maxLen != null) {
      buf.writeln('          maxLength: $maxLen,');
    } else if (rawType == 'otp') {
      buf.writeln('          maxLength: 6,');
    }
    if (isArea) {
      buf.writeln('          maxLines: 5,');
      buf.writeln('          minLines: 3,');
    }
    buf.writeln('          keyboardType: $kbType,');
    buf.writeln('          textCapitalization: $capType,');
    buf.writeln('          textInputAction: $inputAction,');
    buf.writeln(
      '          onChanged: (value) => context.read<$blocName>().add(',
    );
    buf.writeln(
      "            ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('          ),');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeStaticDropdown(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw = field['options'] as List<dynamic>? ?? [];
    final options = optionsRaw
        .map((opt) => "'${escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppDropdownField<String>(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        items: [$options],');
    buf.writeln('        itemLabelBuilder: (item) => item,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln(
      "              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeApiDropdown(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    final asyncFieldName = '${fieldKey}Async';
    final listField = listFieldName(field);
    final innerEntityClass = resolveInnerEntityClass(field);
    final valueKey = field['dropdownValue']?.toString() ?? 'name';

    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocBuilder<$blocName, $stateName>(');
    buf.writeln('      buildWhen: (previous, current) =>');
    buf.writeln(
      "          previous.$asyncFieldName != current.$asyncFieldName ||",
    );
    buf.writeln(
      "          previous.formValues['$fieldKey'] != current.formValues['$fieldKey'],",
    );
    buf.writeln('      builder: (context, state) {');
    buf.writeln(
      "        final selectedId = state.formValues['$fieldKey']?.toString();",
    );
    buf.writeln('        final wrapperAsync = state.$asyncFieldName;');
    buf.writeln(
      '        late final AsyncValue<List<$innerEntityClass>> listAsync;',
    );
    buf.writeln('        wrapperAsync.when(');
    buf.writeln('          idle: () => listAsync = const AsyncValue.idle(),');
    buf.writeln(
      '          loading: () => listAsync = const AsyncValue.loading(),',
    );
    buf.writeln(
      '          data: (wrapper) => listAsync = AsyncValue.data(wrapper.$listField),',
    );
    buf.writeln('          error: (err) => listAsync = AsyncValue.error(err),');
    buf.writeln('        );');
    buf.writeln(
      '        final options = listAsync.isData ? listAsync.data! : <$innerEntityClass>[];',
    );
    buf.writeln('        $innerEntityClass? selectedOption;');
    buf.writeln('        try {');
    buf.writeln('          selectedOption = options.firstWhere(');
    buf.writeln(
      "            (item) => getDropdownLabel(item, '$valueKey') == selectedId,",
    );
    buf.writeln('          );');
    buf.writeln('        } catch (_) {');
    buf.writeln('          selectedOption = null;');
    buf.writeln('        }');
    buf.writeln('        return AppAsyncDropdownField<$innerEntityClass>(');
    buf.writeln("          label: '${escape(label)}',");
    buf.writeln('          asyncState: toAsyncState(listAsync),');
    buf.writeln('          value: selectedOption,');
    buf.writeln(
      "          itemLabelBuilder: (item) => getDropdownLabel(item, '$valueKey'),",
    );
    buf.writeln('          errorText: null,');
    if (hasAsync) {
      buf.writeln(
        '          onRetry: () => context.read<$blocName>().add(const Load${featureName}DataEvent()),',
      );
    } else {
      buf.writeln('          onRetry: null,');
    }
    buf.writeln('          onChanged: (value) {');
    buf.writeln('            if (value != null) {');
    buf.writeln('              context.read<$blocName>().add(');
    buf.writeln('                ${featureName}FieldChangedEvent(');
    buf.writeln("                  fieldName: '$fieldKey',");
    buf.writeln(
      "                  value: getDropdownLabel(value, '$valueKey'),",
    );
    buf.writeln('                ),');
    buf.writeln('              );');
    buf.writeln('            }');
    buf.writeln('          },');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeRadioGroup(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw =
        field['options'] as List<dynamic>? ?? ['Option 1', 'Option 2'];
    final options = optionsRaw
        .map((opt) => "'${escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppRadioGroupField(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        options: [$options],');
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln(
      "              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeDatePicker(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, DateTime?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey'] as DateTime?,",
    );
    buf.writeln('      builder: (context, value) => AppDatePickerField(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln(
      "              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeCheckbox(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey'] as bool? ?? false,",
    );
    buf.writeln('      builder: (context, value) => AppCheckboxField(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
    buf.writeln(
      "          ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value ?? false),",
    );
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeFileUpload(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppFileUploadField(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln(
      "              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeMultiSelect(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw =
        field['options'] as List<dynamic>? ??
        ['Option 1', 'Option 2', 'Option 3'];
    final options = optionsRaw
        .map((opt) => "'${escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln(
      '    return BlocSelector<$blocName, $stateName, List<String>>(',
    );
    buf.writeln(
      "      selector: (state) => (state.formValues['$fieldKey'] as List<dynamic>?)?.cast<String>() ?? [],",
    );
    buf.writeln('      builder: (context, value) => AppMultiSelectField(');
    buf.writeln("        label: '${escape(label)}',");
    buf.writeln('        options: [$options],');
    buf.writeln('        selectedValues: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
    buf.writeln(
      "          ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),",
    );
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeDataGrid(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = fieldName(field);
    final label = field['label'] ?? fieldKey;
    final columnsRaw = ((field['componentConfig'] as Map?)?['columns'] as List?) ??
        (field['columns'] as List?) ??
        const [];
    final columns = columnsRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, List<Map<String, dynamic>>>(');
    buf.writeln(
      "      selector: (state) => (state.formValues['$fieldKey'] as List<dynamic>? ?? const [])",
    );
    buf.writeln(
      "          .whereType<Map>()",
    );
    buf.writeln(
      "          .map((e) => Map<String, dynamic>.from(e))",
    );
    buf.writeln(
      "          .toList(growable: false),",
    );
    buf.writeln('      builder: (context, rows) => AppDataGrid(');
    buf.writeln("        label: '${escape(label.toString())}',");
    buf.writeln('        columns: [');
    if (columns.isEmpty) {
      buf.writeln("          const AppDataGridColumn(keyName: 'value', label: 'Value'),");
    } else {
      for (final c in columns) {
        final key = (c['key'] ?? c['field'] ?? c['id'] ?? c['name'] ?? 'value')
            .toString()
            .replaceAll("'", "\\'");
        final colLabel = (c['label'] ?? key).toString().replaceAll("'", "\\'");
        final readOnly = c['readOnly'] == true;
        buf.writeln(
          "          const AppDataGridColumn(keyName: '$key', label: '$colLabel', readOnly: $readOnly),",
        );
      }
    }
    buf.writeln('        ],');
    buf.writeln('        rows: rows,');
    buf.writeln('        onRowsChanged: (nextRows) => context.read<$blocName>().add(');
    buf.writeln(
      "          ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: nextRows),",
    );
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writePlaceholder(StringBuffer buf, Map<String, dynamic> field) {
    final label = field['label'] ?? fieldName(field);
    buf.writeln(
      'class _${cap(fieldName(field))}Field extends StatelessWidget {',
    );
    buf.writeln('  const _${cap(fieldName(field))}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return FormFieldWrapper(');
    buf.writeln("      label: '${escape(label)}',");
    buf.writeln('      child: Container(');
    buf.writeln('        padding: const EdgeInsets.all(16),');
    buf.writeln('        decoration: BoxDecoration(');
    buf.writeln('          color: const Color(0xFFF1F5F9),');
    buf.writeln('          borderRadius: BorderRadius.circular(12),');
    buf.writeln(
      '          border: Border.all(color: const Color(0xFFE2E8F0)),',
    );
    buf.writeln('        ),');
    buf.writeln('        child: const Center(');
    buf.writeln(
      "          child: Text('Component not implemented in generator yet', style: TextStyle(color: Color(0xFF64748B))),",
    );
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void writeDivider(StringBuffer buf, Map<String, dynamic> field) {
    final fieldKey = fieldName(field);
    final label = (field['label'] ?? '').toString().trim();
    buf.writeln('class _${cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return Padding(');
    buf.writeln('      padding: const EdgeInsets.symmetric(vertical: 12),');
    buf.writeln('      child: Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    if (label.isNotEmpty) {
      buf.writeln("          Text('${escape(label)}'),");
      buf.writeln('          const SizedBox(height: 8),');
    }
    buf.writeln('          const Divider(),');
    buf.writeln('        ],');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  bool isFormField(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    final hidden = field['hidden'] == true;
    final visible = field['visible'] != false;
    const skip = {
      'card',
      'group',
      'section',
      'step',
      'tab',
      'tabs',
      'container',
      'row',
      'column',
      'accordion',
      'timeline',
      'repeater',
    };
    if (hidden || !visible) return false;
    return !skip.contains(type);
  }

  bool isApiDropdown(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type != 'dropdown' && type != 'api_dropdown') return false;
    final useStatic = field['useStaticOptions'] == true;
    final hasApiUrl = field['dropdownApiUrl'] != null;
    return !useStatic && hasApiUrl;
  }

  bool isAutoId(String? id) {
    if (id == null) return true;
    return RegExp(r'^field_\d+$').hasMatch(id.trim());
  }

  String fieldName(Map<String, dynamic> f) {
    final id = f['id']?.toString().trim();
    final label = (f['label'] ?? f['fieldId'] ?? 'field').toString().trim();
    if (isAutoId(id)) return labelToCamel(label);
    final raw = (id ?? label);
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String labelToCamel(String label) {
    final parts = label.trim().split(RegExp(r'[\s_\-]+'));
    if (parts.isEmpty) return 'field';
    final first = parts.first;
    final rest = parts.skip(1).map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1);
    }).join();
    final camel = first[0].toLowerCase() + first.substring(1) + rest;
    final n = camel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String escape(String s) => s.replaceAll("'", "\\'");

  String resolveEntityFile(Map<String, dynamic> field) {
    final entityClass = resolveEntityClass(field);
    final base = entityClass.replaceAll('Entity', '');
    return toSnakeCase(base);
  }

  String resolveInnerEntityFile(Map<String, dynamic> field) {
    final innerClass = resolveInnerEntityClass(field);
    final base = innerClass.replaceAll('Entity', '');
    return toSnakeCase(base);
  }

  String resolveEntityClass(Map<String, dynamic> field) {
    final explicit = field['entityName'];

    if (explicit != null && explicit.toString().trim().isNotEmpty) {
      var value = explicit.toString().trim();
      if (!value.endsWith('Entity')) {
        value = '${value}Entity';
      }
      return value;
    }

    final label = field['label'] ?? field['id'] ?? 'item';
    return '${cap(label.toString().replaceAll(' ', ''))}Entity';
  }

  String resolveInnerEntityClass(Map<String, dynamic> field) {
    final explicit = field['itemEntity'];

    if (explicit != null && explicit.toString().trim().isNotEmpty) {
      var value = explicit.toString().trim();
      if (!value.endsWith('Entity')) {
        value = '${value}Entity';
      }
      return value;
    }

    final dropdowndata = field['dropdowndata'];

    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
          return '${cap(singularize(entry.key))}Entity';
        }
      }
    }

    return 'ItemEntity';
  }

  String listFieldName(Map<String, dynamic> field) {
    final explicit = field['listFieldName'];
    if (explicit != null && explicit.toString().isNotEmpty) {
      return explicit.toString();
    }
    final dropdowndata = field['dropdowndata'];
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List) {
          return entry.key;
        }
      }
    }
    return 'items';
  }

  String singularize(String text) {
    if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
    if (text.endsWith('s') && text.length > 1) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && RegExp(r'[A-Z]').hasMatch(char)) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String flutterKeyboardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'emailaddress':
      case 'email':
        return 'TextInputType.emailAddress';
      case 'number':
        return 'TextInputType.number';
      case 'phone':
        return 'TextInputType.phone';
      case 'multiline':
        return 'TextInputType.multiline';
      case 'url':
        return 'TextInputType.url';
      case 'visiblepassword':
        return 'TextInputType.visiblePassword';
      default:
        return 'TextInputType.text';
    }
  }

  String flutterCapitalization(String? cap) {
    switch (cap?.toLowerCase()) {
      case 'words':
        return 'TextCapitalization.words';
      case 'sentences':
        return 'TextCapitalization.sentences';
      case 'characters':
        return 'TextCapitalization.characters';
      default:
        return 'TextCapitalization.none';
    }
  }

  String flutterInputAction(String? action) {
    switch (action?.toLowerCase()) {
      case 'next':
        return 'TextInputAction.next';
      case 'search':
        return 'TextInputAction.search';
      case 'send':
        return 'TextInputAction.send';
      case 'go':
        return 'TextInputAction.go';
      case 'newline':
        return 'TextInputAction.newline';
      default:
        return 'TextInputAction.done';
    }
  }
}

String getDropdownLabel(dynamic item, String key) {
  try {
    final json = item.toJson();
    final value = json[key];
    if (value == null) return '';
    return value.toString();
  } catch (_) {
    return '';
  }
}

// Convert AsyncValue -> AsyncState
dynamic toAsyncState(dynamic asyncValue) {
  // Let the generated screen import the exact runtime classes directly
  return asyncValue;
}
