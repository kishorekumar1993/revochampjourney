// lib/codegenerator/generators/bloc/generators/widget_sources_text.dart

const String appTextFieldSource = r"""
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

const String formFieldWrapperSource = r"""
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

const String appErrorWidgetSource = r"""
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

const String appLoadingWidgetSource = r"""
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
