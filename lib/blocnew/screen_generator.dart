// lib/bloc/generators/screen/screen_generator.dart

import 'package:revojourneytryone/blocnew/field_schema.dart';

class ScreenGenerator {
  ScreenGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final snakeName = toSnakeCase(featureName);
    final stateName = '${featureName}FeatureState';
    final blocName  = '${featureName}Bloc';
    final keysClass = '${featureName}ComponentKeys';
    final buf       = StringBuffer();

    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_bloc.dart';");
    buf.writeln("import '../state/${snakeName}_feature_state.dart';");
    buf.writeln("import '../events/${snakeName}_event.dart';");
    buf.writeln("import '../../../../core/runtime/reactive_value.dart';");
    buf.writeln();

    // ── Screen ──────────────────────────────────────────────────────────────
    buf.writeln('class ${featureName}Screen extends StatelessWidget {');
    buf.writeln('  const ${featureName}Screen({super.key});');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocListener<$blocName, $stateName>(');
    buf.writeln('      listenWhen: (p, c) => p.submission != c.submission,');
    buf.writeln('      listener: (context, state) {');
    buf.writeln('        state.submission.maybeWhen(');
    buf.writeln("          success: (data) => _showSuccess(context, data.message ?? 'Submitted!'),");
    buf.writeln('          onFailure: (f)    => _showError(context, f.message),');
    buf.writeln('          orElse: () {},');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('      child: Scaffold(');
    buf.writeln("        backgroundColor: const Color(0xFFF0F4F8),");
    buf.writeln("        appBar: AppBar(");
    buf.writeln("          title: const Text('$featureName'),");
    buf.writeln("          backgroundColor: const Color(0xFF1A73E8),");
    buf.writeln("          foregroundColor: Colors.white,");
    buf.writeln("          elevation: 0,");
    buf.writeln("          actions: [");
    buf.writeln("            IconButton(");
    buf.writeln("              icon: const Icon(Icons.refresh_rounded),");
    buf.writeln("              tooltip: 'Reset',");
    buf.writeln("              onPressed: () => context.read<$blocName>()");
    buf.writeln("                  .add(const Reset${featureName}FormEvent()),");
    buf.writeln("            ),");
    buf.writeln("          ],");
    buf.writeln("        ),");
    buf.writeln('        body: const _${featureName}Body(),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln("  void _showSuccess(BuildContext ctx, String msg) =>");
    buf.writeln('    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(');
    buf.writeln("      content: Text(msg),");
    buf.writeln("      backgroundColor: Colors.green,");
    buf.writeln("      behavior: SnackBarBehavior.floating,");
    buf.writeln('    ));');
    buf.writeln();
    buf.writeln("  void _showError(BuildContext ctx, String msg) =>");
    buf.writeln('    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(');
    buf.writeln("      content: Text(msg),");
    buf.writeln("      backgroundColor: Colors.red,");
    buf.writeln("      behavior: SnackBarBehavior.floating,");
    buf.writeln('    ));');
    buf.writeln('}');
    buf.writeln();

    // ── Body ─────────────────────────────────────────────────────────────────
    buf.writeln('class _${featureName}Body extends StatelessWidget {');
    buf.writeln('  const _${featureName}Body();');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return SingleChildScrollView(');
    buf.writeln('      padding: const EdgeInsets.all(16),');
    buf.writeln('      child: Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    for (final f in fields) {
      if (f.isHidden) continue;
      buf.writeln("          _${toCap(f.fieldName)}Field(key: const ValueKey('${f.fieldName}')),");
      buf.writeln('          const SizedBox(height: 16),');
    }
    buf.writeln('          _SubmitButton(),');
    buf.writeln('          const SizedBox(height: 32),');
    buf.writeln('        ],');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ── Per-field widget classes ──────────────────────────────────────────────
    for (final f in fields) {
      if (f.isHidden) continue;
      _writeFieldClass(buf, f, stateName, blocName, keysClass);
      buf.writeln();
    }

    // ── Submit button ─────────────────────────────────────────────────────────
    buf.writeln('class _SubmitButton extends StatelessWidget {');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocSelector<$blocName, $stateName, bool>(');
    buf.writeln('      selector: (s) => s.isSubmitting,');
    buf.writeln('      builder: (ctx, busy) => SizedBox(');
    buf.writeln('        width: double.infinity,');
    buf.writeln('        height: 52,');
    buf.writeln('        child: ElevatedButton(');
    buf.writeln('          style: ElevatedButton.styleFrom(');
    buf.writeln('            backgroundColor: const Color(0xFF1A73E8),');
    buf.writeln('            foregroundColor: Colors.white,');
    buf.writeln('            shape: RoundedRectangleBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12)),');
    buf.writeln('          ),');
    buf.writeln('          onPressed: busy ? null : () =>');
    buf.writeln('              ctx.read<$blocName>().add(const Submit${featureName}FormEvent()),');
    buf.writeln('          child: busy');
    buf.writeln('              ? const SizedBox(height: 22, width: 22,');
    buf.writeln('                  child: CircularProgressIndicator(');
    buf.writeln('                    color: Colors.white, strokeWidth: 2.5))');
    buf.writeln("              : const Text('Submit',");
    buf.writeln('                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),');
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Field class writers
  // ─────────────────────────────────────────────────────────────────────────

  void _writeFieldClass(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    // Text-input types need StatefulWidget + TextEditingController so that
    // external state changes (form reset) properly clear the displayed text.
    final isTextInput = switch (f.fieldType) {
      FieldType.text ||
      FieldType.email ||
      FieldType.phone ||
      FieldType.number ||
      FieldType.decimal ||
      FieldType.password ||
      FieldType.textarea => true,
      FieldType.dropdown => !f.isStaticStringOnly && !f.isAsyncDropdown,
      _ => false,
    };

    if (isTextInput) {
      _writeTextFieldStateful(buf, f, s, b, k);
      return;
    }

    buf.writeln('class _${toCap(f.fieldName)}Field extends StatelessWidget {');
    buf.writeln('  const _${toCap(f.fieldName)}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');

    switch (f.fieldType) {
      case FieldType.dropdown:
        if (f.isStaticStringOnly) {
          _writeStaticStringDropdown(buf, f, s, b, k);
        } else {
          _writeApiDropdown(buf, f, s, b, k);
        }
      case FieldType.radio:
        _writeRadioGroup(buf, f, s, b, k);
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
        _writeDatePicker(buf, f, s, b, k);
      case FieldType.checkbox:
        _writeCheckbox(buf, f, s, b, k);
      case FieldType.file:
      case FieldType.image:
      case FieldType.fileUpload:
        _writeFileUpload(buf, f, s, b, k);
      case FieldType.multiSelect:
        _writeMultiSelect(buf, f, s, b, k);
      default:
        _writeApiDropdown(buf, f, s, b, k);
    }

    buf.writeln('  }');
    buf.writeln('}');
  }

  void _writeTextFieldStateful(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    final kbType   = _flutterKeyboardType(f.keyboardType);
    final capType  = _flutterCapitalization(f.textCapitalization);
    final action   = _flutterInputAction(f.textInputAction);
    final hintText = f.hint ?? '';
    final cap      = toCap(f.fieldName);
    final isArea   = f.fieldType == FieldType.textarea;

    buf.writeln('class _${cap}Field extends StatefulWidget {');
    buf.writeln('  const _${cap}Field({super.key});');
    buf.writeln('  @override');
    buf.writeln('  State<_${cap}Field> createState() => _${cap}FieldState();');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('class _${cap}FieldState extends State<_${cap}Field> {');
    buf.writeln('  late final TextEditingController _ctrl;');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  void initState() {');
    buf.writeln('    super.initState();');
    buf.writeln('    _ctrl = TextEditingController(');
    buf.writeln("        text: context.read<$b>().state.${f.fieldName}Field.value);");
    buf.writeln('  }');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  void dispose() {');
    buf.writeln('    _ctrl.dispose();');
    buf.writeln('    super.dispose();');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocConsumer<$b, $s>(');
    buf.writeln('      listenWhen: (prev, curr) =>');
    buf.writeln('          prev.${f.fieldName}Field.value != curr.${f.fieldName}Field.value,');
    buf.writeln('      listener: (ctx, state) {');
    buf.writeln('        final newVal = state.${f.fieldName}Field.value;');
    buf.writeln('        if (_ctrl.text != newVal) _ctrl.text = newVal;');
    buf.writeln('      },');
    buf.writeln('      buildWhen: (prev, curr) =>');
    buf.writeln('          prev.${f.fieldName}Field.hasError != curr.${f.fieldName}Field.hasError,');
    buf.writeln('      builder: (ctx, state) {');
    buf.writeln('        final field = state.${f.fieldName}Field;');
    buf.writeln('        return TextFormField(');
    buf.writeln('          controller: _ctrl,');
    if (f.isReadOnly)         buf.writeln('          readOnly: true,');
    if (f.isDisabled)         buf.writeln('          enabled: false,');
    if (f.obscureText)        buf.writeln('          obscureText: true,');
    if (!f.autocorrect)       buf.writeln('          autocorrect: false,');
    if (!f.enableSuggestions) buf.writeln('          enableSuggestions: false,');
    if (f.maxLength != null)  buf.writeln('          maxLength: ${f.maxLength},');
    if (isArea) {
      buf.writeln('          maxLines: 5,');
      buf.writeln('          minLines: 3,');
    }
    buf.writeln('          keyboardType: $kbType,');
    buf.writeln('          textCapitalization: $capType,');
    buf.writeln('          textInputAction: $action,');
    buf.writeln('          decoration: InputDecoration(');
    buf.writeln("            labelText: '${_esc(f.label)}',");
    if (hintText.isNotEmpty) {
      buf.writeln("            hintText: '${_esc(hintText)}',");
    }
    buf.writeln('            errorText: field.hasError ? field.error?.message : null,');
    buf.writeln('            filled: true,');
    buf.writeln('            fillColor: const Color(0xFFF8F9FA),');
    if (isArea) buf.writeln('            alignLabelWithHint: true,');
    buf.writeln('            border: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12)),');
    buf.writeln('            enabledBorder: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln("                borderSide: const BorderSide(color: Color(0xFFDEE2E6))),");
    buf.writeln('            focusedBorder: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln("                borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.8)),");
    buf.writeln('            errorBorder: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln("                borderSide: const BorderSide(color: Colors.red, width: 1.5)),");
    buf.writeln('            focusedErrorBorder: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln("                borderSide: const BorderSide(color: Colors.red, width: 1.8)),");
    buf.writeln('          ),');
    buf.writeln('          onChanged: (v) => ctx.read<$b>().add(');
    buf.writeln('            ComponentUpdatedEvent($k.${f.fieldName}, v)),');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
  }

  void _writeStaticStringDropdown(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    final opts = f.staticStringValues.map((v) => "'${_esc(v)}'").join(', ');
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<String>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) => DropdownButtonFormField<String>(');
    buf.writeln('        value: field.value.isEmpty ? null : field.value,');
    buf.writeln("        hint: const Text('Select ${_esc(f.label)}'),");
    buf.writeln('        isExpanded: true,');
    buf.writeln('        decoration: InputDecoration(');
    buf.writeln("          labelText: '${_esc(f.label)}',");
    buf.writeln('          errorText: field.hasError ? field.error?.message : null,');
    buf.writeln('          filled: true,');
    buf.writeln('          fillColor: const Color(0xFFF8F9FA),');
    buf.writeln('          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),');
    buf.writeln('        ),');
    buf.writeln('        items: [$opts].map((v) =>');
    buf.writeln('          DropdownMenuItem(value: v, child: Text(v))).toList(),');
    buf.writeln('        onChanged: (v) { if (v != null) ctx.read<$b>().add(');
    buf.writeln('          ComponentUpdatedEvent($k.${f.fieldName}, v)); },');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeApiDropdown(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    // ✅ FIX: dropdownValue is dynamic — safe toString with fallback
    final labelKey = (f.dropdownValue?.toString().isNotEmpty == true)
        ? toCamelCase(f.dropdownValue.toString())
        : 'title';
    buf.writeln('    return BlocBuilder<$b, $s>(');
    buf.writeln('      buildWhen: (p, c) =>');
    buf.writeln('          p.${f.fieldName}Options != c.${f.fieldName}Options ||');
    buf.writeln('          p.${f.fieldName}Field   != c.${f.fieldName}Field   ||');
    buf.writeln('          p.${f.fieldName}State   != c.${f.fieldName}State,');
    buf.writeln('      builder: (ctx, state) {');
    buf.writeln('        final opts  = state.${f.fieldName}Options;');
    buf.writeln('        final field = state.${f.fieldName}Field;');
    buf.writeln('        final async = state.${f.fieldName}State;');
    // Loading state: keep full dropdown height to prevent layout shift
    buf.writeln('        if (async.isLoading)');
    buf.writeln('          return DropdownButtonFormField<String>(');
    buf.writeln('            value: null, items: const [], onChanged: null,');
    buf.writeln('            isExpanded: true,');
    buf.writeln("            hint: const Row(mainAxisSize: MainAxisSize.min, children: [");
    buf.writeln("              SizedBox(width: 14, height: 14,");
    buf.writeln("                child: CircularProgressIndicator(strokeWidth: 2)),");
    buf.writeln("              SizedBox(width: 8), Text('Loading…'),");
    buf.writeln("            ]),");
    buf.writeln('            decoration: InputDecoration(');
    buf.writeln("              labelText: '${_esc(f.label)}',");
    buf.writeln('              filled: true, fillColor: const Color(0xFFF8F9FA),');
    buf.writeln('              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),');
    buf.writeln('            ),');
    buf.writeln('          );');
    // Error state: same height, red border to signal failure
    buf.writeln('        if (async.isFailure)');
    buf.writeln('          return DropdownButtonFormField<String>(');
    buf.writeln('            value: null, items: const [], onChanged: null,');
    buf.writeln('            isExpanded: true,');
    buf.writeln("            hint: Text(async.failureOrNull?.message ?? 'Failed to load',");
    buf.writeln("              style: const TextStyle(color: Colors.red, fontSize: 13)),");
    buf.writeln('            decoration: InputDecoration(');
    buf.writeln("              labelText: '${_esc(f.label)}',");
    buf.writeln('              filled: true, fillColor: const Color(0xFFF8F9FA),');
    buf.writeln('              border: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln('                borderSide: const BorderSide(color: Colors.red)),');
    buf.writeln('              enabledBorder: OutlineInputBorder(');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln('                borderSide: const BorderSide(color: Colors.red)),');
    buf.writeln('            ),');
    buf.writeln('          );');
    buf.writeln('        return DropdownButtonFormField<String>(');
    buf.writeln('          value: field.value?.toString().isEmpty == true ? null : field.value?.toString(),');
    buf.writeln("          hint: const Text('Select ${_esc(f.label)}'),");
    buf.writeln('          isExpanded: true,');
    buf.writeln('          decoration: InputDecoration(');
    buf.writeln("            labelText: '${_esc(f.label)}',");
    buf.writeln('            errorText: field.hasError ? field.error?.message : null,');
    buf.writeln('            filled: true,');
    buf.writeln('            fillColor: const Color(0xFFF8F9FA),');
    buf.writeln('            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),');
    buf.writeln('          ),');
    buf.writeln('          items: opts.map((e) => DropdownMenuItem(');
    buf.writeln("            value: e.$labelKey.toString(),");
    buf.writeln("            child: Text(e.$labelKey.toString()),");
    buf.writeln('          )).toList(),');
    buf.writeln('          onChanged: (v) { if (v != null) ctx.read<$b>().add(');
    buf.writeln('            ComponentUpdatedEvent($k.${f.fieldName}, v)); },');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
  }

  void _writeRadioGroup(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    final opts = f.isStaticStringOnly
        ? f.staticStringValues
        : ['Option1', 'Option2', 'Option3'];
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<String>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) => Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    buf.writeln("          Text('${_esc(f.label)}',");
    buf.writeln('            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),');
    buf.writeln('          const SizedBox(height: 4),');
    buf.writeln('          Container(');
    buf.writeln('            decoration: BoxDecoration(');
    buf.writeln('              border: Border.all(color: field.hasError');
    buf.writeln('                  ? Colors.red : const Color(0xFFDEE2E6)),');
    buf.writeln('              borderRadius: BorderRadius.circular(12),');
    buf.writeln('              color: const Color(0xFFF8F9FA),');
    buf.writeln('            ),');
    buf.writeln('            child: Column(');
    buf.writeln('              children: [');
    for (final opt in opts) {
      buf.writeln('                RadioListTile<String>(');
      buf.writeln("                  value: '${_esc(opt)}',");
      buf.writeln('                  groupValue: field.value.isEmpty ? null : field.value,');
      buf.writeln("                  title: const Text('${_esc(opt)}'),");
      buf.writeln('                  dense: true,');
      buf.writeln('                  onChanged: (v) { if (v != null) ctx.read<$b>().add(');
      buf.writeln('                    ComponentUpdatedEvent($k.${f.fieldName}, v)); },');
      buf.writeln('                ),');
    }
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('          ),');
    buf.writeln('          if (field.hasError)');
    buf.writeln('            Padding(');
    buf.writeln('              padding: const EdgeInsets.only(left: 12, top: 4),');
    // ✅ FIX: field.error?.message instead of field.error!.message
    buf.writeln("              child: Text(field.error?.message ?? '',");
    buf.writeln('                style: const TextStyle(color: Colors.red, fontSize: 12))),');
    buf.writeln('        ],');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeDatePicker(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<DateTime?>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) {');
    buf.writeln("        final display = field.value == null ? 'Select date'");
    // ✅ FIX: safe null check with ?? instead of !
    buf.writeln("            : '\${field.value?.day.toString().padLeft(2, \"0\") ?? \"\"}/\${field.value?.month.toString().padLeft(2, \"0\") ?? \"\"}/\${field.value?.year ?? \"\"}';");
    buf.writeln('        return GestureDetector(');
    buf.writeln('          onTap: () async {');
    buf.writeln('            final picked = await showDatePicker(');
    buf.writeln('              context: ctx,');
    buf.writeln('              initialDate: DateTime(2000),');
    buf.writeln('              firstDate: DateTime(1900),');
    buf.writeln('              lastDate: DateTime.now(),');
    buf.writeln('            );');
    buf.writeln('            if (picked != null && ctx.mounted) {');
    buf.writeln('              ctx.read<$b>().add(');
    buf.writeln('                ComponentUpdatedEvent($k.${f.fieldName}, picked));');
    buf.writeln('            }');
    buf.writeln('          },');
    buf.writeln('          child: InputDecorator(');
    buf.writeln('            decoration: InputDecoration(');
    buf.writeln("              labelText: '${_esc(f.label)}',");
    buf.writeln('              suffixIcon: const Icon(Icons.calendar_today_outlined),');
    buf.writeln('              errorText: field.hasError ? field.error?.message : null,');
    buf.writeln('              filled: true,');
    buf.writeln('              fillColor: const Color(0xFFF8F9FA),');
    buf.writeln('              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),');
    buf.writeln('            ),');
    buf.writeln('            child: Text(display,');
    buf.writeln('              style: TextStyle(color: field.value == null ? Colors.grey : Colors.black87)),');
    buf.writeln('          ),');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
  }

  void _writeCheckbox(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<bool>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) => Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    buf.writeln('          CheckboxListTile(');
    buf.writeln('            value: field.value,');
    buf.writeln("            title: const Text('${_esc(f.label)}'),");
    buf.writeln('            controlAffinity: ListTileControlAffinity.leading,');
    buf.writeln('            contentPadding: EdgeInsets.zero,');
    buf.writeln('            onChanged: (v) => ctx.read<$b>().add(');
    buf.writeln('              ComponentUpdatedEvent($k.${f.fieldName}, v ?? false)),');
    buf.writeln('          ),');
    buf.writeln('          if (field.hasError)');
    buf.writeln('            Padding(');
    buf.writeln('              padding: const EdgeInsets.only(left: 12),');
    // ✅ FIX: field.error?.message instead of field.error!.message
    buf.writeln("              child: Text(field.error?.message ?? '',");
    buf.writeln('                style: const TextStyle(color: Colors.red, fontSize: 12))),');
    buf.writeln('        ],');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  void _writeFileUpload(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<dynamic>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) {');
    buf.writeln('        final file = field.value as dynamic;');
    // ✅ FIX: safe null check on file path
    buf.writeln("        final name = file == null ? 'No file selected' : file.toString();");
    buf.writeln('        return Column(');
    buf.writeln('          crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('          children: [');
    buf.writeln("            Text('${_esc(f.label)}',");
    buf.writeln('              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),');
    buf.writeln('            const SizedBox(height: 6),');
    buf.writeln('            Container(');
    buf.writeln('              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),');
    buf.writeln('              decoration: BoxDecoration(');
    buf.writeln('                border: Border.all(color: field.hasError');
    buf.writeln('                    ? Colors.red : const Color(0xFFDEE2E6)),');
    buf.writeln('                borderRadius: BorderRadius.circular(12),');
    buf.writeln('                color: const Color(0xFFF8F9FA),');
    buf.writeln('              ),');
    buf.writeln('              child: Row(');
    buf.writeln('                children: [');
    buf.writeln('                  Expanded(');
    buf.writeln('                    child: Text(name,');
    buf.writeln('                      style: TextStyle(');
    buf.writeln('                        color: file == null ? Colors.grey : Colors.black87,');
    buf.writeln('                        overflow: TextOverflow.ellipsis),');
    buf.writeln('                      maxLines: 1),');
    buf.writeln('                  ),');
    buf.writeln('                  const SizedBox(width: 8),');
    buf.writeln('                  ElevatedButton.icon(');
    buf.writeln('                    style: ElevatedButton.styleFrom(');
    buf.writeln('                      backgroundColor: const Color(0xFF1A73E8),');
    buf.writeln('                      foregroundColor: Colors.white,');
    buf.writeln('                      shape: RoundedRectangleBorder(');
    buf.writeln('                          borderRadius: BorderRadius.circular(8)),');
    buf.writeln('                    ),');
    buf.writeln('                    icon: const Icon(Icons.upload_file, size: 18),');
    buf.writeln("                    label: const Text('Browse'),");
    buf.writeln('                    onPressed: () async {');
    buf.writeln('                      // TODO: integrate file_picker package');
    buf.writeln('                      // final result = await FilePicker.platform.pickFiles();');
    buf.writeln('                      // if (result != null && ctx.mounted) {');
    buf.writeln('                      //   ctx.read<$b>().add(ComponentUpdatedEvent(');
    buf.writeln('                      //     $k.${f.fieldName}, result.files.single.path));');
    buf.writeln('                      // }');
    buf.writeln('                    },');
    buf.writeln('                  ),');
    buf.writeln('                ],');
    buf.writeln('              ),');
    buf.writeln('            ),');
    buf.writeln('            if (field.hasError)');
    buf.writeln('              Padding(');
    buf.writeln('                padding: const EdgeInsets.only(left: 12, top: 4),');
    // ✅ FIX: field.error?.message instead of field.error!.message
    buf.writeln("                child: Text(field.error?.message ?? '',");
    buf.writeln('                  style: const TextStyle(color: Colors.red, fontSize: 12))),');
    buf.writeln("            const Padding(");
    buf.writeln('              padding: EdgeInsets.only(left: 12, top: 4),');
    buf.writeln("              child: Text('Accepted: PDF, JPG, PNG · Max 5 MB',");
    buf.writeln('                style: TextStyle(color: Colors.grey, fontSize: 11))),');
    buf.writeln('          ],');
    buf.writeln('        );');
    buf.writeln('      },');
    buf.writeln('    );');
  }

  void _writeMultiSelect(StringBuffer buf, FieldSchema f, String s, String b, String k) {
    final opts = f.staticStringValues.isNotEmpty
        ? f.staticStringValues.map((v) => "'${_esc(v)}'").join(', ')
        : "'Option1', 'Option2', 'Option3'";
    buf.writeln('    return BlocSelector<$b, $s, ReactiveValue<List<String>>>(');
    buf.writeln('      selector: (state) => state.${f.fieldName}Field,');
    buf.writeln('      builder: (ctx, field) => Column(');
    buf.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('        children: [');
    buf.writeln("          Text('${_esc(f.label)}',");
    buf.writeln('              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),');
    buf.writeln('          const SizedBox(height: 8),');
    buf.writeln('          Wrap(');
    buf.writeln('            spacing: 8,');
    buf.writeln('            children: [$opts].map((opt) {');
    buf.writeln('              final selected = field.value.contains(opt);');
    buf.writeln('              return FilterChip(');
    buf.writeln('                label: Text(opt),');
    buf.writeln('                selected: selected,');
    buf.writeln('                onSelected: (_) {');
    buf.writeln('                  final current = List<String>.from(field.value);');
    buf.writeln('                  selected ? current.remove(opt) : current.add(opt);');
    buf.writeln('                  ctx.read<$b>().add(');
    buf.writeln('                    ComponentUpdatedEvent($k.${f.fieldName}, current));');
    buf.writeln('                },');
    buf.writeln('              );');
    buf.writeln('            }).toList(),');
    buf.writeln('          ),');
    buf.writeln('          if (field.hasError)');
    buf.writeln('            Padding(');
    buf.writeln('              padding: const EdgeInsets.only(top: 4),');
    // ✅ FIX: field.error?.message instead of field.error!.message
    buf.writeln("              child: Text(field.error?.message ?? '',");
    buf.writeln('                style: const TextStyle(color: Colors.red, fontSize: 12))),');
    buf.writeln('        ],');
    buf.writeln('      ),');
    buf.writeln('    );');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Escape single quotes inside generated string literals
  String _esc(String s) => s.replaceAll("'", "\\'");

  String _flutterKeyboardType(String kt) => switch (kt.toLowerCase()) {
        'emailaddress' || 'email' => 'TextInputType.emailAddress',
        'number'                  => 'TextInputType.number',
        'phone'                   => 'TextInputType.phone',
        'multiline'               => 'TextInputType.multiline',
        'url'                     => 'TextInputType.url',
        'visiblepassword'         => 'TextInputType.visiblePassword',
        _                         => 'TextInputType.text',
      };

  String _flutterCapitalization(String cap) => switch (cap.toLowerCase()) {
        'words'      => 'TextCapitalization.words',
        'sentences'  => 'TextCapitalization.sentences',
        'characters' => 'TextCapitalization.characters',
        _            => 'TextCapitalization.none',
      };

  String _flutterInputAction(String action) => switch (action.toLowerCase()) {
        'next'    => 'TextInputAction.next',
        'search'  => 'TextInputAction.search',
        'send'    => 'TextInputAction.send',
        'go'      => 'TextInputAction.go',
        'newline' => 'TextInputAction.newline',
        _         => 'TextInputAction.done',
      };
}
