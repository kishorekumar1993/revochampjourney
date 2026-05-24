// lib/bloc/generators/widget_generator.dart
//
// Generates reusable, feature-independent form widgets:
//   • AppTextField           — text / email / phone / password
//   • AppDropdownField<T>    — static options
//   • AppAsyncDropdownField<T> — async options with retry
//   • AppCheckboxField
//   • AppDatePickerField
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
  });

  final String               label;
  final String?              hint;
  final String?              errorText;
  final String?              initialValue;
  final TextEditingController? controller;
  final FocusNode?           focusNode;
  final TextInputType        keyboardType;
  final TextInputAction      textInputAction;
  final bool                 obscureText;
  final bool                 readOnly;
  final int?                 maxLines;
  final int?                 maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback?        onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget?              suffixIcon;
  final Widget?              prefixIcon;
  final bool                 enabled;
  final Iterable<String>?   autofillHints;

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
        textInputAction:    textInputAction,
        obscureText:        obscureText,
        readOnly:           readOnly,
        maxLines:           obscureText ? 1 : maxLines,
        maxLength:          maxLength,
        inputFormatters:    inputFormatters,
        onChanged:          onChanged,
        onEditingComplete:  onEditingComplete,
        onFieldSubmitted:   onFieldSubmitted,
        validator:          validator,
        enabled:            enabled,
        autofillHints:      autofillHints,
        decoration: InputDecoration(
          hintText:    hint,
          errorText:   errorText,
          prefixIcon:  prefixIcon,
          suffixIcon:  suffixIcon,
          border:      _border(),
          enabledBorder:  _border(),
          focusedBorder:  _border(focused: true),
          errorBorder:    _border(error: true),
          focusedErrorBorder: _border(focused: true, error: true),
          filled:      true,
          fillColor: readOnly
              ? Theme.of(context).colorScheme.surfaceVariant.withValues(alpha:.4)
              : Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, bool error = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: error
              ? Colors.red.shade700
              : focused
                  ? Colors.blue.shade600
                  : Colors.grey.shade300,
          width: focused ? 1.5 : 1,
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

/// Static (in-memory) dropdown field.
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
        decoration: InputDecoration(
          hintText:  hint ?? 'Select $label',
          errorText: errorText,
          border:      _border(),
          enabledBorder: _border(),
          focusedBorder: _border(focused: true),
          filled:    true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        )).toList(),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: focused ? Colors.blue.shade600 : Colors.grey.shade300,
      width: focused ? 1.5 : 1,
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

/// Async dropdown that reacts to [AsyncState] and shows retry on failure.
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
        initialValue:     value,
        onChanged: enabled && items.isNotEmpty ? onChanged : null,
        decoration: InputDecoration(
          hintText:  items.isEmpty ? 'No $label available' : hint ?? 'Select $label',
          errorText: errorText,
          border:         _border(),
          enabledBorder:  _border(),
          focusedBorder:  _border(focused: true),
          filled:    true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        )).toList(),
      );

  OutlineInputBorder _border({bool focused = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: focused ? Colors.blue.shade600 : Colors.grey.shade300,
      width: focused ? 1.5 : 1,
    ),
  );
}

class _DropdownShimmer extends StatelessWidget {
  const _DropdownShimmer();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(
      child: SizedBox(width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.message, required this.onRetry});

  final String    message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: TextStyle(fontSize: 13, color: Colors.red.shade800))),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
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
  // form_field_wrapper.dart
  // ─────────────────────────────────────────────────────────────────────────
  static const String formFieldWrapper = r"""
// lib/bloc/core/widgets/form_field_wrapper.dart
import 'package:flutter/material.dart';

/// Wraps any form widget with a label above and an error message below.
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        if (isRequired) ...[
          const SizedBox(width: 2),
          Text('*', style: TextStyle(color: Colors.red.shade700,
              fontWeight: FontWeight.bold)),
        ],
      ]),
      const SizedBox(height: 6),
      child,
      if (errorText != null) ...[
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.error_outline, size: 13, color: Colors.red.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Text(errorText!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          ),
        ]),
      ],
      const SizedBox(height: 14),
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
      height: 50,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white)),
                const SizedBox(width: 10),
                Text(loadingLabel),
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(label),
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

/// Consistent full-surface error display with optional retry button.
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
          Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700)),
          if (failure.code.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Code: ${failure.code}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(children: [
      Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
      const SizedBox(width: 8),
      Expanded(child: Text(failure.message,
          style: TextStyle(fontSize: 13, color: Colors.red.shade800))),
      if (onRetry != null)
        GestureDetector(
          onTap: onRetry,
          child: Icon(Icons.refresh, size: 18, color: Colors.blue.shade700),
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

/// Generic loading indicator that can be full-page or inline.
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
      const CircularProgressIndicator(),
      if (message != null) ...[
        const SizedBox(height: 12),
        Text(message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600)),
      ],
    ]);
    if (fullPage) return Center(child: content);
    return content;
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
        title:       Text(label),
        subtitle:    subtitle != null ? Text(subtitle!) : null,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense:       true,
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
        ),
      const SizedBox(height: 8),
    ],
  );
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
export 'app_form_button.dart';
export 'app_error_widget.dart';
export 'app_loading_widget.dart';
export 'form_field_wrapper.dart';
""";
}

