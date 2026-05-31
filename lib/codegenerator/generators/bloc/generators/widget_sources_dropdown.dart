// lib/codegenerator/generators/bloc/generators/widget_sources_dropdown.dart

const String appDropdownFieldSource = r"""
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

class DropdownItem {
  final String key;
  final String value;

  DropdownItem({
    required this.key,
    required this.value,
  });
}
""";

const String appAsyncDropdownFieldSource = r"""
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
