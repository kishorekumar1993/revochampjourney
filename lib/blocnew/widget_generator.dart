// lib/blocnew/widget_generator.dart
//
// Generates reusable, feature-independent form widgets:
//   • AppTextField           — text / email / phone / password
//   • AppDropdownField<T>    — static options
//   • AppAsyncDropdownField<T> — async options with retry
//   • AppCheckboxField
//   • AppDatePickerField
//   • AppRadioGroupField
//   • AppFileUploadField
//   • AppMultiSelectField
//   • AppFormButton          — submit / loading / disabled states
//   • AppErrorWidget         — consistent error display with retry
//   • AppLoadingWidget       — shimmer placeholder
//   • FormFieldWrapper       — label + error row wrapper
//
// These are emitted ONCE per project into lib/bloc/core/widgets/

abstract final class ReusableWidgetSources {
  // ─────────────────────────────────────────────────────────────────────────
  // app_text_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appTextField = r"""
// lib/bloc/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_field_wrapper.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String               label;
  final String?              hint;
  final String?              errorText;
  final String?              initialValue;
  final TextEditingController? controller;
  final FocusNode?           focusNode;
  final TextInputType        keyboardType;
  final TextInputAction      textInputAction;
  final TextCapitalization   textCapitalization;
  final bool                 obscureText;
  final bool                 readOnly;
  final int?                 maxLines;
  final int?                 minLines;
  final int?                 maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback?        onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget?              suffixIcon;
  final Widget?              prefixIcon;
  final bool                 enabled;
  final Iterable<String>?    autofillHints;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: TextFormField(
        initialValue:       controller == null ? initialValue : null,
        controller:         controller,
        focusNode:          focusNode,
        keyboardType:       keyboardType,
        textCapitalization: textCapitalization,
        textInputAction:    textInputAction,
        obscureText:        obscureText,
        readOnly:           readOnly,
        maxLines:           obscureText ? 1 : maxLines,
        minLines:           minLines,
        maxLength:          maxLength,
        inputFormatters:    inputFormatters,
        onChanged:          onChanged,
        onEditingComplete:  onEditingComplete,
        onFieldSubmitted:   onFieldSubmitted,
        validator:          validator,
        enabled:            enabled,
        autofillHints:      autofillHints,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText:    hint,
          hintStyle:   const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon:  prefixIcon,
          suffixIcon:  suffixIcon,
          border:      _border(),
          enabledBorder:  _border(),
          focusedBorder:  _border(focused: true),
          errorBorder:    _border(error: true),
          focusedErrorBorder: _border(focused: true, error: true),
          filled:      true,
          fillColor: readOnly || !enabled
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: error
              ? const Color(0xFFEF4444)
              : focused
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFE2E8F0),
          width: focused ? 2.0 : 1.0,
        ),
      );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_dropdown_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appDropdownField = r"""
// lib/bloc/core/widgets/app_dropdown_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String         label;
  final List<T>        items;
  final String Function(T) itemLabelBuilder;
  final T?             value;
  final ValueChanged<T?> onChanged;
  final String?        hint;
  final String?        errorText;
  final bool           enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: DropdownButtonFormField<T>(
        value:       value,
        onChanged:   enabled ? onChanged : null,
        isExpanded:  true,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText:  hint ?? 'Select $label',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border:      _border(),
          enabledBorder: _border(),
          focusedBorder: _border(focused: true),
          errorBorder: _border(error: true),
          focusedErrorBorder: _border(focused: true, error: true),
          filled:    true,
          fillColor: !enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        )).toList(),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: error 
          ? const Color(0xFFEF4444)
          : focused 
              ? const Color(0xFF6366F1) 
              : const Color(0xFFE2E8F0),
      width: focused ? 2.0 : 1.0,
    ),
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_async_dropdown_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appAsyncDropdownField = r"""
// lib/bloc/core/widgets/app_async_dropdown_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';
import '../runtime/async_state.dart';