// // lib/bloc/generators/widget_generator.dart
// //
// // Generates reusable, feature-independent form widgets:
// //   • AppTextField           — text / email / phone / password
// //   • AppDropdownField<T>    — static options
// //   • AppAsyncDropdownField<T> — async options with retry
// //   • AppCheckboxField
// //   • AppDatePickerField
// //   • AppFormButton          — submit / loading / disabled states
// //   • AppErrorWidget         — consistent error display with retry
// //   • AppLoadingWidget       — shimmer placeholder
// //   • FormFieldWrapper       — label + error row wrapper
// //
// // These are emitted ONCE per project into lib/bloc/core/widgets/

// abstract final class ReusableWidgetSources {
//   // ─────────────────────────────────────────────────────────────────────────
//   // app_text_field.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appTextField = r"""
// // lib/bloc/core/widgets/app_text_field.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'widgets.dart';

// class AppTextField extends StatelessWidget {
//   const AppTextField({
//     super.key,
//     required this.label,
//     this.hint,
//     this.errorText,
//     this.initialValue,
//     this.controller,
//     this.focusNode,
//     this.keyboardType = TextInputType.text,
//     this.textInputAction = TextInputAction.next,
//     this.obscureText = false,
//     this.readOnly = false,
//     this.maxLines = 1,
//     this.maxLength,
//     this.inputFormatters,
//     this.onChanged,
//     this.onEditingComplete,
//     this.onFieldSubmitted,
//     this.validator,
//     this.suffixIcon,
//     this.prefixIcon,
//     this.enabled = true,
//     this.autofillHints,
//   });

//   final String               label;
//   final String?              hint;
//   final String?              errorText;
//   final String?              initialValue;
//   final TextEditingController? controller;
//   final FocusNode?           focusNode;
//   final TextInputType        keyboardType;
//   final TextInputAction      textInputAction;
//   final bool                 obscureText;
//   final bool                 readOnly;
//   final int?                 maxLines;
//   final int?                 maxLength;
//   final List<TextInputFormatter>? inputFormatters;
//   final ValueChanged<String>? onChanged;
//   final VoidCallback?        onEditingComplete;
//   final ValueChanged<String>? onFieldSubmitted;
//   final FormFieldValidator<String>? validator;
//   final Widget?              suffixIcon;
//   final Widget?              prefixIcon;
//   final bool                 enabled;
//   final Iterable<String>?   autofillHints;

//   @override
//   Widget build(BuildContext context) {
//     return FormFieldWrapper(
//       label: label,
//       errorText: errorText,
//       child: TextFormField(
//         initialValue:       controller == null ? initialValue : null,
//         controller:         controller,
//         focusNode:          focusNode,
//         keyboardType:       keyboardType,
//         textInputAction:    textInputAction,
//         obscureText:        obscureText,
//         readOnly:           readOnly,
//         maxLines:           obscureText ? 1 : maxLines,
//         maxLength:          maxLength,
//         inputFormatters:    inputFormatters,
//         onChanged:          onChanged,
//         onEditingComplete:  onEditingComplete,
//         onFieldSubmitted:   onFieldSubmitted,
//         validator:          validator,
//         enabled:            enabled,
//         autofillHints:      autofillHints,
//         decoration: InputDecoration(
//           hintText:    hint,
//           errorText:   errorText,
//           prefixIcon:  prefixIcon,
//           suffixIcon:  suffixIcon,
//           border:      _border(),
//           enabledBorder:  _border(),
//           focusedBorder:  _border(focused: true),
//           errorBorder:    _border(error: true),
//           focusedErrorBorder: _border(focused: true, error: true),
//           filled:      true,
//           fillColor: readOnly
//               ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.4)
//               : Theme.of(context).colorScheme.surface,
//         ),
//       ),
//     );
//   }

