String generateTextForm() {
  final buffer = StringBuffer();


buffer.writeln("""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ============================================
// ENUMS & MODELS (Enhanced)
// ============================================
enum FieldType { text, password, number, email, phone, date, time, datetime }
enum LabelPosition { floating, top, left, inline }
enum ValidationMode { onChanged, onBlur, onSubmit }

// Enhanced FieldConfig with more features
class FieldConfig {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool readOnly;
  final dynamic defaultValue;
  final bool visible;
  final String? dependsOn; // Field ID this depends on
  final dynamic dependsOnValue; // Value that makes this visible
  final Map<String, dynamic>? customProps;
  
  const FieldConfig({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.readOnly = false,
    this.defaultValue,
    this.visible = true,
    this.dependsOn,
    this.dependsOnValue,
    this.customProps,
  });
  
  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      required: json['required'] ?? false,
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      pattern: json['pattern'],
      readOnly: json['readOnly'] ?? false,
      defaultValue: json['defaultValue'],
      visible: json['visible'] ?? true,
      dependsOn: json['dependsOn'],
      dependsOnValue: json['dependsOnValue'],
      customProps: json['customProps'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'required': required,
      'minLength': minLength,
      'maxLength': maxLength,
      'pattern': pattern,
      'readOnly': readOnly,
      'defaultValue': defaultValue,
      'visible': visible,
      'dependsOn': dependsOn,
      'dependsOnValue': dependsOnValue,
      'customProps': customProps,
    };
  }
}

// ============================================
// VALIDATOR ENGINE (Enhanced with Date/Time validation)
// ============================================
abstract class FieldValidator {
  String? validate(String? value);
}

class RequiredValidator implements FieldValidator {
  final String fieldName;
  RequiredValidator(this.fieldName);
  
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return "\$fieldName is required";
    }
    return null;
  }
}

class MinLengthValidator implements FieldValidator {
  final int minLength;
  final String fieldName;
  
  MinLengthValidator(this.minLength, this.fieldName);
  
  @override
  String? validate(String? value) {
    if (value != null && value.isNotEmpty && value.length < minLength) {
      return "\$fieldName must be at least \$minLength characters";
    }
    return null;
  }
}

class MaxLengthValidator implements FieldValidator {
  final int maxLength;
  final String fieldName;
  
  MaxLengthValidator(this.maxLength, this.fieldName);
  
  @override
  String? validate(String? value) {
    if (value != null && value.isNotEmpty && value.length > maxLength) {
      return "\$fieldName must be at most \$maxLength characters";
    }
    return null;
  }
}

class EmailValidator implements FieldValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$',
  );
  
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

class PhoneValidator implements FieldValidator {
   static final RegExp _phoneRegex = RegExp(
    r'^[\\d\\s\\-\\(\\)\\+]{10,}\$',
  );
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}

class PatternValidator implements FieldValidator {
  final String pattern;
  final String errorMessage;
  
  PatternValidator(this.pattern, this.errorMessage);
  
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return errorMessage;
    }
    return null;
  }
}

// New: Date Format Validator
class DateFormatValidator implements FieldValidator {
  final String format;
  final Locale? locale;
  final String fieldName;
  
  DateFormatValidator(this.format, this.fieldName, {this.locale});
  
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      DateFormat(format, locale?.toString()).parseStrict(value);
      return null;
    } catch (e) {
      return "\$fieldName must be in format: \$format";
    }
  }
}

String? validateField(String? value, List<FieldValidator> validators) {
  for (final v in validators) {
    final res = v.validate(value);
    if (res != null) return res;
  }
  return null;
}

// ============================================
// DATE PICKER SERVICE
// ============================================
class DatePickerService {
  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
    );
  }
  
  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }
  
  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? initialDate,
    TimeOfDay? initialTime,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final pickedDate = await pickDate(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate == null) return null;
    
    final pickedTime = await pickTime(
      context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return null;
    
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}

// ============================================
// TEXT INPUT FIELD (Optimized with minimal rebuilds)
// ============================================
class TextInputField extends StatefulWidget {
  final FieldType fieldType;
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final List<FieldValidator>? validators;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final AutovalidateMode? autovalidateMode;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final bool readOnly;
  final bool enabled;
  final bool autoFocus;
  final bool showClearButton;
  final ValidationMode validationMode;
  final IconData? prefixIcon;
  final Color? fillColor;
  final bool isMandatory;
  
  const TextInputField({
    super.key,
    required this.fieldType,
    required this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.validators,
    this.inputFormatters,
    this.onSaved,
    this.onChanged,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.autovalidateMode,
    this.textStyle,
    this.decoration,
    this.readOnly = false,
    this.enabled = true,
    this.autoFocus = false,
    this.showClearButton = false,
    this.validationMode = ValidationMode.onSubmit,
    this.prefixIcon,
    this.fillColor,
    this.isMandatory = false,
  });
  
  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  final ValueNotifier<bool> _obscureNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _refreshSuffixNotifier = ValueNotifier(false);
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    // Listen to controller changes for clear button
    widget.controller.addListener(_onControllerChanged);
  }
  
  void _onControllerChanged() {
    if (widget.showClearButton) {
      _refreshSuffixNotifier.value = !_refreshSuffixNotifier.value;
    }
  }
  
  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      // Trigger suffix rebuild for clear button
      if (widget.showClearButton) {
        _refreshSuffixNotifier.value = !_refreshSuffixNotifier.value;
      }
    }
    
    if (widget.validationMode == ValidationMode.onBlur && !_focusNode.hasFocus) {
      _focusNode.context?.findAncestorStateOfType<FormState>()?.validate();
    }
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _obscureNotifier.dispose();
    _refreshSuffixNotifier.dispose();
    super.dispose();
  }
  
  void _togglePassword() {
    _obscureNotifier.value = !_obscureNotifier.value;
  }
  
  void _clearText() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }
  
  Widget _buildSuffixIcon() {
    if (widget.showClearButton && widget.controller.text.isNotEmpty && _isFocused) {
      return IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: _clearText,
      );
    }
    
    if (widget.fieldType == FieldType.password) {
      return ValueListenableBuilder<bool>(
        valueListenable: _obscureNotifier,
        builder: (_, obscure, __) {
          return IconButton(
            icon: Icon(
              obscure ? Icons.visibility : Icons.visibility_off,
              size: 20,
            ),
            onPressed: _togglePassword,
          );
        },
      );
    }
    
    return null;
  }
  
  Widget _buildLabelWithRequired() {
    if (widget.label == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label!),
        if (widget.isMandatory)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
  
  InputDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    
    final defaultDecoration = InputDecoration(
      label: _buildLabelWithRequired(),
      hintText: widget.hint,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      border: const OutlineInputBorder(),
      filled: widget.fillColor != null,
      fillColor: widget.fillColor,
    );
    
    // Use ValueListenableBuilder only for suffix icon to minimize rebuilds
    final baseDecoration = (widget.decoration ?? defaultDecoration)
        .applyDefaults(theme.inputDecorationTheme);
    
    // Return decoration without suffix first, then wrap with ValueListenableBuilder
    return baseDecoration.copyWith(
      suffixIcon: null, // Will be handled by the ValueListenableBuilder
    );
  }
  
  String? _validate(String? value) {
    if (widget.validators != null && widget.validators!.isNotEmpty) {
      return validateField(value, widget.validators!);
    }
    return null;
  }
  
  TextInputType _getKeyboardType() {
    switch (widget.fieldType) {
      case FieldType.number:
        return TextInputType.number;
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _refreshSuffixNotifier,
      builder: (_, __, ___) {
        return ValueListenableBuilder<bool>(
          valueListenable: _obscureNotifier,
          builder: (_, obscure, __) {
            return TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.fieldType == FieldType.password ? obscure : false,
              keyboardType: _getKeyboardType(),
              validator: _validate,
              onSaved: widget.onSaved,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (widget.validationMode == ValidationMode.onChanged) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _focusNode.context?.findAncestorStateOfType<FormState>()?.validate();
                  });
                }
              },
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              autovalidateMode: widget.autovalidateMode,
              style: widget.textStyle,
              decoration: _buildDecoration(context).copyWith(
                suffixIcon: _buildSuffixIcon(),
              ),
              autofocus: widget.autoFocus,
            );
          },
        );
      },
    );
  }
}

// ============================================
// DATE FIELD (Enhanced with format validation)
// ============================================
class DateField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? dateFormat;
  final Locale? locale;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(String)? onChanged;
  final List<FieldValidator>? validators;
  final bool enabled;
  final IconData? prefixIcon;
  final bool isMandatory;
  
  const DateField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.dateFormat,
    this.locale,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.validators,
    this.enabled = true,
    this.prefixIcon,
    this.isMandatory = false,
  });
  
  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late DateFormat _dateFormat;
  
  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat(
      widget.dateFormat ?? 'yyyy-MM-dd',
      widget.locale?.toString(),
    );
  }
  
  Future<void> _pickDate() async {
    if (!widget.enabled) return;
    
    final pickedDate = await DatePickerService.pickDate(
      context,
      initialDate: widget.initialDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    
    if (pickedDate != null) {
      widget.controller.text = _dateFormat.format(pickedDate);
      widget.onChanged?.call(widget.controller.text);
    }
  }
  
  Widget _buildLabelWithRequired() {
    if (widget.label == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label!),
        if (widget.isMandatory)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
  
  String? _validate(String? value) {
    final builtValidators = <FieldValidator>[];
    
    // Add date format validator if value exists
    if (value != null && value.isNotEmpty) {
      builtValidators.add(DateFormatValidator(
        widget.dateFormat ?? 'yyyy-MM-dd',
        widget.label ?? 'Date',
        locale: widget.locale,
      ));
    }
    
    // Add custom validators
    if (widget.validators != null) {
      builtValidators.addAll(widget.validators!);
    }
    
    if (builtValidators.isNotEmpty) {
      return validateField(value, builtValidators);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _pickDate,
      validator: _validate,
      enabled: widget.enabled,
      decoration: InputDecoration(
        label: _buildLabelWithRequired(),
        hintText: widget.hint ?? 'Select date',
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ============================================
// TIME FIELD (Enhanced with format validation)
// ============================================
class TimeField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? timeFormat;
  final Locale? locale;
  final TimeOfDay? initialTime;
  final void Function(String)? onChanged;
  final List<FieldValidator>? validators;
  final bool enabled;
  final IconData? prefixIcon;
  final bool isMandatory;
  
  const TimeField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.timeFormat,
    this.locale,
    this.initialTime,
    this.onChanged,
    this.validators,
    this.enabled = true,
    this.prefixIcon,
    this.isMandatory = false,
  });
  
  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  late DateFormat _timeFormat;
  
  @override
  void initState() {
    super.initState();
    _timeFormat = DateFormat(
      widget.timeFormat ?? 'HH:mm',
      widget.locale?.toString(),
    );
  }
  
  Future<void> _pickTime() async {
    if (!widget.enabled) return;
    
    final pickedTime = await DatePickerService.pickTime(
      context,
      initialTime: widget.initialTime,
    );
    
    if (pickedTime != null) {
      final now = DateTime.now();
      final fullTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      widget.controller.text = _timeFormat.format(fullTime);
      widget.onChanged?.call(widget.controller.text);
    }
  }
  
  Widget _buildLabelWithRequired() {
    if (widget.label == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label!),
        if (widget.isMandatory)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
  
  String? _validate(String? value) {
    final builtValidators = <FieldValidator>[];
    
    // Add time format validator if value exists
    if (value != null && value.isNotEmpty) {
      builtValidators.add(DateFormatValidator(
        widget.timeFormat ?? 'HH:mm',
        widget.label ?? 'Time',
        locale: widget.locale,
      ));
    }
    
    // Add custom validators
    if (widget.validators != null) {
      builtValidators.addAll(widget.validators!);
    }
    
    if (builtValidators.isNotEmpty) {
      return validateField(value, builtValidators);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _pickTime,
      validator: _validate,
      enabled: widget.enabled,
      decoration: InputDecoration(
        label: _buildLabelWithRequired(),
        hintText: widget.hint ?? 'Select time',
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ============================================
// DATETIME FIELD (Enhanced with format validation)
// ============================================
class DateTimeField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? dateTimeFormat;
  final Locale? locale;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(String)? onChanged;
  final List<FieldValidator>? validators;
  final bool enabled;
  final IconData? prefixIcon;
  final bool isMandatory;
  
  const DateTimeField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.dateTimeFormat,
    this.locale,
    this.initialDate,
    this.initialTime,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.validators,
    this.enabled = true,
    this.prefixIcon,
    this.isMandatory = false,
  });
  
  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  late DateFormat _dateTimeFormat;
  
  @override
  void initState() {
    super.initState();
    _dateTimeFormat = DateFormat(
      widget.dateTimeFormat ?? 'yyyy-MM-dd HH:mm',
      widget.locale?.toString(),
    );
  }
  
  Future<void> _pickDateTime() async {
    if (!widget.enabled) return;
    
    final pickedDateTime = await DatePickerService.pickDateTime(
      context,
      initialDate: widget.initialDate,
      initialTime: widget.initialTime,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    
    if (pickedDateTime != null) {
      widget.controller.text = _dateTimeFormat.format(pickedDateTime);
      widget.onChanged?.call(widget.controller.text);
    }
  }
  
  Widget _buildLabelWithRequired() {
    if (widget.label == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label!),
        if (widget.isMandatory)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
  
  String? _validate(String? value) {
    final builtValidators = <FieldValidator>[];
    
    // Add datetime format validator if value exists
    if (value != null && value.isNotEmpty) {
      builtValidators.add(DateFormatValidator(
        widget.dateTimeFormat ?? 'yyyy-MM-dd HH:mm',
        widget.label ?? 'Date & Time',
        locale: widget.locale,
      ));
    }
    
    // Add custom validators
    if (widget.validators != null) {
      builtValidators.addAll(widget.validators!);
    }
    
    if (builtValidators.isNotEmpty) {
      return validateField(value, builtValidators);
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _pickDateTime,
      validator: _validate,
      enabled: widget.enabled,
      decoration: InputDecoration(
        label: _buildLabelWithRequired(),
        hintText: widget.hint ?? 'Select date & time',
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: const Icon(Icons.date_range),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ============================================
// MAIN WRAPPER (Enhanced with field dependencies)
// ============================================
class CustomField extends StatefulWidget {
  final FieldType fieldType;
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final FieldConfig? config;
  final List<FieldValidator>? validators;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final AutovalidateMode? autovalidateMode;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final bool readOnly;
  final bool enabled;
  final bool autoFocus;
  final bool showClearButton;
  final ValidationMode validationMode;
  final String? dateFormat;
  final String? timeFormat;
  final String? dateTimeFormat;
  final Locale? locale;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TimeOfDay? initialTime;
  final LabelPosition labelPosition;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? fillColor;
  final String fieldId;
  final Map<String, dynamic>? formValues; // For dependency checking
  
  const CustomField({
    super.key,
    required this.fieldType,
    required this.fieldId,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.config,
    this.validators,
    this.inputFormatters,
    this.onSaved,
    this.onChanged,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.autovalidateMode,
    this.textStyle,
    this.decoration,
    this.readOnly = false,
    this.enabled = true,
    this.autoFocus = false,
    this.showClearButton = false,
    this.validationMode = ValidationMode.onSubmit,
    this.dateFormat,
    this.timeFormat,
    this.dateTimeFormat,
    this.locale,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.initialTime,
    this.labelPosition = LabelPosition.floating,
    this.prefixIcon,
    this.padding,
    this.width,
    this.height,
    this.fillColor,
    this.formValues,
  });
  
  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  late TextEditingController _internalController;
  bool _isExternalController = false;
  bool _isVisible = true;
  
  @override
  void initState() {
    super.initState();
    _isExternalController = widget.controller != null;
    _internalController = widget.controller ?? TextEditingController();
    
    // Set default value if provided
    if (widget.config?.defaultValue != null && _internalController.text.isEmpty) {
      _internalController.text = widget.config!.defaultValue.toString();
    }
    
    _checkVisibility();
  }
  
  @override
  void didUpdateWidget(CustomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check visibility when form values change
    if (widget.formValues != oldWidget.formValues) {
      _checkVisibility();
    }
  }
  
  void _checkVisibility() {
    if (widget.config?.dependsOn != null && widget.formValues != null) {
      final dependsOnValue = widget.formValues![widget.config!.dependsOn];
      final expectedValue = widget.config!.dependsOnValue;
      
      setState(() {
        _isVisible = dependsOnValue == expectedValue;
      });
    } else {
      _isVisible = widget.config?.visible ?? true;
    }
  }
  
  @override
  void dispose() {
    if (!_isExternalController) {
      _internalController.dispose();
    }
    super.dispose();
  }
  
  List<FieldValidator> _buildValidators() {
    final builtValidators = <FieldValidator>[];
    
    // Add config-based validators
    if (widget.config != null) {
      if (widget.config!.required) {
        builtValidators.add(RequiredValidator(widget.label ?? widget.fieldId));
      }
      if (widget.config!.minLength != null) {
        builtValidators.add(MinLengthValidator(
          widget.config!.minLength!,
          widget.label ?? widget.fieldId,
        ));
      }
      if (widget.config!.maxLength != null) {
        builtValidators.add(MaxLengthValidator(
          widget.config!.maxLength!,
          widget.label ?? widget.fieldId,
        ));
      }
      if (widget.config!.pattern != null) {
        builtValidators.add(PatternValidator(
          widget.config!.pattern!,
          'Invalid format',
        ));
      }
    }
    
    // Add type-specific validators
    switch (widget.fieldType) {
      case FieldType.email:
        builtValidators.add(EmailValidator());
        break;
      case FieldType.phone:
        builtValidators.add(PhoneValidator());
        break;
      default:
        break;
    }
    
    // Add custom validators
    if (widget.validators != null) {
      builtValidators.addAll(widget.validators!);
    }
    
    return builtValidators;
  }
  
  Widget _buildFieldWidget() {
    final validators = _buildValidators();
    final isMandatory = widget.config?.required ?? false;
    final isReadOnly = widget.config?.readOnly ?? widget.readOnly;
    
    switch (widget.fieldType) {
      case FieldType.date:
        return DateField(
          controller: _internalController,
          label: widget.label,
          hint: widget.hint,
          dateFormat: widget.dateFormat,
          locale: widget.locale,
          initialDate: widget.initialDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onChanged: widget.onChanged,
          validators: validators.isNotEmpty ? validators : null,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          isMandatory: isMandatory,
        );
        
      case FieldType.time:
        return TimeField(
          controller: _internalController,
          label: widget.label,
          hint: widget.hint,
          timeFormat: widget.timeFormat,
          locale: widget.locale,
          initialTime: widget.initialTime,
          onChanged: widget.onChanged,
          validators: validators.isNotEmpty ? validators : null,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          isMandatory: isMandatory,
        );
        
      case FieldType.datetime:
        return DateTimeField(
          controller: _internalController,
          label: widget.label,
          hint: widget.hint,
          dateTimeFormat: widget.dateTimeFormat,
          locale: widget.locale,
          initialDate: widget.initialDate,
          initialTime: widget.initialTime,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onChanged: widget.onChanged,
          validators: validators.isNotEmpty ? validators : null,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          isMandatory: isMandatory,
        );
        
      default:
        return TextInputField(
          fieldType: widget.fieldType,
          controller: _internalController,
          label: widget.label,
          hint: widget.hint,
          helperText: widget.helperText,
          validators: validators.isNotEmpty ? validators : null,
          inputFormatters: widget.inputFormatters,
          onSaved: widget.onSaved,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          focusNode: widget.focusNode,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autovalidateMode: widget.autovalidateMode,
          textStyle: widget.textStyle,
          decoration: widget.decoration,
          readOnly: isReadOnly,
          enabled: widget.enabled,
          autoFocus: widget.autoFocus,
          showClearButton: widget.showClearButton,
          validationMode: widget.validationMode,
          prefixIcon: widget.prefixIcon,
          fillColor: widget.fillColor,
          isMandatory: isMandatory,
        );
    }
  }
  
  Widget _wrapWithLabel(Widget field) {
    if (widget.label == null) return field;
    
    final labelWidget = Text(
      widget.label!,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
    
    switch (widget.labelPosition) {
      case LabelPosition.top:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: 8),
            field,
          ],
        );
        
      case LabelPosition.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: labelWidget,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: field),
          ],
        );
        
      case LabelPosition.inline:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            labelWidget,
            const SizedBox(width: 10),
            Expanded(child: field),
          ],
        );
        
      default:
        return field;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    Widget field = _buildFieldWidget();
    
    // Apply sizing
    if (widget.width != null || widget.height != null) {
      field = SizedBox(
        width: widget.width,
        height: widget.height,
        child: field,
      );
    }
    
    // Apply padding
    if (widget.padding != null) {
      field = Padding(
        padding: widget.padding!,
        child: field,
      );
    }
    
    // Apply label positioning
    if (widget.labelPosition != LabelPosition.floating && widget.label != null) {
      field = _wrapWithLabel(field);
    }
    
    return field;
  }
}'""");
  return buffer.toString().replaceAll('\u00A0', ' ');
}
