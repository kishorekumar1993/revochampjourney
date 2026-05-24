// lib/bloc/generators/validation/validation_generator.dart
// v5: Fixes import path and handles dropdowns without entity classes.

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
    final buf = StringBuffer();
    final importedEntities = <String>{};

    // Import entity classes only for dropdowns that have a non‑empty entityClassName
    for (final f in fields.where((f) => f.isAsyncDropdown || f.isStaticDropdown)) {
      final entityClass = f.entityClassName;
      if (entityClass.isEmpty) continue; // static string dropdown – no entity
      if (importedEntities.contains(entityClass)) continue;
      importedEntities.add(entityClass);
      final baseName = entityClass.replaceAll('Entity', '');
      final snake = toSnakeCase(baseName);
      // Correct relative path: from presentation/validation/ to domain/entities/
      buf.writeln("import '../../domain/entities/${snake}_entity.dart';");
    }
    if (importedEntities.isNotEmpty) buf.writeln();

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
    final paramType = _validatorParamType(f);
    final paramName = 'value';

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
          // For dropdowns without entity (static strings), value is String?
          // For entity dropdowns, value is Entity?; both can be checked with null.
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
          errors.add(
            "    if (value == null || value.trim().isEmpty) {\n"
            "      return '${f.label} is required';\n"
            "    }");
      }
    }

    // String-specific validations
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
          "!RegExp(r'${_escapeRegex(f.regex!)}').hasMatch(value)) {\n"
          "      return '$errMsg';\n"
          "    }");
      }
    }

    // Numeric validations
    if (_isNumericField(f)) {
      if (f.minValue != null) {
        errors.add(
          "    if (value != null && value.isNotEmpty) {\n"
          "      final n = ${f.fieldType == FieldType.decimal ? 'double' : 'int'}.tryParse(value);\n"
          "      if (n != null && n < ${f.minValue}) {\n"
          "        return '${f.label} must be >= ${f.minValue}';\n"
          "      }\n"
          "    }");
      }
      if (f.maxValue != null) {
        errors.add(
          "    if (value != null && value.isNotEmpty) {\n"
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
  String _validatorParamType(FieldSchema f) {
    if (f.isFileUpload || f.fieldType == FieldType.image) return 'dynamic';
    if (f.fieldType == FieldType.checkbox) return 'bool?';
    if (f.fieldType == FieldType.date || f.fieldType == FieldType.dateTime) {
      return 'DateTime?';
    }
    if (f.fieldType == FieldType.multiSelect) return 'List<String>?';
    if (f.fieldType == FieldType.dropdown || f.fieldType == FieldType.asyncDropdown) {
      // If entityClassName is empty (static string dropdown), use String?
      return  'String?';
  //  return f.entityClassName.isNotEmpty ? '${f.entityClassName}?' : 'String?';
    }
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
      !_isNumericField(f);

  bool _isNumericField(FieldSchema f) =>
      f.fieldType == FieldType.number || f.fieldType == FieldType.decimal;

  // ── Helper functions ──────────────────────────────────────────────────
  String toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (var i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && RegExp(r'[A-Z]').hasMatch(char)) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  String _escapeRegex(String pattern) {
    return pattern.replaceAll(r'\', r'\\').replaceAll(r"'", r"\'");
  }
}