//   OutlineInputBorder _border({bool focused = false, bool error = false}) =>
//       OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(
//           color: error
//               ? Colors.red.shade700
//               : focused
//                   ? Colors.blue.shade600
//                   : Colors.grey.shade300,
//           width: focused ? 1.5 : 1,
//         ),
//       );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_dropdown_field.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appDropdownField = r"""
// // lib/bloc/core/widgets/app_dropdown_field.dart
// import 'package:flutter/material.dart';
// import 'form_field_wrapper.dart';

// /// Static (in-memory) dropdown field.
// class AppDropdownField<T> extends StatelessWidget {
//   const AppDropdownField({
//     super.key,
//     required this.label,
//     required this.items,
//     required this.itemLabelBuilder,
//     required this.value,
//     required this.onChanged,
//     this.hint,
//     this.errorText,
//     this.enabled = true,
//   });

//   final String         label;
//   final List<T>        items;
//   final String Function(T) itemLabelBuilder;
//   final T?             value;
//   final ValueChanged<T?> onChanged;
//   final String?        hint;
//   final String?        errorText;
//   final bool           enabled;

//   @override
//   Widget build(BuildContext context) {
//     return FormFieldWrapper(
//       label: label,
//       errorText: errorText,
//       child: DropdownButtonFormField<T>(
//         initialValue:       value,
//         onChanged:   enabled ? onChanged : null,
//         decoration: InputDecoration(
//           hintText:  hint ?? 'Select $label',
//           errorText: errorText,
//           border:      _border(),
//           enabledBorder: _border(),
//           focusedBorder: _border(focused: true),
//           filled:    true,
//           fillColor: Theme.of(context).colorScheme.surface,
//         ),
//         items: items.map((item) => DropdownMenuItem<T>(
//           value: item,
//           child: Text(itemLabelBuilder(item)),
//         )).toList(),
//       ),
//     );
//   }

//   OutlineInputBorder _border({bool focused = false}) => OutlineInputBorder(
//     borderRadius: BorderRadius.circular(10),
//     borderSide: BorderSide(
//       color: focused ? Colors.blue.shade600 : Colors.grey.shade300,
//       width: focused ? 1.5 : 1,
//     ),
//   );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_async_dropdown_field.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appAsyncDropdownField = r"""
// // lib/bloc/core/widgets/app_async_dropdown_field.dart
// import 'package:flutter/material.dart';
// import 'form_field_wrapper.dart';
// import '../runtime/async_state.dart';

// /// Async dropdown that reacts to [AsyncState] and shows retry on failure.
// class AppAsyncDropdownField<T> extends StatelessWidget {
//   const AppAsyncDropdownField({
//     super.key,
//     required this.label,
//     required this.asyncState,
//     required this.itemLabelBuilder,
//     required this.value,
//     required this.onChanged,
//     required this.onRetry,
//     this.hint,
//     this.errorText,
//     this.enabled = true,
//   });

//   final String                   label;
//   final AsyncState<List<T>>      asyncState;
//   final String Function(T)       itemLabelBuilder;
//   final T?                       value;
//   final ValueChanged<T?>         onChanged;
//   final VoidCallback             onRetry;
//   final String?                  hint;
//   final String?                  errorText;
//   final bool                     enabled;

//   @override
//   Widget build(BuildContext context) {
//     return FormFieldWrapper(
//       label: label,
//       errorText: errorText,
//       child: asyncState.when(
//         idle:    () => _buildDropdown(context, []),
//         loading: () => const _DropdownShimmer(),
//         success: (items) => _buildDropdown(context, items),
//         onFailure: (f) => _RetryRow(
//           message: f.message,
//           onRetry: onRetry,
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(BuildContext context, List<T> items) =>
//       DropdownButtonFormField<T>(
//         value:     value,
//         onChanged: enabled && items.isNotEmpty ? onChanged : null,
//         decoration: InputDecoration(
//           hintText:  items.isEmpty ? 'No $label available' : hint ?? 'Select $label',
//           errorText: errorText,
//           border:         _border(),
//           enabledBorder:  _border(),
//           focusedBorder:  _border(focused: true),
//           filled:    true,
//           fillColor: Theme.of(context).colorScheme.surface,
//         ),
//         items: items.map((item) => DropdownMenuItem<T>(
//           value: item,
//           child: Text(itemLabelBuilder(item)),
//         )).toList(),
//       );

