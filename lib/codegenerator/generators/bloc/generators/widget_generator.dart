// lib/codegenerator/generators/bloc/generators/widget_generator.dart
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

import 'widget_sources_text.dart';
import 'widget_sources_dropdown.dart';
import 'widget_sources_inputs.dart';
import 'widget_sources_button.dart';

abstract final class ReusableWidgetSources {
  static const String appTextField = appTextFieldSource;
  static const String formFieldWrapper = formFieldWrapperSource;
  static const String appErrorWidget = appErrorWidgetSource;
  static const String appLoadingWidget = appLoadingWidgetSource;

  static const String appDropdownField = appDropdownFieldSource;
  static const String appAsyncDropdownField = appAsyncDropdownFieldSource;

  static const String appDatePickerField = appDatePickerFieldSource;
  static const String appRadioGroupField = appRadioGroupFieldSource;
  static const String appFileUploadField = appFileUploadFieldSource;
  static const String appMultiSelectField = appMultiSelectFieldSource;
  static const String appCheckboxField = appCheckboxFieldSource;
  static const String appDataGrid = appDataGridSource;

  static const String appFormButton = appFormButtonSource;
  static const String widgetsBarrel = widgetsBarrelSource;
}
