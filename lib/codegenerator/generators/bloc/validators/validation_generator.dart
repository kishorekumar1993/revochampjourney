// lib/bloc/generators/validation/validation_generator.dart
// Generates validators for a map‑based form state.

class ValidationGenerator {
  /// [featureName] – PascalCase feature name (e.g., "UserjourneyForm")
  /// [fields] – flattened field maps from JSON (output of flattenBlocFields)
  ValidationGenerator({
    required this.featureName,
    required this.fields,
  });

  final String featureName;
  final List<Map<String, dynamic>> fields;

  String generate() {
    final validatorsName = '${featureName}Validators';
    final buf = StringBuffer();
    final importedEntities = <String>{};

    // Import entities only for async dropdowns that have dropdowndata
    for (final f in fields.where(_isAsyncDropdown)) {
      final entityClass = _resolveEntityClass(f);
      if (entityClass.isEmpty) continue;
      if (importedEntities.contains(entityClass)) continue;
      importedEntities.add(entityClass);
      // import commented out — entity files not generated in current pipeline;
    }
    if (importedEntities.isNotEmpty) buf.writeln();

    buf.writeln('/// Auto-generated field validators for the $featureName feature.');
    buf.writeln('abstract final class $validatorsName {');
    buf.writeln();

    // Generate a validator for each field that is a real input (skip card/group)
    for (final f in fields.where(_isFormField)) {
      _writeValidator(buf, f);
    }

    buf.writeln('}');
    return buf.toString();
  }