class AppAsyncDropdownField<T> extends StatelessWidget {
  const AppAsyncDropdownField({
    super.key,
    required this.label,
    required this.asyncState,
    required this.itemLabelBuilder,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String                   label;
  final AsyncState<List<T>>      asyncState;
  final String Function(T)       itemLabelBuilder;
  final T?                       value;
  final ValueChanged<T?>         onChanged;
  final VoidCallback             onRetry;
  final String?                  hint;
  final String?                  errorText;
  final bool                     enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: asyncState.when(
        idle:    () => _buildDropdown(context, []),
        loading: () => const _DropdownShimmer(),
        success: (items) => _buildDropdown(context, items),
        onFailure: (f) => _RetryRow(
          message: f.message,
          onRetry: onRetry,
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, List<T> items) =>
      DropdownButtonFormField<T>(
        value:     value,
        onChanged: enabled && items.isNotEmpty ? onChanged : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText:  items.isEmpty ? 'No $label available' : hint ?? 'Select $label',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border:         _border(),
          enabledBorder:  _border(),
          focusedBorder:  _border(focused: true),
          errorBorder:    _border(error: true),
          focusedErrorBorder: _border(focused: true, error: true),
          filled:    true,
          fillColor: !enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        )).toList(),
      );

  OutlineInputBorder _border({bool focused = false, bool error = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: error 
          ? const Color(0xFFEF4444)
          : focused 
              ? const Color(0xFF6366F1) 
              : const Color(0xFFE2E8F0),
      width: focused ? 2.0 : 1.0,
    ),
  );
}

class _DropdownShimmer extends StatelessWidget {
  const _DropdownShimmer();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: const Center(
      child: SizedBox(width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6366F1))),
    ),
  );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.message, required this.onRetry});

  final String    message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)))),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF6366F1)),
          label: const Text('Retry', style: TextStyle(color: Color(0xFF6366F1))),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    ),
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_date_picker_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appDatePickerField = r"""
// lib/bloc/core/widgets/app_date_picker_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final display = value == null 
      ? (hint ?? 'Select date')
      : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: GestureDetector(
        onTap: enabled ? () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF6366F1), // header background color
                    onPrimary: Colors.white, // header text color
                    onSurface: Color(0xFF1E293B), // body text color
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onChanged(picked);
          }
        } : null,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            errorText: null, // error handled by wrapper
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(focused: true),
            errorBorder: _border(error: true),
            filled: true,
            fillColor: !enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                display,
                style: TextStyle(
                  fontSize: 15,
                  color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: error 
          ? const Color(0xFFEF4444)
          : focused 
              ? const Color(0xFF6366F1) 
              : const Color(0xFFE2E8F0),
      width: focused ? 2.0 : 1.0,
    ),
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_radio_group_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appRadioGroupField = r"""
// lib/bloc/core/widgets/app_radio_group_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppRadioGroupField extends StatelessWidget {
  const AppRadioGroupField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: options.map((opt) => RadioListTile<String>(
            value: opt,
            groupValue: value,
            title: Text(opt, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
            dense: true,
            activeColor: const Color(0xFF6366F1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            onChanged: enabled ? onChanged : null,
          )).toList(),
        ),
      ),
    );
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_file_upload_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appFileUploadField = r"""
// lib/bloc/core/widgets/app_file_upload_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppFileUploadField extends StatelessWidget {
  const AppFileUploadField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final display = value?.isNotEmpty == true ? value!.split('/').last : 'No file selected';

    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)
              ),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: const Color(0xFF4338CA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Browse', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: enabled ? () async {
                    // Placeholder logic: You would integrate file_picker here.
                    // final result = await FilePicker.platform.pickFiles();
                    // if (result != null) onChanged(result.files.single.path);
                    onChanged('mock_file_path/document.pdf');
                  } : null,
                ),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                hint!,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_multi_select_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appMultiSelectField = r"""
// lib/bloc/core/widgets/app_multi_select_field.dart
import 'package:flutter/material.dart';
import 'form_field_wrapper.dart';

