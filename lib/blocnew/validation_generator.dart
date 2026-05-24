// lib/bloc/generators/validation/validation_generator.dart
// v4: Updated to produce simple String? validators with typed entity parameters.

import 'package:revojourneytryone/blocnew/field_schema.dart';

class ValidationGenerator {
  ValidationGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<FieldSchema> fields;

  String generate() {
    final validatorsName = '${featureName}Validators';
    final buf            = StringBuffer();

    // Import entity classes for dropdown fields
    for (final f in fields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
      final snake = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("import '../../domain/entities/${snake}_entity.dart';");
    }
    buf.writeln();
    buf.writeln('/// Auto-generated field validators for the $featureName feature.');
    buf.writeln('abstract final class $validatorsName {');
    buf.writeln();

    for (final f in fields) {
      _writeValidator(buf, f);
    }

    buf.writeln('}');
    return buf.toString();
  }

  void _writeValidator(StringBuffer buf, FieldSchema f) {
    final methodName = 'validate${toCap(f.fieldName)}';
    final paramType  = _validatorParamType(f);
    final paramName  = 'value';

    buf.writeln('  static String? $methodName($paramType $paramName) {');

    final errors = <String>[];

    // Required check
    if (f.isRequired) {
      switch (f.fieldType) {
        case FieldType.checkbox:
          errors.add(
            "    if (value != true) {\n"
            "      return '${f.label} must be accepted';\n"
            "    }");
        case FieldType.dropdown:
        case FieldType.asyncDropdown:
          errors.add(
            "    if (value == null) {\n"
            "      return 'Please select ${f.label.toLowerCase()}';\n"
            "    }");
        case FieldType.file:
        case FieldType.image:
          errors.add(
            "    if (value == null) {\n"
            "      return '${f.label} is required';\n"
            "    }");
        case FieldType.multiSelect:
          errors.add(
            "    if (value == null || value.isEmpty) {\n"
            "      return '${f.label} is required';\n"
            "    }");
        default:
          // String-based fields
          errors.add(
            "    if (value == null || value.trim().isEmpty) {\n"
            "      return '${f.label} is required';\n"
            "    }");
      }
    }

    // String-specific validations (for text fields)
    if (_isStringField(f)) {
      if (f.minLength != null) {
        errors.add(
          "    if (value != null && value.length < ${f.minLength}) {\n"
          "      return '${f.label} must be at least ${f.minLength} characters';\n"
          "    }");
      }
      if (f.maxLength != null) {
        errors.add(
          "    if (value != null && value.length > ${f.maxLength}) {\n"
          "      return '${f.label} must be at most ${f.maxLength} characters';\n"
          "    }");
      }
      if (f.fieldType == FieldType.email) {
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'^[\\w\\.\\+\\-]+@[\\w\\-]+\\.[a-zA-Z]{2,}\$').hasMatch(value)) {\n"
          "      return 'Enter a valid email address';\n"
          "    }");
      }
      if (f.fieldType == FieldType.phone) {
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'^\\+?[0-9\\s\\-\\(\\)]{7,15}\$').hasMatch(value)) {\n"
          "      return 'Enter a valid phone number';\n"
          "    }");
      }
      if (f.regex != null) {
        final errMsg = f.regexError ?? 'Invalid ${f.label}';
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'${f.regex}').hasMatch(value)) {\n"
          "      return '$errMsg';\n"
          "    }");
      }
    }

    // Numeric validations (value is String? so we parse)
    if (_isNumericField(f)) {
      if (f.minValue != null) {
        errors.add(
          "    if (value != null) {\n"
          "      final n = ${f.fieldType == FieldType.decimal ? 'double' : 'int'}.tryParse(value);\n"
          "      if (n != null && n < ${f.minValue}) {\n"
          "        return '${f.label} must be >= ${f.minValue}';\n"
          "      }\n"
          "    }");
      }
      if (f.maxValue != null) {
        errors.add(
          "    if (value != null) {\n"
          "      final n = ${f.fieldType == FieldType.decimal ? 'double' : 'int'}.tryParse(value);\n"
          "      if (n != null && n > ${f.maxValue}) {\n"
          "        return '${f.label} must be <= ${f.maxValue}';\n"
          "      }\n"
          "    }");
      }
    }

    for (final e in errors) {
      buf.writeln(e);
    }

    buf.writeln('    return null;');
    buf.writeln('  }');
    buf.writeln();
  }

  // ── Param type per field type ─────────────────────────────────────────────

  /// Returns the Dart parameter type for the validator method.
  /// Now uses specific entity types for dropdowns.
  String _validatorParamType(FieldSchema f) {
    if (f.isFileUpload || f.fieldType == FieldType.image) return 'dynamic';
    if (f.fieldType == FieldType.checkbox)  return 'bool?';
    if (f.fieldType == FieldType.date ||
        f.fieldType == FieldType.dateTime) {
      return 'DateTime?';
    }
    if (f.fieldType == FieldType.multiSelect) return 'List<String>?';
    if (f.fieldType == FieldType.dropdown ||
        f.fieldType == FieldType.asyncDropdown) {
      return '${f.entityClassName}?';   // e.g. NewTitelEntity?
    }
    // All text-based fields (String?, number, decimal)
    return 'String?';
  }

  bool _isStringField(FieldSchema f) =>
      !f.isFileUpload &&
      f.fieldType != FieldType.checkbox &&
      f.fieldType != FieldType.date &&
      f.fieldType != FieldType.dateTime &&
      f.fieldType != FieldType.multiSelect &&
      f.fieldType != FieldType.dropdown &&
      f.fieldType != FieldType.asyncDropdown &&
      f.fieldType != FieldType.image &&
      !_isNumericField(f);   // numeric fields are handled separately

  bool _isNumericField(FieldSchema f) =>
      f.fieldType == FieldType.number ||
      f.fieldType == FieldType.decimal;
}

