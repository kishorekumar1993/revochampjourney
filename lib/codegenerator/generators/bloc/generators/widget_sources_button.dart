// lib/codegenerator/generators/bloc/generators/widget_sources_button.dart

const String appFormButtonSource = r"""
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

const String widgetsBarrelSource = r"""
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
export 'app_data_grid.dart';
export 'form_field_wrapper.dart';
""";