class AppMultiSelectField extends StatelessWidget {
  const AppMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      errorText: errorText,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = selectedValues.contains(opt);
          return FilterChip(
            label: Text(opt, style: TextStyle(
              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: const Color(0xFFE0E7FF),
            backgroundColor: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            onSelected: enabled ? (_) {
              final current = List<String>.from(selectedValues);
              if (isSelected) {
                current.remove(opt);
              } else {
                current.add(opt);
              }
              onChanged(current);
            } : null,
          );
        }).toList(),
      ),
    );
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_checkbox_field.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appCheckboxField = r"""
// lib/bloc/core/widgets/app_checkbox_field.dart
import 'package:flutter/material.dart';

class AppCheckboxField extends StatelessWidget {
  const AppCheckboxField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.errorText,
    this.enabled = true,
  });

  final String         label;
  final bool           value;
  final ValueChanged<bool?> onChanged;
  final String?        subtitle;
  final String?        errorText;
  final bool           enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CheckboxListTile(
        value:       value,
        onChanged:   enabled ? onChanged : null,
        title:       Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
        subtitle:    subtitle != null ? Text(subtitle!, style: const TextStyle(color: Color(0xFF64748B))) : null,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF6366F1),
        dense:       true,
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(errorText!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
        ),
      const SizedBox(height: 8),
    ],
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // form_field_wrapper.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String formFieldWrapper = r"""
// lib/bloc/core/widgets/form_field_wrapper.dart
import 'package:flutter/material.dart';

class FormFieldWrapper extends StatelessWidget {
  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.isRequired = false,
  });

  final String  label;
  final Widget  child;
  final String? errorText;
  final bool    isRequired;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            )),
        if (isRequired) ...[
          const SizedBox(width: 2),
          const Text('*', style: TextStyle(color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold)),
        ],
      ]),
      const SizedBox(height: 8),
      child,
      if (errorText != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(errorText!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
          ),
        ]),
      ],
      const SizedBox(height: 20),
    ],
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_form_button.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appFormButton = r"""
// lib/bloc/core/widgets/app_form_button.dart
import 'package:flutter/material.dart';

enum AppButtonState { idle, loading, disabled }

class AppFormButton extends StatelessWidget {
  const AppFormButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = AppButtonState.idle,
    this.loadingLabel = 'Submitting…',
    this.icon,
    this.width = double.infinity,
  });

  final String          label;
  final VoidCallback?   onPressed;
  final AppButtonState  state;
  final String          loadingLabel;
  final IconData?       icon;
  final double          width;

  @override
  Widget build(BuildContext context) {
    final isLoading  = state == AppButtonState.loading;
    final isDisabled = state == AppButtonState.disabled || isLoading;

    return SizedBox(
      width:  width,
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1), // Indigo Primary
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        color: Colors.white)),
                const SizedBox(width: 12),
                Text(loadingLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_error_widget.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appErrorWidget = r"""
// lib/bloc/core/widgets/app_error_widget.dart
import 'package:flutter/material.dart';
import '../runtime/failure.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final Failure       failure;
  final VoidCallback? onRetry;
  final bool          compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactError(failure: failure, onRetry: onRetry);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 15)),
          if (failure.code.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Code: ${failure.code}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _CompactError extends StatelessWidget {
  const _CompactError({required this.failure, this.onRetry});

  final Failure       failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)),
      const SizedBox(width: 12),
      Expanded(child: Text(failure.message,
          style: const TextStyle(fontSize: 14, color: Color(0xFFB91C1C)))),
      if (onRetry != null)
        GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.refresh, size: 22, color: Color(0xFF6366F1)),
        ),
    ]),
  );
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // app_loading_widget.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String appLoadingWidget = r"""
// lib/bloc/core/widgets/app_loading_widget.dart
import 'package:flutter/material.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({
    super.key,
    this.message,
    this.fullPage = false,
  });

  final String? message;
  final bool    fullPage;

  @override
  Widget build(BuildContext context) {
    final content = Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Color(0xFF6366F1)),
      if (message != null) ...[
        const SizedBox(height: 16),
        Text(message!,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
      ],
    ]);
    if (fullPage) return Center(child: content);
    return content;
  }
}
""";

  // ─────────────────────────────────────────────────────────────────────────
  // widgets barrel export
  // ─────────────────────────────────────────────────────────────────────────
  static const String widgetsBarrel = r"""
// lib/bloc/core/widgets/widgets.dart
export 'app_text_field.dart';
export 'app_dropdown_field.dart';
export 'app_async_dropdown_field.dart';
export 'app_checkbox_field.dart';
export 'app_date_picker_field.dart';
export 'app_radio_group_field.dart';
export 'app_file_upload_field.dart';
export 'app_multi_select_field.dart';
export 'app_form_button.dart';
export 'app_error_widget.dart';
export 'app_loading_widget.dart';
export 'form_field_wrapper.dart';
""";
}