//   OutlineInputBorder _border({bool focused = false}) => OutlineInputBorder(
//     borderRadius: BorderRadius.circular(10),
//     borderSide: BorderSide(
//       color: focused ? Colors.blue.shade600 : Colors.grey.shade300,
//       width: focused ? 1.5 : 1,
//     ),
//   );
// }

// class _DropdownShimmer extends StatelessWidget {
//   const _DropdownShimmer();

//   @override
//   Widget build(BuildContext context) => Container(
//     height: 52,
//     decoration: BoxDecoration(
//       color: Colors.grey.shade200,
//       borderRadius: BorderRadius.circular(10),
//     ),
//     child: const Center(
//       child: SizedBox(width: 24, height: 24,
//         child: CircularProgressIndicator(strokeWidth: 2)),
//     ),
//   );
// }

// class _RetryRow extends StatelessWidget {
//   const _RetryRow({required this.message, required this.onRetry});

//   final String    message;
//   final VoidCallback onRetry;

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//     decoration: BoxDecoration(
//       color: Colors.red.shade50,
//       borderRadius: BorderRadius.circular(10),
//       border: Border.all(color: Colors.red.shade200),
//     ),
//     child: Row(
//       children: [
//         Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
//         const SizedBox(width: 8),
//         Expanded(child: Text(message,
//             style: TextStyle(fontSize: 13, color: Colors.red.shade800))),
//         TextButton.icon(
//           onPressed: onRetry,
//           icon: const Icon(Icons.refresh, size: 16),
//           label: const Text('Retry'),
//           style: TextButton.styleFrom(
//             foregroundColor: Colors.blue.shade700,
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             minimumSize: Size.zero,
//             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           ),
//         ),
//       ],
//     ),
//   );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // form_field_wrapper.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String formFieldWrapper = r"""
// // lib/bloc/core/widgets/form_field_wrapper.dart
// import 'package:flutter/material.dart';

// /// Wraps any form widget with a label above and an error message below.
// class FormFieldWrapper extends StatelessWidget {
//   const FormFieldWrapper({
//     super.key,
//     required this.label,
//     required this.child,
//     this.errorText,
//     this.isRequired = false,
//   });

//   final String  label;
//   final Widget  child;
//   final String? errorText;
//   final bool    isRequired;

//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Row(children: [
//         Text(label,
//             style: Theme.of(context)
//                 .textTheme
//                 .bodyMedium
//                 ?.copyWith(fontWeight: FontWeight.w500)),
//         if (isRequired) ...[
//           const SizedBox(width: 2),
//           Text('*', style: TextStyle(color: Colors.red.shade700,
//               fontWeight: FontWeight.bold)),
//         ],
//       ]),
//       const SizedBox(height: 6),
//       child,
//       if (errorText != null) ...[
//         const SizedBox(height: 4),
//         Row(children: [
//           Icon(Icons.error_outline, size: 13, color: Colors.red.shade700),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Text(errorText!,
//                 style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
//           ),
//         ]),
//       ],
//       const SizedBox(height: 14),
//     ],
//   );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_form_button.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appFormButton = r"""
// // lib/bloc/core/widgets/app_form_button.dart
// import 'package:flutter/material.dart';

// enum AppButtonState { idle, loading, disabled }

// class AppFormButton extends StatelessWidget {
//   const AppFormButton({
//     super.key,
//     required this.label,
//     required this.onPressed,
//     this.state = AppButtonState.idle,
//     this.loadingLabel = 'Submitting…',
//     this.icon,
//     this.width = double.infinity,
//   });

//   final String          label;
//   final VoidCallback?   onPressed;
//   final AppButtonState  state;
//   final String          loadingLabel;
//   final IconData?       icon;
//   final double          width;

//   @override
//   Widget build(BuildContext context) {
//     final isLoading  = state == AppButtonState.loading;
//     final isDisabled = state == AppButtonState.disabled || isLoading;

