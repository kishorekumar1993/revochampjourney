// lib/bloc/generators/screen/screen_generator.dart

import 'package:revojourneytryone/blocnew/field_schema.dart';

class ScreenGenerator {
  ScreenGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  bool get hasAsyncDropdown => fields.any((f) => f.isAsyncDropdown);

  String generate() {
    final snakeName = _toSnakeCase(featureName);
    final stateName = '${featureName}State';
    final blocName  = '${featureName}Bloc';
    final keysClass = '${featureName}ComponentKeys';
    final buf       = StringBuffer();

    // ─── Imports (all relative) ────────────────────────────────────────────
    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    // Core imports (relative from presentation/screens/ to core/)
    buf.writeln("import '../../../../core/runtime/reactive_value.dart';");
    buf.writeln("import '../../${snakeName}_feature.dart';");
    buf.writeln("import '/core/widgets/widgets.dart';");
    buf.writeln("import '/core/runtime/reactive_value.dart';");
    // Feature imports
    buf.writeln("import '../bloc/${snakeName}_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_state.dart';");
    buf.writeln("import '../bloc/${snakeName}_event.dart';");
    buf.writeln();

    // ─── Screen widget ──────────────────────────────────────────────────────
    buf.writeln('class ${featureName}Screen extends StatelessWidget {');
    buf.writeln('  const ${featureName}Screen({super.key});');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocListener<$blocName, $stateName>(');
    buf.writeln('      listenWhen: (previous, current) => previous.submissionAsync != current.submissionAsync,');
    buf.writeln('      listener: (context, state) {');
    buf.writeln('        state.submissionAsync.when(');
    buf.writeln('          idle: () {},');
    buf.writeln('          loading: () {},');
    buf.writeln("          data: (data) => _showSuccess(context, 'Submitted successfully'),");
    buf.writeln("          error: (error) => _showError(context, error.toString()),");
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('      child: Scaffold(');
    buf.writeln("        backgroundColor: const Color(0xFFF8FAFC),");
    buf.writeln("        appBar: AppBar(");
    buf.writeln("          title: const Text('$featureName', style: TextStyle(fontWeight: FontWeight.w600)),");
    buf.writeln("          backgroundColor: Colors.transparent,");
    buf.writeln("          foregroundColor: const Color(0xFF0F172A),");
    buf.writeln("          elevation: 0,");
    buf.writeln("          centerTitle: true,");
    buf.writeln("          actions: [");
    buf.writeln("            IconButton(");
    buf.writeln("              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),");
    buf.writeln("              tooltip: 'Reset',");
    buf.writeln("              onPressed: () => context.read<$blocName>().add(const Reset${featureName}Event()),");
    buf.writeln("            ),");
    buf.writeln("          ],");
    buf.writeln("        ),");
    buf.writeln('        body: const SafeArea(');
    buf.writeln('          child: _${featureName}Body(),');
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln("  void _showSuccess(BuildContext context, String message) {");
    buf.writeln("    ScaffoldMessenger.of(context).showSnackBar(SnackBar(");
    buf.writeln("      content: Text(message),");
    buf.writeln("      backgroundColor: const Color(0xFF10B981),");
    buf.writeln("      behavior: SnackBarBehavior.floating,");
    buf.writeln("    ));");
    buf.writeln("  }");
    buf.writeln();
    buf.writeln("  void _showError(BuildContext context, String message) {");
    buf.writeln("    ScaffoldMessenger.of(context).showSnackBar(SnackBar(");
    buf.writeln("      content: Text(message),");
    buf.writeln("      backgroundColor: const Color(0xFFEF4444),");
    buf.writeln("      behavior: SnackBarBehavior.floating,");
    buf.writeln("    ));");
    buf.writeln("  }");
    buf.writeln('}');
    buf.writeln();

    // ─── Body widget ────────────────────────────────────────────────────────
    buf.writeln('class _${featureName}Body extends StatelessWidget {');
    buf.writeln('  const _${featureName}Body();');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return Center(');
    buf.writeln('      child: ConstrainedBox(');
    buf.writeln('        constraints: const BoxConstraints(maxWidth: 600),');
    buf.writeln('        child: SingleChildScrollView(');
    buf.writeln('          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),');
    buf.writeln('          child: Container(');
    buf.writeln('            padding: const EdgeInsets.all(24),');
    buf.writeln('            decoration: BoxDecoration(');
    buf.writeln('              color: Colors.white,');
    buf.writeln('              borderRadius: BorderRadius.circular(20),');
    buf.writeln('              border: Border.all(color: const Color(0xFFE2E8F0)),');
    buf.writeln('              boxShadow: const [');
    buf.writeln('                BoxShadow(');
    buf.writeln('                  color: Color(0x0A000000),');
    buf.writeln('                  blurRadius: 20,');
    buf.writeln('                  offset: Offset(0, 10),');
    buf.writeln('                ),');
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('            child: Column(');
    buf.writeln('              crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('              children: [');
    for (final f in fields) {
      if (f.isHidden) continue;
      buf.writeln("                _${_toCap(f.fieldName)}Field(key: const ValueKey('${f.fieldName}')),");
    }
    buf.writeln('                const SizedBox(height: 12),');
    buf.writeln('                _SubmitButton(),');
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('          ),');
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ─── Field widgets ──────────────────────────────────────────────────────
    for (final f in fields) {
      if (f.isHidden) continue;
      _writeFieldClass(buf, f, stateName, blocName, keysClass);
      buf.writeln();
    }

    // ─── Submit button ──────────────────────────────────────────────────────
    buf.writeln('class _SubmitButton extends StatelessWidget {');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
    buf.writeln('      selector: (state) => state.submissionAsync.isLoading,');
    buf.writeln('      builder: (context, isSubmitting) => AppFormButton(');
    buf.writeln("        label: 'Submit',");
    buf.writeln("        loadingLabel: 'Submitting...',");
    buf.writeln('        state: isSubmitting ? AppButtonState.loading : AppButtonState.idle,');
    buf.writeln('        onPressed: () => context.read<$blocName>().add(const Submit${featureName}Event()),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }

  // --------------------------------------------------------------------------
  // Field widget builders
  // --------------------------------------------------------------------------

  void _writeFieldClass(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final isTextInput = switch (f.fieldType) {
      FieldType.text ||
      FieldType.email ||
      FieldType.phone ||
      FieldType.number ||
      FieldType.decimal ||
      FieldType.password ||
      FieldType.textarea => true,
      FieldType.slider ||
      FieldType.repeater ||
      FieldType.timeline ||
      FieldType.section ||
      FieldType.label ||
      FieldType.starRating ||
      FieldType.signature ||
      FieldType.grid => true,
      FieldType.dropdown => !f.isStaticStringOnly && !f.isAsyncDropdown,
      _ => false,
    };

    if (isTextInput) {
      _writeTextFieldStateful(buf, f, stateName, blocName, keysClass);
      return;
    }

    buf.writeln('class _${_toCap(f.fieldName)}Field extends StatelessWidget {');
    buf.writeln('  const _${_toCap(f.fieldName)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');

    switch (f.fieldType) {
      case FieldType.dropdown:
        if (f.isStaticStringOnly) {
          _writeStaticStringDropdown(buf, f, stateName, blocName, keysClass);
        } else {
          _writeApiDropdown(buf, f, stateName, blocName, keysClass);
        }
      case FieldType.radio:
        _writeRadioGroup(buf, f, stateName, blocName, keysClass);
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
        _writeDatePicker(buf, f, stateName, blocName, keysClass);
      case FieldType.checkbox:
        _writeCheckbox(buf, f, stateName, blocName, keysClass);
      case FieldType.file:
      case FieldType.image:
      case FieldType.fileUpload:
        _writeFileUpload(buf, f, stateName, blocName, keysClass);
      case FieldType.multiSelect:
        _writeMultiSelect(buf, f, stateName, blocName, keysClass);
      case FieldType.slider:
      case FieldType.repeater:
      case FieldType.timeline:
      case FieldType.section:
      case FieldType.label:
      case FieldType.starRating:
      case FieldType.signature:
      case FieldType.grid:
      case FieldType.autoComplete:
        _writePlaceholderField(buf, f, stateName, blocName, keysClass);
      default:
        _writePlaceholderField(buf, f, stateName, blocName, keysClass);
    }

    buf.writeln('  }');
    buf.writeln('}');
  }

  void _writeTextFieldStateful(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final kbType   = _flutterKeyboardType(f.keyboardType);
    final capType  = _flutterCapitalization(f.textCapitalization);
    final action   = _flutterInputAction(f.textInputAction);
    final hintText = f.hint ?? '';
    final cap      = _toCap(f.fieldName);
    final isArea   = f.fieldType == FieldType.textarea;

    buf.writeln('class _${cap}Field extends StatefulWidget {');
    buf.writeln('  const _${cap}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  State<_${cap}Field> createState() => _${cap}FieldState();');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('class _${cap}FieldState extends State<_${cap}Field> {');
    buf.writeln('  late final TextEditingController _controller;');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  void initState() {');
    buf.writeln('    super.initState();');
    buf.writeln('    _controller = TextEditingController(');
    buf.writeln("        text: context.read<$blocName>().state.formValues['${f.fieldName}']?.toString() ?? '');");
    buf.writeln('  }');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  void dispose() {');
    buf.writeln('    _controller.dispose();');
    buf.writeln('    super.dispose();');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocConsumer<$blocName, $stateName>(');
    buf.writeln("      listenWhen: (previous, current) => previous.formValues['${f.fieldName}'] != current.formValues['${f.fieldName}'],");
    buf.writeln('      listener: (context, state) {');
    buf.writeln("        final newValue = state.formValues['${f.fieldName}']?.toString() ?? '';");
    buf.writeln('        if (_controller.text != newValue) _controller.text = newValue;');
    buf.writeln('      },');
    buf.writeln("      buildWhen: (previous, current) => false,");
    buf.writeln('      builder: (context, state) {');
    buf.writeln('        return AppTextField(');
    buf.writeln('          controller: _controller,');
    buf.writeln("          label: '${_escape(f.label)}',");
    if (hintText.isNotEmpty) buf.writeln("          hint: '${_escape(hintText)}',");
    buf.writeln('          errorText: null,');
    if (f.isReadOnly)         buf.writeln('          readOnly: true,');
    if (f.isDisabled)         buf.writeln('          enabled: false,');
    if (f.obscureText)        buf.writeln('          obscureText: true,');
    if (f.maxLength != null)  buf.writeln('          maxLength: ${f.maxLength},');
    if (isArea) {
      buf.writeln('          maxLines: 5,');
      buf.writeln('          minLines: 3,');
    }
    buf.writeln('          keyboardType: $kbType,');
    buf.writeln('          textCapitalization: $capType,');
    buf.writeln('          textInputAction: $action,');
    buf.writeln('          onChanged: (value) => context.read<$blocName>().add(');
    buf.writeln("            ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: value),");
    buf.writeln('          ),');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void _writeStaticStringDropdown(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final options = f.staticStringValues.map((v) => "'${_escape(v)}'").join(', ');
    buf.writeln('    return BlocSelector<$blocName, $stateName, String>(');
    buf.writeln("      selector: (state) => state.formValues['${f.fieldName}']?.toString() ?? '',");
    buf.writeln('      builder: (context, value) => AppDropdownField<String>(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        value: value.isEmpty ? null : value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        items: [$options],');
    buf.writeln('        itemLabelBuilder: (item) => item,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: value),");
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeApiDropdown(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final labelKey = (f.dropdownValue?.toString().isNotEmpty == true)
        ? _toCamelCase(f.dropdownValue.toString())
        : 'title';
    buf.writeln('    return BlocBuilder<$blocName, $stateName>(');
    buf.writeln('      buildWhen: (previous, current) =>');
    buf.writeln("          previous.${f.fieldName}Async != current.${f.fieldName}Async ||");
    buf.writeln("          previous.formValues['${f.fieldName}'] != current.formValues['${f.fieldName}'],");
    buf.writeln('      builder: (context, state) {');
    buf.writeln("        final value = state.formValues['${f.fieldName}']?.toString() ?? '';");
    buf.writeln('        final async = state.${f.fieldName}Async;');
    buf.writeln('        final options = async.isData ? async.data! : [];');
    buf.writeln('        return AppAsyncDropdownField<dynamic>(');
    buf.writeln("          label: '${_escape(f.label)}',");
    buf.writeln('          asyncState: async,');
    buf.writeln('          value: value.isEmpty ? null : options.firstWhere(');
    buf.writeln('            (item) => item.$labelKey.toString() == value,');
    buf.writeln('            orElse: () => null,');
    buf.writeln('          ),');
    buf.writeln('          itemLabelBuilder: (item) => item.$labelKey.toString(),');
    buf.writeln('          errorText: null,');
    if (hasAsyncDropdown) {
      buf.writeln('          onRetry: () => context.read<$blocName>().add(const Load${featureName}DataEvent()),');
    } else {
      buf.writeln('          onRetry: () {},');
    }
    buf.writeln('          onChanged: (value) {');
    buf.writeln('            if (value != null) {');
    buf.writeln('              context.read<$blocName>().add(');
    buf.writeln("                ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val.$labelKey.toString()),");
    buf.writeln('              );');
    buf.writeln('            }');
    buf.writeln('          },');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
  }

  void _writeRadioGroup(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final options = f.isStaticStringOnly
        ? f.staticStringValues.map((v) => "'${_escape(v)}'").join(', ')
        : "'Option 1', 'Option 2'";
    buf.writeln('    return BlocSelector<$blocName, $stateName, String>(');
    buf.writeln("      selector: (state) => state.formValues['${f.fieldName}']?.toString() ?? '',");
    buf.writeln('      builder: (context, value) => AppRadioGroupField(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        options: [$options],');
    buf.writeln('        value: value.isEmpty ? null : value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val),");
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeDatePicker(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    buf.writeln('    return BlocSelector<$blocName, $stateName, DateTime?>(');
    buf.writeln("      selector: (state) => state.formValues['${f.fieldName}'] as DateTime?,");
    buf.writeln('      builder: (context, value) => AppDatePickerField(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val),");
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeCheckbox(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
    buf.writeln("      selector: (state) => state.formValues['${f.fieldName}'] as bool? ?? false,");
    buf.writeln('      builder: (context, value) => AppCheckboxField(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
    buf.writeln("          ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val ?? false),");
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeFileUpload(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    buf.writeln('    return BlocSelector<$blocName, $stateName, String?>(');
    buf.writeln("      selector: (state) => state.formValues['${f.fieldName}']?.toString(),");
    buf.writeln('      builder: (context, value) => AppFileUploadField(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        value: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) {');
    buf.writeln('          if (value != null) {');
    buf.writeln('            context.read<$blocName>().add(');
    buf.writeln("              ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val),");
    buf.writeln('            );');
    buf.writeln('          }');
    buf.writeln('        },');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeMultiSelect(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    final options = f.staticStringValues.isNotEmpty
        ? f.staticStringValues.map((v) => "'${_escape(v)}'").join(', ')
        : "'Option 1', 'Option 2', 'Option 3'";
    buf.writeln('    return BlocSelector<$blocName, $stateName, List<String>>(');
    buf.writeln("      selector: (state) => (state.formValues['${f.fieldName}'] as List<dynamic>?)?.cast<String>() ?? [],");
    buf.writeln('      builder: (context, value) => AppMultiSelectField(');
    buf.writeln("        label: '${_escape(f.label)}',");
    buf.writeln('        options: [$options],');
    buf.writeln('        selectedValues: value,');
    buf.writeln('        errorText: null,');
    buf.writeln('        onChanged: (value) => context.read<$blocName>().add(');
    buf.writeln("          ${featureName}FieldChangedEvent(fieldName: '${f.fieldName}', value: val),");
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writePlaceholderField(StringBuffer buf, FieldSchema f, String stateName, String blocName, String keysClass) {
    buf.writeln('    return FormFieldWrapper(');
    buf.writeln("      label: '${_escape(f.label)}',");
    buf.writeln('      child: Container(');
    buf.writeln('        padding: const EdgeInsets.all(16),');
    buf.writeln('        decoration: BoxDecoration(');
    buf.writeln('          color: const Color(0xFFF1F5F9),');
    buf.writeln('          borderRadius: BorderRadius.circular(12),');
    buf.writeln('          border: Border.all(color: const Color(0xFFE2E8F0)),');
    buf.writeln('        ),');
    buf.writeln('        child: const Center(');
    buf.writeln("          child: Text('Component not implemented in generator yet', style: TextStyle(color: Color(0xFF64748B))),");
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  // --------------------------------------------------------------------------
  // Helpers (all static)
  // --------------------------------------------------------------------------

  static String _escape(String s) => s.replaceAll("'", "\\'");

  static String _flutterKeyboardType(String keyboardType) {
    switch (keyboardType.toLowerCase()) {
      case 'emailaddress': case 'email': return 'TextInputType.emailAddress';
      case 'number': return 'TextInputType.number';
      case 'phone': return 'TextInputType.phone';
      case 'multiline': return 'TextInputType.multiline';
      case 'url': return 'TextInputType.url';
      case 'visiblepassword': return 'TextInputType.visiblePassword';
      default: return 'TextInputType.text';
    }
  }

  static String _flutterCapitalization(String capitalization) {
    switch (capitalization.toLowerCase()) {
      case 'words': return 'TextCapitalization.words';
      case 'sentences': return 'TextCapitalization.sentences';
      case 'characters': return 'TextCapitalization.characters';
      default: return 'TextCapitalization.none';
    }
  }

  static String _flutterInputAction(String inputAction) {
    switch (inputAction.toLowerCase()) {
      case 'next': return 'TextInputAction.next';
      case 'search': return 'TextInputAction.search';
      case 'send': return 'TextInputAction.send';
      case 'go': return 'TextInputAction.go';
      case 'newline': return 'TextInputAction.newline';
      default: return 'TextInputAction.done';
    }
  }

  static String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  static String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    final parts = input.split('_');
    final buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      buffer.write(_toCap(parts[i]));
    }
    return buffer.toString();
  }
}