// lib/bloc/generators/screen/screen_generator.dart

import 'package:revojourneytryone/filegegnerator/journey_step_codegen.dart';

class ScreenGenerator {
  ScreenGenerator({
    required this.featureName,
    required this.flatFields,
    required this.hasSubmit,
    this.stepJson,
  });

  final String featureName;
  final List<Map<String, dynamic>> flatFields;
  final bool hasSubmit;
  final Map<String, dynamic>? stepJson;

  List<Map<String, dynamic>> get _asyncFields =>
      flatFields.where(_isApiDropdown).toList();

  bool get _hasAsync => _asyncFields.isNotEmpty;

  String generate() {
    final snakeName = _toSnakeCase(featureName);
    final stateName = '${featureName}State';
    final blocName = '${featureName}Bloc';
    final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});
    final buf = StringBuffer();

    // ─── Imports ──────────────────────────────────────────────────────────
    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_state.dart';");
    buf.writeln("import '../bloc/${snakeName}_event.dart';");
    buf.writeln("import '../../../../../core/widgets/widgets.dart';");
    buf.writeln("import '/core/runtime/async_state.dart' as runtime;");
    buf.writeln("import '../../presentation/bloc/async_value.dart' as asyncv;");
    buf.writeln("import '../../../../../core/runtime/failure.dart';");

    // Import both wrapper and inner entities for API dropdowns
    final wrapperImports = <String>{};
    final innerImports = <String>{};
    for (final f in flatFields.where(_isApiDropdown)) {
      final wrapperFile = _resolveEntityFile(f);
      final innerFile = _resolveInnerEntityFile(f);
      wrapperImports.add(
        "import '../../domain/entity/${wrapperFile}_entity.dart';",
      );
      innerImports.add(
        "import '../../domain/entity/${innerFile}_entity.dart';",
      );
    }
    for (final imp in wrapperImports) buf.writeln(imp);
    for (final imp in innerImports) buf.writeln(imp);
    buf.writeln();

    // ─── Helper: get label from entity via toJson() ──────────────────────
    buf.writeln("String _getDropdownLabel(dynamic item, String key) {");
    buf.writeln("  try {");
    buf.writeln("    final json = item.toJson();");
    buf.writeln("    final value = json[key];");
    buf.writeln("    if (value == null) return '';");
    buf.writeln("    return value.toString();");
    buf.writeln("  } catch (_) {");
    buf.writeln("    return '';");
    buf.writeln("  }");
    buf.writeln("}");
    buf.writeln();

    // ─── Helper: convert AsyncValue → AsyncState (matching your AsyncState class) ──
    // buf.writeln("AsyncState<T> _toAsyncState<T>(AsyncValue<T> asyncValue) {");
    // buf.writeln("  return asyncValue.when(");
    // buf.writeln("    idle: () => AsyncIdle<T>(),");
    // buf.writeln("    loading: () => AsyncLoading<T>(),");
    // buf.writeln("    data: (data) =>  AsyncSuccess<T>(data),");
    // buf.writeln(
    //   "    error: (err) => AsyncFailure<T>(Failure(message: err.toString())),",
    // );
    // buf.writeln("  );");
    // buf.writeln("}");
    // buf.writeln();

    buf.writeln("""
runtime.AsyncState<T> _toAsyncState<T>(
  asyncv.AsyncValue<T> asyncValue,
) {
  return asyncValue.when(
    idle: () => runtime.AsyncIdle<T>(),
    loading: () => runtime.AsyncLoading<T>(),
    data: (data) => runtime.AsyncSuccess<T>(data),
    error: (err) => runtime.AsyncFailure<T>(
      runtime.Failure(
        message: err.toString(),
      ),
    ),
  );
}

""");

    // ─── Screen widget ────────────────────────────────────────────────────
    buf.writeln('class ${featureName}Screen extends StatelessWidget {');
    buf.writeln('  const ${featureName}Screen({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocListener<$blocName, $stateName>(');
    buf.writeln('      listenWhen: (prev, curr) =>');
    buf.writeln(
      '          prev.navigationTargetStepId != curr.navigationTargetStepId,',
    );
    buf.writeln('      listener: (context, state) {');
    buf.writeln('        final target = state.navigationTargetStepId;');
    buf.writeln('        if (target != null && target.isNotEmpty) {');
    buf.writeln(
      "          Navigator.of(context).pushNamed('/journey/\$target');",
    );
    buf.writeln('        }');
    buf.writeln('        if (state.errorMessage != null) {');
    buf.writeln('          ScaffoldMessenger.of(context).showSnackBar(');
    buf.writeln('            SnackBar(content: Text(state.errorMessage!)),');
    buf.writeln('          );');
    buf.writeln('        }');
    buf.writeln('      },');
    buf.writeln('      child: Scaffold(');
    buf.writeln("      backgroundColor: const Color(0xFFF8FAFC),");
    buf.writeln("      appBar: AppBar(");
    buf.writeln(
      "        title: const Text('${stepMeta.escapedTitle}', style: TextStyle(fontWeight: FontWeight.w600)),",
    );
    buf.writeln("        backgroundColor: Colors.transparent,");
    buf.writeln("        foregroundColor: const Color(0xFF0F172A),");
    buf.writeln("        elevation: 0,");
    buf.writeln("        centerTitle: true,");
    buf.writeln("        actions: [");
    buf.writeln("          IconButton(");
    buf.writeln(
      "            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),",
    );
    buf.writeln("            tooltip: 'Reset',");
    buf.writeln(
      "            onPressed: () => context.read<$blocName>().add(const Reset${featureName}Event()),",
    );
    buf.writeln("          ),");
    buf.writeln("        ],");
    buf.writeln("      ),");
    buf.writeln("      body: const SafeArea(child: _${featureName}Body()),");
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ─── Body widget ─────────────────────────────────────────────────────
    buf.writeln('class _${featureName}Body extends StatelessWidget {');
    buf.writeln('  const _${featureName}Body();');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return Center(');
    buf.writeln('      child: ConstrainedBox(');
    buf.writeln('        constraints: const BoxConstraints(maxWidth: 600),');
    buf.writeln('        child: SingleChildScrollView(');
    buf.writeln(
      '          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),',
    );
    buf.writeln('          child: Container(');
    buf.writeln('            padding: const EdgeInsets.all(24),');
    buf.writeln('            decoration: BoxDecoration(');
    buf.writeln('              color: Colors.white,');
    buf.writeln('              borderRadius: BorderRadius.circular(20),');
    buf.writeln(
      '              border: Border.all(color: const Color(0xFFE2E8F0)),',
    );
    buf.writeln('            ),');
    buf.writeln('            child: Column(');
    buf.writeln('              crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('              children: [');
    stepMeta.writeFlutterStepHeader(buf);
    for (final f in flatFields.where(_isFormField)) {
      final fieldKey = _fieldName(f);
      buf.writeln(
        "                _${_cap(fieldKey)}Field(key: const ValueKey('$fieldKey')),",
      );
    }
    if (hasSubmit) {
      stepMeta.writeBlocActionButton(buf, featureName);
    }
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('          ),');
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ─── Field widgets ───────────────────────────────────────────────────
    for (final f in flatFields.where(_isFormField)) {
      _writeFieldClass(buf, f, stateName, blocName);
      buf.writeln();
    }

    return buf.toString();
  }

  // --------------------------------------------------------------------------
  // Field widget builders (unchanged except API dropdown uses corrected helper)
  // --------------------------------------------------------------------------
  void _writeFieldClass(
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
      _writeTextField(buf, field, stateName, blocName);
    } else if (type == 'dropdown' || type == 'api_dropdown') {
      if (_isApiDropdown(field)) {
        _writeApiDropdown(buf, field, stateName, blocName);
      } else {
        _writeStaticDropdown(buf, field, stateName, blocName);
      }
    } else if (type == 'radio' || type == 'radio buttons') {
      _writeRadioGroup(buf, field, stateName, blocName);
    } else if (type == 'date' ||
        type == 'datetime' ||
        type == 'date time' ||
        type == 'time') {
      _writeDatePicker(buf, field, stateName, blocName);
    } else if (type == 'checkbox' || type == 'switch') {
      _writeCheckbox(buf, field, stateName, blocName);
    } else if (type == 'file' || type == 'image') {
      _writeFileUpload(buf, field, stateName, blocName);
    } else if (type == 'multiselect' || type == 'multi_select') {
      _writeMultiSelect(buf, field, stateName, blocName);
    } else if (type == 'divider') {
      _writeDivider(buf, field);
    } else {
      _writePlaceholder(buf, field);
    }
  }

  void _writeTextField(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final className = '${_cap(fieldKey)}Field';
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
        : _flutterKeyboardType(field['keyboardType'] ?? '');
    final capType = _flutterCapitalization(field['textCapitalization'] ?? '');
    final inputAction = _flutterInputAction(field['textInputAction'] ?? '');

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
    buf.writeln("          label: '${_escape(label)}',");
    if (hint.isNotEmpty) buf.writeln("          hint: '${_escape(hint)}',");
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

  void _writeStaticDropdown(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw = field['options'] as List<dynamic>? ?? [];
    final options = optionsRaw
        .map((opt) => "'${_escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppDropdownField<String>(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writeApiDropdown(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    final asyncFieldName = '${fieldKey}Async';
    final listField = _listFieldName(field);
    final innerEntityClass = _resolveInnerEntityClass(field);
    final valueKey = field['dropdownValue']?.toString() ?? 'name';

    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
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
    // buf.writeln(
    //   '          data: (wrapper) => listAsync = AsyncValue.data(wrapper.$listField as List<$innerEntityClass>),',
    // );
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
      "            (item) => _getDropdownLabel(item, '$valueKey') == selectedId,",
    );
    buf.writeln('          );');
    buf.writeln('        } catch (_) {');
    buf.writeln('          selectedOption = null;');
    buf.writeln('        }');
    buf.writeln('        return AppAsyncDropdownField<$innerEntityClass>(');
    buf.writeln("          label: '${_escape(label)}',");
    buf.writeln('          asyncState: _toAsyncState(listAsync),');
    buf.writeln('          value: selectedOption,');
    buf.writeln(
      "          itemLabelBuilder: (item) => _getDropdownLabel(item, '$valueKey'),",
    );
    buf.writeln('          errorText: null,');
    if (_hasAsync) {
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
      "                  value: _getDropdownLabel(value, '$valueKey'),",
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

  void _writeRadioGroup(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw =
        field['options'] as List<dynamic>? ?? ['Option 1', 'Option 2'];
    final options = optionsRaw
        .map((opt) => "'${_escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppRadioGroupField(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writeDatePicker(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, DateTime?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey'] as DateTime?,",
    );
    buf.writeln('      builder: (context, value) => AppDatePickerField(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writeCheckbox(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey'] as bool? ?? false,",
    );
    buf.writeln('      builder: (context, value) => AppCheckboxField(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writeFileUpload(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln(
      "      selector: (state) => state.formValues['$fieldKey']?.toString(),",
    );
    buf.writeln('      builder: (context, value) => AppFileUploadField(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writeMultiSelect(
    StringBuffer buf,
    Map<String, dynamic> field,
    String stateName,
    String blocName,
  ) {
    final fieldKey = _fieldName(field);
    final label = field['label'] ?? fieldKey;
    final optionsRaw =
        field['options'] as List<dynamic>? ??
        ['Option 1', 'Option 2', 'Option 3'];
    final options = optionsRaw
        .map((opt) => "'${_escape(opt.toString())}'")
        .join(', ');
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln(
      '    return BlocSelector<$blocName, $stateName, List<String>>(',
    );
    buf.writeln(
      "      selector: (state) => (state.formValues['$fieldKey'] as List<dynamic>?)?.cast<String>() ?? [],",
    );
    buf.writeln('      builder: (context, value) => AppMultiSelectField(');
    buf.writeln("        label: '${_escape(label)}',");
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

  void _writePlaceholder(StringBuffer buf, Map<String, dynamic> field) {
    final label = field['label'] ?? _fieldName(field);
    buf.writeln(
      'class _${_cap(_fieldName(field))}Field extends StatelessWidget {',
    );
    buf.writeln('  const _${_cap(_fieldName(field))}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return FormFieldWrapper(');
    buf.writeln("      label: '${_escape(label)}',");
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

  void _writeDivider(StringBuffer buf, Map<String, dynamic> field) {
    final fieldKey = _fieldName(field);
    final label = (field['label'] ?? '').toString().trim();
    buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
    buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return Padding(');
    buf.writeln('      padding: const EdgeInsets.symmetric(vertical: 12),');
    buf.writeln('      child: Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    if (label.isNotEmpty) {
      buf.writeln("          Text('${_escape(label)}'),");
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
  // Helpers for names and types (unchanged)
  // --------------------------------------------------------------------------
  bool _isFormField(Map<String, dynamic> field) {
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
      'table_grid',
      'timeline',
      'repeater',
    };
    if (hidden || !visible) return false;
    return !skip.contains(type);
  }

  bool _isApiDropdown(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type != 'dropdown' && type != 'api_dropdown') return false;
    final useStatic = field['useStaticOptions'] == true;
    final hasApiUrl = field['dropdownApiUrl'] != null;
    return !useStatic && hasApiUrl;
  }

  bool _isAutoId(String? id) {
    if (id == null) return true;
    return RegExp(r'^field_\d+$').hasMatch(id.trim());
  }

  String _fieldName(Map<String, dynamic> f) {
    final id = f['id']?.toString().trim();
    final label = (f['label'] ?? f['fieldId'] ?? 'field').toString().trim();
    if (_isAutoId(id)) return _labelToCamel(label);
    final raw = (id ?? label);
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String _labelToCamel(String label) {
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

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _escape(String s) => s.replaceAll("'", "\\'");

  String _resolveEntityFile(Map<String, dynamic> field) {
    final entityClass = _resolveEntityClass(field);
    final base = entityClass.replaceAll('Entity', '');
    return _toSnakeCase(base);
  }

  String _resolveInnerEntityFile(Map<String, dynamic> field) {
    final innerClass = _resolveInnerEntityClass(field);
    final base = innerClass.replaceAll('Entity', '');
    return _toSnakeCase(base);
  }

  String _resolveEntityClass(Map<String, dynamic> field) {
    final explicit = field['entityName'];

    if (explicit != null && explicit.toString().trim().isNotEmpty) {
      var value = explicit.toString().trim();

      if (!value.endsWith('Entity')) {
        value = '${value}Entity';
      }

      return value;
    }

    final label = field['label'] ?? field['id'] ?? 'item';

    return '${_cap(label.toString().replaceAll(' ', ''))}Entity';
  }

  // String _resolveEntityClass(Map<String, dynamic> field) {
  //   final explicit = field['entityName'] ?? field['referenceEntity'];
  //   if (explicit != null && explicit.toString().trim().isNotEmpty) {
  //     var value = explicit.toString().trim();
  //     if (!value.endsWith('Entity')) value = '${value}Entity';
  //     return value;
  //   }
  //   final dropdowndata = field['dropdowndata'];
  //   if (dropdowndata is Map<String, dynamic>) {
  //     for (final entry in dropdowndata.entries) {
  //       final v = entry.value;
  //       if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
  //         return '${_cap(_singularize(entry.key))}Entity';
  //       }
  //     }
  //   }
  //   final label = field['label'] ?? field['id'] ?? 'item';
  //   return '${_cap(_singularize(label))}Entity';
  // }

  // String _resolveInnerEntityClass(Map<String, dynamic> field) {
  //   final dropdowndata = field['dropdowndata'];
  //   if (dropdowndata is Map<String, dynamic>) {
  //     for (final entry in dropdowndata.entries) {
  //       final v = entry.value;
  //       if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
  //         return '${_cap(_singularize(entry.key))}Entity';
  //       }
  //     }
  //   }
  //   final label = field['label'] ?? field['id'] ?? 'item';
  //   return '${_cap(_singularize(label))}Entity';
  // }

  String _resolveInnerEntityClass(Map<String, dynamic> field) {
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
          return '${_cap(_singularize(entry.key))}Entity';
        }
      }
    }

    return 'ItemEntity';
  }

  String _listFieldName(Map<String, dynamic> field) {
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

  String _singularize(String text) {
    if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
    if (text.endsWith('s') && text.length > 1)
      return text.substring(0, text.length - 1);
    return text;
  }

  String _toSnakeCase(String input) {
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

  String _flutterKeyboardType(String? type) {
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

  String _flutterCapitalization(String? cap) {
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

  String _flutterInputAction(String? action) {
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

// // lib/bloc/generators/screen/screen_generator.dart

// import 'dart:convert';

// class ScreenGenerator {
//   ScreenGenerator({
//     required this.featureName,
//     required this.flatFields,
//     required this.hasSubmit,
//   });

//   final String featureName;
//   final List<Map<String, dynamic>> flatFields;
//   final bool hasSubmit;

//   List<Map<String, dynamic>> get _asyncFields =>
//       flatFields.where(_isApiDropdown).toList();

//   bool get _hasAsync => _asyncFields.isNotEmpty;

//   String generate() {
//     final snakeName = _toSnakeCase(featureName);
//     final stateName = '${featureName}State';
//     final blocName = '${featureName}Bloc';
//     final buf = StringBuffer();

//     // ─── Imports ──────────────────────────────────────────────────────────
//     buf.writeln("import 'package:flutter/material.dart';");
//     buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
//     buf.writeln("import '../bloc/${snakeName}_bloc.dart';");
//     buf.writeln("import '../bloc/${snakeName}_state.dart';");
//     buf.writeln("import '../bloc/${snakeName}_event.dart';");
//     buf.writeln("import '/core/widgets/widgets.dart';"); // adjust path if needed

//     // Import both wrapper and inner entities for API dropdowns
//     final wrapperImports = <String>{};
//     final innerImports = <String>{};
//     for (final f in flatFields.where(_isApiDropdown)) {
//       final wrapperFile = _resolveEntityFile(f);
//       final innerFile = _resolveInnerEntityFile(f);
//       wrapperImports.add("import '../../domain/entity/${wrapperFile}_entity.dart';");
//       innerImports.add("import '../../domain/entity/${innerFile}_entity.dart';");
//     }
//     for (final imp in wrapperImports) buf.writeln(imp);
//     for (final imp in innerImports) buf.writeln(imp);
//     buf.writeln();

//     // ─── Helper: get label from entity via toJson() ──────────────────────
//     buf.writeln("String _getDropdownLabel(dynamic item, String key) {");
//     buf.writeln("  try {");
//     buf.writeln("    final json = item.toJson();");
//     buf.writeln("    final value = json[key];");
//     buf.writeln("    if (value == null) return '';");
//     buf.writeln("    return value.toString();");
//     buf.writeln("  } catch (_) {");
//     buf.writeln("    return '';");
//     buf.writeln("  }");
//     buf.writeln("}");
//     buf.writeln();

//     // ─── Helper: convert AsyncValue → AsyncState ─────────────────────────
//     buf.writeln("AsyncState<T> _toAsyncState<T>(AsyncValue<T> asyncValue) {");
//     buf.writeln("  return asyncValue.when(");
//     buf.writeln("    idle: () => AsyncState<T>.idle(),");
//     buf.writeln("    loading: () => AsyncState<T>.loading(),");
//     buf.writeln("    data: (data) => AsyncState<T>.data(data),");
//     buf.writeln("    error: (err) => AsyncState<T>.error(err),");
//     buf.writeln("  );");
//     buf.writeln("}");
//     buf.writeln();

//     // ─── Screen widget (no submit listener) ──────────────────────────────
//     buf.writeln('class ${featureName}Screen extends StatelessWidget {');
//     buf.writeln('  const ${featureName}Screen({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return Scaffold(');
//     buf.writeln("      backgroundColor: const Color(0xFFF8FAFC),");
//     buf.writeln("      appBar: AppBar(");
//     buf.writeln("        title: const Text('$featureName', style: TextStyle(fontWeight: FontWeight.w600)),");
//     buf.writeln("        backgroundColor: Colors.transparent,");
//     buf.writeln("        foregroundColor: const Color(0xFF0F172A),");
//     buf.writeln("        elevation: 0,");
//     buf.writeln("        centerTitle: true,");
//     buf.writeln("        actions: [");
//     buf.writeln("          IconButton(");
//     buf.writeln("            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),");
//     buf.writeln("            tooltip: 'Reset',");
//     buf.writeln("            onPressed: () => context.read<$blocName>().add(const Reset${featureName}Event()),");
//     buf.writeln("          ),");
//     buf.writeln("        ],");
//     buf.writeln("      ),");
//     buf.writeln("      body: const SafeArea(child: _${featureName}Body()),");
//     buf.writeln("    );");
//     buf.writeln("  }");
//     buf.writeln("}");
//     buf.writeln();

//     // ─── Body widget ─────────────────────────────────────────────────────
//     buf.writeln('class _${featureName}Body extends StatelessWidget {');
//     buf.writeln('  const _${featureName}Body();');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return Center(');
//     buf.writeln('      child: ConstrainedBox(');
//     buf.writeln('        constraints: const BoxConstraints(maxWidth: 600),');
//     buf.writeln('        child: SingleChildScrollView(');
//     buf.writeln('          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),');
//     buf.writeln('          child: Container(');
//     buf.writeln('            padding: const EdgeInsets.all(24),');
//     buf.writeln('            decoration: BoxDecoration(');
//     buf.writeln('              color: Colors.white,');
//     buf.writeln('              borderRadius: BorderRadius.circular(20),');
//     buf.writeln('              border: Border.all(color: const Color(0xFFE2E8F0)),');
//     buf.writeln('            ),');
//     buf.writeln('            child: Column(');
//     buf.writeln('              crossAxisAlignment: CrossAxisAlignment.start,');
//     buf.writeln('              children: [');
//     for (final f in flatFields.where(_isFormField)) {
//       final fieldKey = _fieldName(f);
//       buf.writeln("                _${_cap(fieldKey)}Field(key: const ValueKey('$fieldKey')),");
//     }
//     if (hasSubmit) {
//       buf.writeln('                const SizedBox(height: 24),');
//       buf.writeln('                _SubmitButton(),');
//     }
//     buf.writeln('              ],');
//     buf.writeln('            ),');
//     buf.writeln('          ),');
//     buf.writeln('        ),');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//     buf.writeln();

//     // ─── Field widgets ───────────────────────────────────────────────────
//     for (final f in flatFields.where(_isFormField)) {
//       _writeFieldClass(buf, f, stateName, blocName);
//       buf.writeln();
//     }

//     // ─── Submit button (placeholder) ─────────────────────────────────────
//     if (hasSubmit) {
//       buf.writeln('class _SubmitButton extends StatelessWidget {');
//       buf.writeln('  @override');
//       buf.writeln('  Widget build(BuildContext context) {');
//       buf.writeln('    return AppFormButton(');
//       buf.writeln("      label: 'Submit',");
//       buf.writeln("      loadingLabel: 'Submitting...',");
//       buf.writeln('      state: AppButtonState.idle,');
//       buf.writeln('      onPressed: () {');
//       buf.writeln('        // Submit logic goes here – add a submit event if required');
//       buf.writeln('        ScaffoldMessenger.of(context).showSnackBar(');
//       buf.writeln("          const SnackBar(content: Text('Submit pressed (not implemented)')),");
//       buf.writeln('        );');
//       buf.writeln('      },');
//       buf.writeln('    );');
//       buf.writeln('  }');
//       buf.writeln('}');
//     }

//     return buf.toString();
//   }

//   // --------------------------------------------------------------------------
//   // Field widget builders
//   // --------------------------------------------------------------------------
//   void _writeFieldClass(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     final fieldKey = _fieldName(field);

//     if (type == 'text' ||
//         type == 'textfield' ||
//         type == 'textarea' ||
//         type == 'email' ||
//         type == 'phone' ||
//         type == 'number' ||
//         type == 'integer' ||
//         type == 'int' ||
//         type == 'decimal' ||
//         type == 'double' ||
//         type == 'password' ||
//         type == 'otp' ||
//         type == 'formula') {
//       _writeTextField(buf, field, stateName, blocName);
//     } else if (type == 'dropdown' || type == 'api_dropdown') {
//       if (_isApiDropdown(field)) {
//         _writeApiDropdown(buf, field, stateName, blocName);
//       } else {
//         _writeStaticDropdown(buf, field, stateName, blocName);
//       }
//     } else if (type == 'radio' || type == 'radio buttons') {
//       _writeRadioGroup(buf, field, stateName, blocName);
//     } else if (type == 'date' || type == 'datetime' || type == 'date time' || type == 'time') {
//       _writeDatePicker(buf, field, stateName, blocName);
//     } else if (type == 'checkbox' || type == 'switch') {
//       _writeCheckbox(buf, field, stateName, blocName);
//     } else if (type == 'file' || type == 'image') {
//       _writeFileUpload(buf, field, stateName, blocName);
//     } else if (type == 'multiselect' || type == 'multi_select') {
//       _writeMultiSelect(buf, field, stateName, blocName);
//     } else {
//       _writePlaceholder(buf, field);
//     }
//   }

//   void _writeTextField(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final className = '${_cap(fieldKey)}Field';
//     final label = field['label'] ?? fieldKey;
//     final hint = field['placeholder'] ?? '';
//     final isArea = (field['type'] == 'textarea');
//     final maxLen = field['maxLength'];
//     final readOnly = field['readOnly'] == true;
//     final enabled = field['disable'] != true;
//     final obscure = field['obscureText'] == true;
//     final kbType = _flutterKeyboardType(field['keyboardType'] ?? '');
//     final capType = _flutterCapitalization(field['textCapitalization'] ?? '');
//     final inputAction = _flutterInputAction(field['textInputAction'] ?? '');

//     buf.writeln('class _$className extends StatefulWidget {');
//     buf.writeln('  const _$className({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  State<_$className> createState() => _${className}State();');
//     buf.writeln('}');
//     buf.writeln();
//     buf.writeln('class _${className}State extends State<_$className> {');
//     buf.writeln('  late final TextEditingController _controller;');
//     buf.writeln('  @override');
//     buf.writeln('  void initState() {');
//     buf.writeln('    super.initState();');
//     buf.writeln('    _controller = TextEditingController(');
//     buf.writeln("        text: context.read<$blocName>().state.formValues['$fieldKey']?.toString() ?? '');");
//     buf.writeln('  }');
//     buf.writeln('  @override');
//     buf.writeln('  void dispose() {');
//     buf.writeln('    _controller.dispose();');
//     buf.writeln('    super.dispose();');
//     buf.writeln('  }');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocConsumer<$blocName, $stateName>(');
//     buf.writeln("      listenWhen: (previous, current) => previous.formValues['$fieldKey'] != current.formValues['$fieldKey'],");
//     buf.writeln('      listener: (context, state) {');
//     buf.writeln("        final newValue = state.formValues['$fieldKey']?.toString() ?? '';");
//     buf.writeln('        if (_controller.text != newValue) _controller.text = newValue;');
//     buf.writeln('      },');
//     buf.writeln("      buildWhen: (previous, current) => false,");
//     buf.writeln('      builder: (context, state) {');
//     buf.writeln('        return AppTextField(');
//     buf.writeln('          controller: _controller,');
//     buf.writeln("          label: '${_escape(label)}',");
//     if (hint.isNotEmpty) buf.writeln("          hint: '${_escape(hint)}',");
//     buf.writeln('          errorText: null,');
//     if (readOnly) buf.writeln('          readOnly: true,');
//     if (!enabled) buf.writeln('          enabled: false,');
//     if (obscure) buf.writeln('          obscureText: true,');
//     if (maxLen != null) buf.writeln('          maxLength: $maxLen,');
//     if (isArea) {
//       buf.writeln('          maxLines: 5,');
//       buf.writeln('          minLines: 3,');
//     }
//     buf.writeln('          keyboardType: $kbType,');
//     buf.writeln('          textCapitalization: $capType,');
//     buf.writeln('          textInputAction: $inputAction,');
//     buf.writeln('          onChanged: (value) => context.read<$blocName>().add(');
//     buf.writeln("            ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('          ),');
//     buf.writeln('        );');
//     buf.writeln('      },');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeStaticDropdown(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     final optionsRaw = field['options'] as List<dynamic>? ?? [];
//     final options = optionsRaw.map((opt) => "'${_escape(opt.toString())}'").join(', ');
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
//     buf.writeln("      selector: (state) => state.formValues['$fieldKey']?.toString(),");
//     buf.writeln('      builder: (context, value) => AppDropdownField<String>(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        value: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        items: [$options],');
//     buf.writeln('        itemLabelBuilder: (item) => item,');
//     buf.writeln('        onChanged: (value) {');
//     buf.writeln('          if (value != null) {');
//     buf.writeln('            context.read<$blocName>().add(');
//     buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('            );');
//     buf.writeln('          }');
//     buf.writeln('        },');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeApiDropdown(
//     StringBuffer buf,
//     Map<String, dynamic> field,
//     String stateName,
//     String blocName,
//   ) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     final asyncFieldName = '${fieldKey}Async';
//     final listField = _listFieldName(field);
//     final innerEntityClass = _resolveInnerEntityClass(field);
//     final valueKey = field['dropdownValue']?.toString() ?? 'name';

//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocBuilder<$blocName, $stateName>(');
//     buf.writeln('      buildWhen: (previous, current) =>');
//     buf.writeln("          previous.$asyncFieldName != current.$asyncFieldName ||");
//     buf.writeln("          previous.formValues['$fieldKey'] != current.formValues['$fieldKey'],");
//     buf.writeln('      builder: (context, state) {');
//     buf.writeln("        final selectedId = state.formValues['$fieldKey']?.toString();");
//     buf.writeln('        final wrapperAsync = state.$asyncFieldName;');
//     buf.writeln('        late final AsyncValue<List<$innerEntityClass>> listAsync;');
//     buf.writeln('        wrapperAsync.when(');
//     buf.writeln('          idle: () => listAsync = const AsyncValue.idle(),');
//     buf.writeln('          loading: () => listAsync = const AsyncValue.loading(),');
//     buf.writeln('          data: (wrapper) => listAsync = AsyncValue.data(wrapper.$listField as List<$innerEntityClass>),');
//     buf.writeln('          error: (err) => listAsync = AsyncValue.error(err),');
//     buf.writeln('        );');
//     buf.writeln('        final options = listAsync.isData ? listAsync.data! : <$innerEntityClass>[];');
//     buf.writeln('        $innerEntityClass? selectedOption;');
//     buf.writeln('        try {');
//     buf.writeln('          selectedOption = options.firstWhere(');
//     buf.writeln("            (item) => _getDropdownLabel(item, '$valueKey') == selectedId,");
//     buf.writeln('          );');
//     buf.writeln('        } catch (_) {');
//     buf.writeln('          selectedOption = null;');
//     buf.writeln('        }');
//     buf.writeln('        return AppAsyncDropdownField<$innerEntityClass>(');
//     buf.writeln("          label: '${_escape(label)}',");
//     buf.writeln('          asyncState: _toAsyncState(listAsync),');
//     buf.writeln('          value: selectedOption,');
//     buf.writeln("          itemLabelBuilder: (item) => _getDropdownLabel(item, '$valueKey'),");
//     buf.writeln('          errorText: null,');
//     if (_hasAsync) {
//       buf.writeln('          onRetry: () => context.read<$blocName>().add(const Load${featureName}DataEvent()),');
//     } else {
//       buf.writeln('          onRetry: null,');
//     }
//     buf.writeln('          onChanged: (value) {');
//     buf.writeln('            if (value != null) {');
//     buf.writeln('              context.read<$blocName>().add(');
//     buf.writeln('                ${featureName}FieldChangedEvent(');
//     buf.writeln("                  fieldName: '$fieldKey',");
//     buf.writeln("                  value: _getDropdownLabel(value, '$valueKey'),");
//     buf.writeln('                ),');
//     buf.writeln('              );');
//     buf.writeln('            }');
//     buf.writeln('          },');
//     buf.writeln('        );');
//     buf.writeln('      },');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeRadioGroup(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     final optionsRaw = field['options'] as List<dynamic>? ?? ['Option 1', 'Option 2'];
//     final options = optionsRaw.map((opt) => "'${_escape(opt.toString())}'").join(', ');
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
//     buf.writeln("      selector: (state) => state.formValues['$fieldKey']?.toString(),");
//     buf.writeln('      builder: (context, value) => AppRadioGroupField(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        options: [$options],');
//     buf.writeln('        value: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        onChanged: (value) {');
//     buf.writeln('          if (value != null) {');
//     buf.writeln('            context.read<$blocName>().add(');
//     buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('            );');
//     buf.writeln('          }');
//     buf.writeln('        },');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeDatePicker(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, DateTime?>(');
//     buf.writeln("      selector: (state) => state.formValues['$fieldKey'] as DateTime?,");
//     buf.writeln('      builder: (context, value) => AppDatePickerField(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        value: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        onChanged: (value) {');
//     buf.writeln('          if (value != null) {');
//     buf.writeln('            context.read<$blocName>().add(');
//     buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('            );');
//     buf.writeln('          }');
//     buf.writeln('        },');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeCheckbox(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
//     buf.writeln("      selector: (state) => state.formValues['$fieldKey'] as bool? ?? false,");
//     buf.writeln('      builder: (context, value) => AppCheckboxField(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        value: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
//     buf.writeln("          ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value ?? false),");
//     buf.writeln('        ),');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeFileUpload(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
//     buf.writeln("      selector: (state) => state.formValues['$fieldKey']?.toString(),");
//     buf.writeln('      builder: (context, value) => AppFileUploadField(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        value: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        onChanged: (value) {');
//     buf.writeln('          if (value != null) {');
//     buf.writeln('            context.read<$blocName>().add(');
//     buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('            );');
//     buf.writeln('          }');
//     buf.writeln('        },');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writeMultiSelect(StringBuffer buf, Map<String, dynamic> field, String stateName, String blocName) {
//     final fieldKey = _fieldName(field);
//     final label = field['label'] ?? fieldKey;
//     final optionsRaw = field['options'] as List<dynamic>? ?? ['Option 1', 'Option 2', 'Option 3'];
//     final options = optionsRaw.map((opt) => "'${_escape(opt.toString())}'").join(', ');
//     buf.writeln('class _${_cap(fieldKey)}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(fieldKey)}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return BlocSelector<$blocName, $stateName, List<String>>(');
//     buf.writeln("      selector: (state) => (state.formValues['$fieldKey'] as List<dynamic>?)?.cast<String>() ?? [],");
//     buf.writeln('      builder: (context, value) => AppMultiSelectField(');
//     buf.writeln("        label: '${_escape(label)}',");
//     buf.writeln('        options: [$options],');
//     buf.writeln('        selectedValues: value,');
//     buf.writeln('        errorText: null,');
//     buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
//     buf.writeln("          ${featureName}FieldChangedEvent(fieldName: '$fieldKey', value: value),");
//     buf.writeln('        ),');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   void _writePlaceholder(StringBuffer buf, Map<String, dynamic> field) {
//     final label = field['label'] ?? _fieldName(field);
//     buf.writeln('class _${_cap(_fieldName(field))}Field extends StatelessWidget {');
//     buf.writeln('  const _${_cap(_fieldName(field))}Field({super.key});');
//     buf.writeln('  @override');
//     buf.writeln('  Widget build(BuildContext context) {');
//     buf.writeln('    return FormFieldWrapper(');
//     buf.writeln("      label: '${_escape(label)}',");
//     buf.writeln('      child: Container(');
//     buf.writeln('        padding: const EdgeInsets.all(16),');
//     buf.writeln('        decoration: BoxDecoration(');
//     buf.writeln('          color: const Color(0xFFF1F5F9),');
//     buf.writeln('          borderRadius: BorderRadius.circular(12),');
//     buf.writeln('          border: Border.all(color: const Color(0xFFE2E8F0)),');
//     buf.writeln('        ),');
//     buf.writeln('        child: const Center(');
//     buf.writeln("          child: Text('Component not implemented in generator yet', style: TextStyle(color: Color(0xFF64748B))),");
//     buf.writeln('        ),');
//     buf.writeln('      ),');
//     buf.writeln('    );');
//     buf.writeln('  }');
//     buf.writeln('}');
//   }

//   // --------------------------------------------------------------------------
//   // Helpers for names and types
//   // --------------------------------------------------------------------------
//   bool _isFormField(Map<String, dynamic> field) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     const skip = {'card', 'group', 'section', 'step', 'tab', 'container'};
//     return !skip.contains(type);
//   }

//   bool _isApiDropdown(Map<String, dynamic> field) {
//     final type = (field['type'] ?? '').toString().toLowerCase();
//     if (type != 'dropdown' && type != 'api_dropdown') return false;
//     final useStatic = field['useStaticOptions'] == true;
//     final hasApiUrl = field['dropdownApiUrl'] != null;
//     return !useStatic && hasApiUrl;
//   }

//   String _fieldName(Map<String, dynamic> f) {
//     final raw = (f['label'] ?? f['id'] ?? f['fieldId'] ?? 'field').toString().trim();
//     final n = raw.replaceAll(RegExp(r'\s+'), '');
//     return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
//   }

//   String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
//   String _escape(String s) => s.replaceAll("'", "\\'");

//   String _resolveEntityFile(Map<String, dynamic> field) {
//     final entityClass = _resolveEntityClass(field);
//     final base = entityClass.replaceAll('Entity', '');
//     return _toSnakeCase(base);
//   }

//   String _resolveInnerEntityFile(Map<String, dynamic> field) {
//     final innerClass = _resolveInnerEntityClass(field);
//     final base = innerClass.replaceAll('Entity', '');
//     return _toSnakeCase(base);
//   }

//   String _resolveEntityClass(Map<String, dynamic> field) {
//     final explicit = field['entityName'] ?? field['referenceEntity'];
//     if (explicit != null && explicit.toString().trim().isNotEmpty) {
//       var value = explicit.toString().trim();
//       if (!value.endsWith('Entity')) value = '${value}Entity';
//       return value;
//     }
//     final dropdowndata = field['dropdowndata'];
//     if (dropdowndata is Map<String, dynamic>) {
//       for (final entry in dropdowndata.entries) {
//         final v = entry.value;
//         if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
//           return '${_cap(_singularize(entry.key))}Entity';
//         }
//       }
//     }
//     final label = field['label'] ?? field['id'] ?? 'item';
//     return '${_cap(_singularize(label))}Entity';
//   }

//   String _resolveInnerEntityClass(Map<String, dynamic> field) {
//     final dropdowndata = field['dropdowndata'];
//     if (dropdowndata is Map<String, dynamic>) {
//       for (final entry in dropdowndata.entries) {
//         final v = entry.value;
//         if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
//           return '${_cap(_singularize(entry.key))}Entity';
//         }
//       }
//     }
//     final label = field['label'] ?? field['id'] ?? 'item';
//     return '${_cap(_singularize(label))}Entity';
//   }

//   String _listFieldName(Map<String, dynamic> field) {
//     final explicit = field['listFieldName'];
//     if (explicit != null && explicit.toString().isNotEmpty) {
//       return explicit.toString();
//     }
//     final dropdowndata = field['dropdowndata'];
//     if (dropdowndata is Map<String, dynamic>) {
//       for (final entry in dropdowndata.entries) {
//         final v = entry.value;
//         if (v is List) {
//           return entry.key;
//         }
//       }
//     }
//     return 'items';
//   }

//   String _singularize(String text) {
//     if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
//     if (text.endsWith('s') && text.length > 1) return text.substring(0, text.length - 1);
//     return text;
//   }

//   String _toSnakeCase(String input) {
//     if (input.isEmpty) return input;
//     final buffer = StringBuffer();
//     buffer.write(input[0].toLowerCase());
//     for (int i = 1; i < input.length; i++) {
//       final char = input[i];
//       if (char.toUpperCase() == char && RegExp(r'[A-Z]').hasMatch(char)) {
//         buffer.write('_${char.toLowerCase()}');
//       } else {
//         buffer.write(char);
//       }
//     }
//     return buffer.toString();
//   }

//   String _flutterKeyboardType(String? type) {
//     switch (type?.toLowerCase()) {
//       case 'emailaddress': case 'email': return 'TextInputType.emailAddress';
//       case 'number': return 'TextInputType.number';
//       case 'phone': return 'TextInputType.phone';
//       case 'multiline': return 'TextInputType.multiline';
//       case 'url': return 'TextInputType.url';
//       case 'visiblepassword': return 'TextInputType.visiblePassword';
//       default: return 'TextInputType.text';
//     }
//   }

//   String _flutterCapitalization(String? cap) {
//     switch (cap?.toLowerCase()) {
//       case 'words': return 'TextCapitalization.words';
//       case 'sentences': return 'TextCapitalization.sentences';
//       case 'characters': return 'TextCapitalization.characters';
//       default: return 'TextCapitalization.none';
//     }
//   }

//   String _flutterInputAction(String? action) {
//     switch (action?.toLowerCase()) {
//       case 'next': return 'TextInputAction.next';
//       case 'search': return 'TextInputAction.search';
//       case 'send': return 'TextInputAction.send';
//       case 'go': return 'TextInputAction.go';
//       case 'newline': return 'TextInputAction.newline';
//       default: return 'TextInputAction.done';
//     }
//   }
// }