//     return SizedBox(
//       width:  width,
//       height: 50,
//       child: ElevatedButton(
//         onPressed: isDisabled ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12)),
//           elevation: 0,
//         ),
//         child: isLoading
//             ? Row(mainAxisSize: MainAxisSize.min, children: [
//                 const SizedBox(width: 18, height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2,
//                         color: Colors.white)),
//                 const SizedBox(width: 10),
//                 Text(loadingLabel),
//               ])
//             : Row(mainAxisSize: MainAxisSize.min, children: [
//                 if (icon != null) ...[
//                   Icon(icon, size: 18),
//                   const SizedBox(width: 6),
//                 ],
//                 Text(label),
//               ]),
//       ),
//     );
//   }
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_error_widget.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appErrorWidget = r"""
// // lib/bloc/core/widgets/app_error_widget.dart
// import 'package:flutter/material.dart';
// import '../runtime/failure.dart';

// /// Consistent full-surface error display with optional retry button.
// class AppErrorWidget extends StatelessWidget {
//   const AppErrorWidget({
//     super.key,
//     required this.failure,
//     this.onRetry,
//     this.compact = false,
//   });

//   final Failure       failure;
//   final VoidCallback? onRetry;
//   final bool          compact;

//   @override
//   Widget build(BuildContext context) {
//     if (compact) return _CompactError(failure: failure, onRetry: onRetry);
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(failure.message,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey.shade700)),
//           if (failure.code.isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Text('Code: ${failure.code}',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Colors.grey.shade500)),
//           ],
//           if (onRetry != null) ...[
//             const SizedBox(height: 20),
//             OutlinedButton.icon(
//               onPressed: onRetry,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Try again'),
//             ),
//           ],
//         ]),
//       ),
//     );
//   }
// }

// class _CompactError extends StatelessWidget {
//   const _CompactError({required this.failure, this.onRetry});

//   final Failure       failure;
//   final VoidCallback? onRetry;

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//     decoration: BoxDecoration(
//       color: Colors.red.shade50,
//       borderRadius: BorderRadius.circular(10),
//       border: Border.all(color: Colors.red.shade200),
//     ),
//     child: Row(children: [
//       Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
//       const SizedBox(width: 8),
//       Expanded(child: Text(failure.message,
//           style: TextStyle(fontSize: 13, color: Colors.red.shade800))),
//       if (onRetry != null)
//         GestureDetector(
//           onTap: onRetry,
//           child: Icon(Icons.refresh, size: 18, color: Colors.blue.shade700),
//         ),
//     ]),
//   );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_loading_widget.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appLoadingWidget = r"""
// // lib/bloc/core/widgets/app_loading_widget.dart
// import 'package:flutter/material.dart';

// /// Generic loading indicator that can be full-page or inline.
// class AppLoadingWidget extends StatelessWidget {
//   const AppLoadingWidget({
//     super.key,
//     this.message,
//     this.fullPage = false,
//   });

//   final String? message;
//   final bool    fullPage;

//   @override
//   Widget build(BuildContext context) {
//     final content = Column(mainAxisSize: MainAxisSize.min, children: [
//       const CircularProgressIndicator(),
//       if (message != null) ...[
//         const SizedBox(height: 12),
//         Text(message!,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Colors.grey.shade600)),
//       ],
//     ]);
//     if (fullPage) return Center(child: content);
//     return content;
//   }
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // app_checkbox_field.dart
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String appCheckboxField = r"""
// // lib/bloc/core/widgets/app_checkbox_field.dart
// import 'package:flutter/material.dart';

// class AppCheckboxField extends StatelessWidget {
//   const AppCheckboxField({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.onChanged,
//     this.subtitle,
//     this.errorText,
//     this.enabled = true,
//   });

//   final String         label;
//   final bool           value;
//   final ValueChanged<bool?> onChanged;
//   final String?        subtitle;
//   final String?        errorText;
//   final bool           enabled;

//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       CheckboxListTile(
//         value:       value,
//         onChanged:   enabled ? onChanged : null,
//         title:       Text(label),
//         subtitle:    subtitle != null ? Text(subtitle!) : null,
//         contentPadding: EdgeInsets.zero,
//         controlAffinity: ListTileControlAffinity.leading,
//         dense:       true,
//       ),
//       if (errorText != null)
//         Padding(
//           padding: const EdgeInsets.only(left: 4, top: 2),
//           child: Text(errorText!,
//               style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
//         ),
//       const SizedBox(height: 8),
//     ],
//   );
// }
// """;

//   // ─────────────────────────────────────────────────────────────────────────
//   // widgets barrel export
//   // ─────────────────────────────────────────────────────────────────────────
//   static const String widgetsBarrel = r"""
// // lib/bloc/core/widgets/widgets.dart
// export 'app_text_field.dart';
// export 'app_dropdown_field.dart';
// export 'app_async_dropdown_field.dart';
// export 'app_checkbox_field.dart';
// export 'app_form_button.dart';
// export 'app_error_widget.dart';
// export 'app_loading_widget.dart';
// export 'form_field_wrapper.dart';
// """;
// }
