import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';
import '../../../../journey_builder/presentation/providers/journey_provider.dart';
import '../advanced_formula_field_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIELD BUILD CONTEXT
// ─────────────────────────────────────────────────────────────────────────────
class FieldBuildContext {
  final BuildContext context;
  final JourneyField field;
  final Map<String, dynamic> values;
  final WidgetRef ref;
  final Map<String, String> errors;
  final InputDecoration Function({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? error,
    bool dense,
  }) fd;
  final Widget Function(JourneyField field, Map<String, dynamic> values) buildField;
  
  final Widget Function(JourneyField field, Map<String, dynamic> values, bool hasErr, String? errMsg, {bool isImage}) buildUpload;
  final Widget Function(JourneyField field) buildGrid;
  final Widget Function(JourneyField field) buildRepeater;
  final Widget Function(JourneyField field) buildTimeline;
  final Widget Function(JourneyField field, Map<String, dynamic> values, IconData icon) buildNested;
  final Widget Function(JourneyField field, Map<String, dynamic> values) buildTabs;
  final Widget Function(JourneyField field, Map<String, dynamic> values) buildNestedRow;
  final Widget Function(JourneyField field, String? initialValue, void Function(String?) onChanged, String? errorText) buildApiDropdown;

  FieldBuildContext({
    required this.context,
    required this.field,
    required this.values,
    required this.ref,
    required this.errors,
    required this.fd,
    required this.buildField,
    required this.buildUpload,
    required this.buildGrid,
    required this.buildRepeater,
    required this.buildTimeline,
    required this.buildNested,
    required this.buildTabs,
    required this.buildNestedRow,
    required this.buildApiDropdown,
  });

  bool get hasError => errors.containsKey(field.id);
  String? get errorMessage => errors[field.id];
  dynamic get currentValue => values[field.id];
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE FIELD PLUGIN
// ─────────────────────────────────────────────────────────────────────────────
abstract class RunnerFieldPlugin {
  bool canHandle(String type);
  Widget build(FieldBuildContext ctx);
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD PLUGINS IMPLEMENTATIONS
// ─────────────────────────────────────────────────────────────────────────────

class DividerFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'divider';

  @override
  Widget build(FieldBuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctx.field.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5B4FCF),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: Color(0xFFF0F0FF), height: 1),
        ],
      ),
    );
  }
}

class DropdownFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'dropdown';

  @override
  Widget build(FieldBuildContext ctx) {
    final opts = ctx.field.getResolvedOptions();
    final disp = opts.isEmpty ? ["Select"] : opts;
    final cur = ctx.currentValue?.toString();
    return DropdownButtonFormField<String>(
      value: disp.contains(cur) ? cur : null,
      decoration: ctx.fd(
        label: ctx.field.label,
        hint: ctx.field.placeholder ?? ctx.field.hintText,
        error: ctx.hasError ? ctx.errorMessage : null,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
      items: disp
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          ctx.ref.read(formValuesProvider.notifier).updateValue(ctx.field.id, v);
        }
      },
    );
  }
}

class ApiDropdownFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'api_dropdown';

  @override
  Widget build(FieldBuildContext ctx) {
    return ctx.buildApiDropdown(
      ctx.field,
      ctx.currentValue?.toString(),
      (v) => ctx.ref.read(formValuesProvider.notifier).updateValue(ctx.field.id, v),
      ctx.hasError ? ctx.errorMessage : null,
    );
  }
}

class RadioFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'radio';

  @override
  Widget build(FieldBuildContext ctx) {
    final opts = ctx.field.getResolvedOptions();
    final cur = ctx.currentValue?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctx.field.label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: opts.map((opt) {
            final sel = cur == opt;
            return GestureDetector(
              onTap: () => ctx.ref
                  .read(formValuesProvider.notifier)
                  .updateValue(ctx.field.id, opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFEEECFD) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFE4E6F0),
                    width: sel ? 1.5 : 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: sel ? const Color(0xFF5B4FCF) : const Color(0xFFB0B4C8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      opt,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        color: sel ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (ctx.hasError) ...[
          const SizedBox(height: 6),
          Text(
            ctx.errorMessage!,
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
          ),
        ],
      ],
    );
  }
}

class CheckboxFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'checkbox';

  @override
  Widget build(FieldBuildContext ctx) {
    final active = ctx.currentValue == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => ctx.ref
              .read(formValuesProvider.notifier)
              .updateValue(ctx.field.id, !active),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF5B4FCF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? const Color(0xFF5B4FCF) : const Color(0xFFB0B4C8),
                    width: 1.5,
                  ),
                ),
                child: active
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ctx.field.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (ctx.hasError) ...[
          const SizedBox(height: 6),
          Text(
            ctx.errorMessage!,
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
          ),
        ],
      ],
    );
  }
}

class SwitchFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'switch';

  @override
  Widget build(FieldBuildContext ctx) {
    final active = ctx.currentValue == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ctx.field.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            Switch(
              value: active,
              activeColor: const Color(0xFF5B4FCF),
              activeTrackColor: const Color(0xFFEEECFD),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
              onChanged: (val) => ctx.ref
                  .read(formValuesProvider.notifier)
                  .updateValue(ctx.field.id, val),
            ),
          ],
        ),
        if (ctx.hasError) ...[
          const SizedBox(height: 4),
          Text(
            ctx.errorMessage!,
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
          ),
        ],
      ],
    );
  }
}

class DateFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'date' || type == 'time' || type == 'datetime';

  @override
  Widget build(FieldBuildContext ctx) {
    final rawType = ctx.field.type.toLowerCase();
    final cur = ctx.currentValue?.toString() ?? '';
    final controller = TextEditingController(text: cur);

    return TextField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E)),
      decoration: ctx.fd(
        label: ctx.field.label,
        hint: ctx.field.placeholder,
        error: ctx.hasError ? ctx.errorMessage : null,
        suffix: Icon(
          rawType == 'time'
              ? Icons.access_time_rounded
              : Icons.calendar_today_rounded,
          color: const Color(0xFF5B4FCF),
          size: 18,
        ),
      ),
      onTap: () async {
        if (rawType == 'time') {
          final tod = await showTimePicker(
            context: ctx.context,
            initialTime: TimeOfDay.now(),
          );
          if (tod != null) {
            ctx.ref
                .read(formValuesProvider.notifier)
                .updateValue(ctx.field.id, tod.format(ctx.context));
          }
        } else {
          final dat = await showDatePicker(
            context: ctx.context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (dat != null) {
            final formatted = "${dat.year}-${dat.month.toString().padLeft(2, '0')}-${dat.day.toString().padLeft(2, '0')}";
            ctx.ref
                .read(formValuesProvider.notifier)
                .updateValue(ctx.field.id, formatted);
          }
        }
      },
    );
  }
}

class TextFieldPlugin extends RunnerFieldPlugin {
  final List<String> types = ['number', 'email', 'phone', 'textarea', 'text', 'textfield'];

  @override
  bool canHandle(String type) => types.contains(type);

  @override
  Widget build(FieldBuildContext ctx) {
    final rawType = ctx.field.type.toLowerCase();
    final cur = ctx.currentValue?.toString() ?? '';
    
    TextInputType keyboard = TextInputType.text;
    List<TextInputFormatter>? formatters;
    int maxLines = 1;

    if (rawType == 'number') {
      keyboard = TextInputType.number;
      formatters = [FilteringTextInputFormatter.digitsOnly];
    } else if (rawType == 'email') {
      keyboard = TextInputType.emailAddress;
    } else if (rawType == 'phone') {
      keyboard = TextInputType.phone;
      formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))];
    } else if (rawType == 'textarea') {
      maxLines = 4;
      keyboard = TextInputType.multiline;
    }

    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: cur,
        selection: TextSelection.collapsed(offset: cur.length),
      ),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E)),
      onChanged: (v) =>
          ctx.ref.read(formValuesProvider.notifier).updateValue(ctx.field.id, v),
      decoration: ctx.fd(
        label: ctx.field.label,
        hint: ctx.field.placeholder,
        error: ctx.hasError ? ctx.errorMessage : null,
      ).copyWith(alignLabelWithHint: maxLines > 1),
    );
  }
}

class OtpFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'otp';

  @override
  Widget build(FieldBuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctx.field.label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (idx) => SizedBox(
              width: 44,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFFAFAFF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE4E6F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF5B4FCF),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && idx < 5) {
                    FocusScope.of(ctx.context).nextFocus();
                  }
                  ctx.ref
                      .read(formValuesProvider.notifier)
                      .updateValue(ctx.field.id, "123456");
                },
              ),
            ),
          ),
        ),
        if (ctx.hasError) ...[
          const SizedBox(height: 6),
          Text(
            ctx.errorMessage!,
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
          ),
        ],
      ],
    );
  }
}

class UploadFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => type == 'image' || type == 'file';

  @override
  Widget build(FieldBuildContext ctx) {
    final isImage = ctx.field.type.toLowerCase() == 'image';
    return ctx.buildUpload(ctx.field, ctx.values, ctx.hasError, ctx.errorMessage, isImage: isImage);
  }
}

class LayoutFieldPlugin extends RunnerFieldPlugin {
  final List<String> types = [
    'table_grid',
    'repeater',
    'timeline',
    'section',
    'card',
    'tabs',
    'accordion',
    'row',
    'formula'
  ];

  @override
  bool canHandle(String type) => types.contains(type);

  @override
  Widget build(FieldBuildContext ctx) {
    final type = ctx.field.type.toLowerCase();
    switch (type) {
      case 'table_grid':
        return ctx.buildGrid(ctx.field);
      case 'repeater':
        return ctx.buildRepeater(ctx.field);
      case 'timeline':
        return ctx.buildTimeline(ctx.field);
      case 'section':
        return ctx.buildNested(ctx.field, ctx.values, Icons.view_agenda_outlined);
      case 'card':
        return ctx.buildNested(ctx.field, ctx.values, Icons.crop_square_rounded);
      case 'tabs':
        return ctx.buildTabs(ctx.field, ctx.values);
      case 'accordion':
        return ctx.buildNested(ctx.field, ctx.values, Icons.unfold_more_rounded);
      case 'row':
        return ctx.buildNestedRow(ctx.field, ctx.values);
      case 'formula':
        return FormulaFieldWidget(
          label: ctx.field.label,
          formula: ctx.field.formula!,
          formValues: ctx.values,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class FallbackFieldPlugin extends RunnerFieldPlugin {
  @override
  bool canHandle(String type) => true;

  @override
  Widget build(FieldBuildContext ctx) {
    final cur = ctx.currentValue?.toString() ?? '';
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: cur,
        selection: TextSelection.collapsed(offset: cur.length),
      ),
    );
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E)),
      onChanged: (v) =>
          ctx.ref.read(formValuesProvider.notifier).updateValue(ctx.field.id, v),
      decoration: ctx.fd(
        label: ctx.field.label,
        hint: ctx.field.placeholder,
        error: ctx.hasError ? ctx.errorMessage : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTRY ORCHESTRATOR
// ─────────────────────────────────────────────────────────────────────────────
class RunnerFieldPluginRegistry {
  static final List<RunnerFieldPlugin> _plugins = [
    DividerFieldPlugin(),
    DropdownFieldPlugin(),
    ApiDropdownFieldPlugin(),
    RadioFieldPlugin(),
    CheckboxFieldPlugin(),
    SwitchFieldPlugin(),
    DateFieldPlugin(),
    TextFieldPlugin(),
    OtpFieldPlugin(),
    UploadFieldPlugin(),
    LayoutFieldPlugin(),
  ];

  static Widget buildField(FieldBuildContext ctx) {
    final type = ctx.field.type.toLowerCase();
    for (final plugin in _plugins) {
      if (plugin.canHandle(type)) {
        return plugin.build(ctx);
      }
    }
    return FallbackFieldPlugin().build(ctx);
  }
}