  void _writeValidator(StringBuffer buf, Map<String, dynamic> field) {
    final fieldKey = _fieldName(field);            // e.g., "postTitle"
    final methodName = 'validate${_cap(fieldKey)}';
    final paramType = _validatorParamType(field); // String?, bool?, etc.
    final paramName = 'value';

    buf.writeln('  static String? $methodName($paramType $paramName) {');

    final errors = <String>[];
    final label = (field['label'] ?? fieldKey).toString();
    final isRequired = field['required'] == true;
    final type = (field['type'] ?? '').toString().toLowerCase();

    // --- Required validation ---
    if (isRequired) {
      switch (type) {
        case 'checkbox':
        case 'switch':
          errors.add(
            "    if (value != true) {\n"
            "      return '$label must be accepted';\n"
            "    }");
          break;
        case 'dropdown':
        case 'api_dropdown':
        case 'radio':
          errors.add(
            "    if (value == null) {\n"
            "      return 'Please select ${label.toLowerCase()}';\n"
            "    }");
          break;
        case 'file':
        case 'image':
          errors.add(
            "    if (value == null) {\n"
            "      return '$label is required';\n"
            "    }");
          break;
        case 'multiselect':
        case 'multi_select':
          errors.add(
            "    if (value == null || (value as List).isEmpty) {\n"
            "      return '$label is required';\n"
            "    }");
          break;
        default:
          errors.add(
            "    if (value == null || value.toString().trim().isEmpty) {\n"
            "      return '$label is required';\n"
            "    }");
      }
    }

    // --- String validations (minLength, maxLength, email, phone, regex) ---
    if (_isStringField(field)) {
      final minLen = field['minLength'];
      if (minLen != null) {
        errors.add(
          "    if (value != null && value.length < $minLen) {\n"
          "      return '$label must be at least $minLen characters';\n"
          "    }");
      }
      final maxLen = field['maxLength'];
      if (maxLen != null) {
        errors.add(
          "    if (value != null && value.length > $maxLen) {\n"
          "      return '$label must be at most $maxLen characters';\n"
          "    }");
      }
      if (type == 'email') {
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'^[\\w\\.\\+\\-]+@[\\w\\-]+\\.[a-zA-Z]{2,}\$').hasMatch(value)) {\n"
          "      return 'Enter a valid email address';\n"
          "    }");
      }
      if (type == 'phone') {
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'^\\+?[0-9\\s\\-\\(\\)]{7,15}\$').hasMatch(value)) {\n"
          "      return 'Enter a valid phone number';\n"
          "    }");
      }
      final regex = field['regex'];
      if (regex != null) {
        final errMsg = field['regexError'] ?? 'Invalid $label';
        errors.add(
          "    if (value != null && value.isNotEmpty && "
          "!RegExp(r'${_escapeRegex(regex)}').hasMatch(value)) {\n"
          "      return '$errMsg';\n"
          "    }");
      }
    }

    // --- Numeric validations (minValue, maxValue) ---
    if (_isNumericField(field)) {
      final minVal = field['minValue'];
      final maxVal = field['maxValue'];
      final numType = (type == 'decimal' || type == 'double') ? 'double' : 'int';
      if (minVal != null) {
        errors.add(
          "    if (value != null && value.isNotEmpty) {\n"
          "      final n = $numType.tryParse(value);\n"
          "      if (n != null && n < $minVal) {\n"
          "        return '$label must be >= $minVal';\n"
          "      }\n"
          "    }");
      }
      if (maxVal != null) {
        errors.add(
          "    if (value != null && value.isNotEmpty) {\n"
          "      final n = $numType.tryParse(value);\n"
          "      if (n != null && n > $maxVal) {\n"
          "        return '$label must be <= $maxVal';\n"
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

  // --- Helper: Determine validator parameter type ---
  String _validatorParamType(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    switch (type) {
      case 'checkbox':
      case 'switch':
        return 'bool?';
      case 'date':
      case 'datetime':
      case 'date time':
        return 'DateTime?';
      case 'multiselect':
      case 'multi_select':
        return 'List<String>?';
      case 'file':
      case 'image':
        return 'dynamic';
      default:
        return 'String?';
    }
  }

  // --- Classify field types ---
  bool _isStringField(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    const stringTypes = {'text', 'textfield', 'textarea', 'email', 'password', 'phone', 'otp', 'formula'};
    return stringTypes.contains(type);
  }

  bool _isNumericField(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    return type == 'number' || type == 'integer' || type == 'int' || type == 'decimal' || type == 'double';
  }

  bool _isAsyncDropdown(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    if (type != 'dropdown' && type != 'api_dropdown') return false;
    final useStatic = field['useStaticOptions'] == true;
    final hasApiUrl = field['dropdownApiUrl'] != null;
    return !useStatic && hasApiUrl;
  }

  bool _isFormField(Map<String, dynamic> field) {
    final type = (field['type'] ?? '').toString().toLowerCase();
    // Skip container types that hold no value
    const skipTypes = {'card', 'group', 'section', 'step', 'tab', 'container'};
    return !skipTypes.contains(type);
  }

  // --- Entity class resolution (same as in bloc generator) ---
  String _resolveEntityClass(Map<String, dynamic> field) {
    final dropdowndata = field['dropdowndata'];
    if (dropdowndata is Map<String, dynamic>) {
      for (final entry in dropdowndata.entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
          return '${_cap(_singularize(entry.key))}Entity';
        }
      }
    }
    // Fallback – but for async dropdowns this shouldn't happen
    final label = field['label'] ?? field['id'] ?? 'item';
    return '${_cap(_singularize(label))}Entity';
  }

  // --- Common utilities (matching bloc generator) ---
  bool _isAutoId(String? id) {
    if (id == null) return true;
    return RegExp(r'^field_\d+$').hasMatch(id.trim());
  }

  String _fieldName(Map<String, dynamic> f) {
    final id = f['id']?.toString().trim();
    final label = (f['label'] ?? f['fieldId'] ?? 'field').toString().trim();
    if (_isAutoId(id)) return _labelToCamel(label);
    final raw = (id ?? label);
    final n = raw.replaceAll(RegExp(r'\s+'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String _labelToCamel(String label) {
    final parts = label.trim().split(RegExp(r'[\s_\-]+'));
    if (parts.isEmpty) return 'field';
    final first = parts.first;
    final rest = parts.skip(1).map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1);
    }).join();
    final camel = first[0].toLowerCase() + first.substring(1) + rest;
    final n = camel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _singularize(String text) {
    if (text.endsWith('ies')) {
      return '${text.substring(0, text.length - 3)}y';
    }
    if (text.endsWith('s') && text.length > 1) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && RegExp(r'[A-Z]').hasMatch(char)) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _escapeRegex(String pattern) {
    return pattern.replaceAll(r'\', r'\\').replaceAll(r"'", r"\'");
  }
}