// // lib/bloc/generators/validation/validation_generator.dart
// // v3: Fixes validator param types so they match FunctionValidator<T>:
// //   - String/email/phone/password/textarea → String?
// //   - checkbox → bool
// //   - date/dateTime → DateTime?
// //   - multiSelect → List<String>
// //   - dropdown/asyncDropdown → dynamic  (value is an entity, not a String)
// //   - file/image → dynamic

// import 'package:revojourneytryone/blocnew/field_schema.dart';

// class ValidationGenerator {
//   ValidationGenerator({
//     required this.featureName,
//     required this.fields,
//   });

//   final String featureName;
//   final List<FieldSchema> fields;

//   String generate() {
//     final validatorsName = '${featureName}Validators';
//     final buf            = StringBuffer();

//     buf.writeln("import '../../../../core/runtime/validation_error.dart';");
//     buf.writeln();
//     buf.writeln('/// Auto-generated field validators for the $featureName feature.');
//     buf.writeln('abstract final class $validatorsName {');
//     buf.writeln();

//     for (final f in fields) {
//       _writeValidator(buf, f);
//     }

//     buf.writeln('}');
//     return buf.toString();
//   }

//   void _writeValidator(StringBuffer buf, FieldSchema f) {
//     final methodName = 'validate${toCap(f.fieldName)}';
//     final paramType  = _validatorParamType(f);
//     final paramName  = 'value';

//     buf.writeln('  static ValidationError? $methodName($paramType $paramName) {');

//     final errors = <String>[];

//     // Required check — adapted per type
//     if (f.isRequired) {
//       switch (f.fieldType) {
//         case FieldType.checkbox:
//           errors.add(
//             "    if (value != true) {\n"
//             "      return const ValidationError(field: '${f.fieldName}', "
//             "message: '${f.label} must be accepted');\n"
//             "    }");
//         case FieldType.dropdown:
//         case FieldType.asyncDropdown:
//           // value is dynamic — check null
//           errors.add(
//             "    if (value == null) {\n"
//             "      return const ValidationError(field: '${f.fieldName}', "
//             "message: '${f.label} is required');\n"
//             "    }");
//         case FieldType.file:
//         case FieldType.image:
//           errors.add(
//             "    if (value == null) {\n"
//             "      return const ValidationError(field: '${f.fieldName}', "
//             "message: '${f.label} is required');\n"
//             "    }");
//         default:
//           // String-based fields
//           errors.add(
//             "    if (value == null || value.trim().isEmpty) {\n"
//             "      return const ValidationError(field: '${f.fieldName}', "
//             "message: '${f.label} is required');\n"
//             "    }");
//       }
//     }

//     // String-specific validations
//     if (_isStringField(f)) {
//       if (f.minLength != null) {
//         errors.add(
//           "    if (value != null && value.length < ${f.minLength}) {\n"
//           "      return const ValidationError(field: '${f.fieldName}', "
//           "message: '${f.label} must be at least ${f.minLength} characters');\n"
//           "    }");
//       }
//       if (f.maxLength != null) {
//         errors.add(
//           "    if (value != null && value.length > ${f.maxLength}) {\n"
//           "      return const ValidationError(field: '${f.fieldName}', "
//           "message: '${f.label} must be at most ${f.maxLength} characters');\n"
//           "    }");
//       }
//       if (f.fieldType == FieldType.email) {
//         errors.add(
//           r"    if (value != null && value.isNotEmpty && "
//           r"!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {" "\n"
//           "      return const ValidationError(field: '${f.fieldName}', "
//           "message: 'Enter a valid email address');\n"
//           "    }");
//       }
//       if (f.fieldType == FieldType.phone) {
//         errors.add(
//           r"    if (value != null && value.isNotEmpty && "
//           r"!RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$').hasMatch(value)) {" "\n"
//           "      return const ValidationError(field: '${f.fieldName}', "
//           "message: 'Enter a valid phone number');\n"
//           "    }");
//       }
//       if (f.regex != null) {
//         final errMsg = f.regexError ?? 'Invalid ${f.label}';
//         errors.add(
//           "    if (value != null && value.isNotEmpty && "
//           "!RegExp(r'${f.regex}').hasMatch(value)) {\n"
//           "      return const ValidationError(field: '${f.fieldName}', "
//           "message: '$errMsg');\n"
//           "    }");
//       }
//     }

//     // Numeric validations
//     if (_isNumericField(f)) {
//       if (f.minValue != null) {
//         errors.add(
//           "    if (value != null) {\n"
//           "      final n = ${f.fieldType == FieldType.decimal ? 'double' : 'int'}"
//           ".tryParse(value);\n"
//           "      if (n != null && n < ${f.minValue}) {\n"
//           "        return const ValidationError(field: '${f.fieldName}', "
//           "message: '${f.label} must be >= ${f.minValue}');\n"
//           "      }\n"
//           "    }");
//       }
//       if (f.maxValue != null) {
//         errors.add(
//           "    if (value != null) {\n"
//           "      final n = ${f.fieldType == FieldType.decimal ? 'double' : 'int'}"
//           ".tryParse(value);\n"
//           "      if (n != null && n > ${f.maxValue}) {\n"
//           "        return const ValidationError(field: '${f.fieldName}', "
//           "message: '${f.label} must be <= ${f.maxValue}');\n"
//           "      }\n"
//           "    }");
//       }
//     }

//     for (final e in errors) {
//       buf.writeln(e);
//     }

//     buf.writeln('    return null;');
//     buf.writeln('  }');
//     buf.writeln();
//   }

//   // ── Param type per field type ─────────────────────────────────────────────

//   /// Returns the Dart parameter type for the validator method.
//   /// Must match the T in `FunctionValidator<T>` in the generated BLoC.
//   String _validatorParamType(FieldSchema f) {
//     if (f.isFileUpload || f.fieldType == FieldType.image) return 'dynamic';
//     if (f.fieldType == FieldType.checkbox)  return 'bool';
//     if (f.fieldType == FieldType.date ||
//         f.fieldType == FieldType.dateTime) {
//       return 'DateTime?';
//     }
//     if (f.fieldType == FieldType.multiSelect) return 'List<String>';
//     // FIX: dropdown/asyncDropdown — value is an entity object, use dynamic
//     if (f.fieldType == FieldType.dropdown ||
//         f.fieldType == FieldType.asyncDropdown) {
//       return 'dynamic';
//     }
//     // All text-based fields
//     return 'String?';
//   }

//   bool _isStringField(FieldSchema f) =>
//       !f.isFileUpload &&
//       f.fieldType != FieldType.checkbox &&
//       f.fieldType != FieldType.date &&
//       f.fieldType != FieldType.dateTime &&
//       f.fieldType != FieldType.multiSelect &&
//       f.fieldType != FieldType.dropdown &&
//       f.fieldType != FieldType.asyncDropdown &&
//       f.fieldType != FieldType.image;

//   bool _isNumericField(FieldSchema f) =>
//       f.fieldType == FieldType.number ||
//       f.fieldType == FieldType.decimal;
// }
