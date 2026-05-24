String riverpodModelGenerateClass(
  String className,
  Map<String, dynamic> json,
  String fileName, {
  bool isNested = false,
}) {
  final StringBuffer buffer = StringBuffer();

  // Add imports and part directives only for the top-level class
  if (!isNested) {
    buffer.writeln(
      "import 'package:freezed_annotation/freezed_annotation.dart';\n",
    );
    buffer.writeln("import '../../domain/entity/${fileName}_entity.dart';");
    buffer.writeln("part '${fileName}_model.freezed.dart';");
    buffer.writeln("part '${fileName}_model.g.dart';\n");
  }

  // Generate Freezed class
  buffer.writeln('@freezed');
  buffer.writeln('abstract class ${className}Model with _\$${className}Model {');
  buffer.writeln('  const ${className}Model._();');
  buffer.writeln('  const factory ${className}Model({');

  json.forEach((key, value) {
    final String type = _getDartType(value, key);
    buffer.writeln('    $type? $key,');
  });

  buffer.writeln('  }) = _${className}Model;\n');
  buffer.writeln(
    '  factory ${className}Model.fromJson(Map<String, dynamic> json) => _\$${className}ModelFromJson(json);\n',
  );

  // Generate toDomain method
  buffer.writeln('  ${className}Entity toDomain() => ${className}Entity(');

  json.forEach((key, value) {
    if (_isNestedObject(value)) {
      buffer.writeln('    $key: $key?.toDomain(),');
    } else if (_isListOfObjects(value)) {
      buffer.writeln('    $key: $key?.map((e) => e.toDomain()).toList(),');
    } else {
      buffer.writeln('    $key: $key,');
    }
  });

  buffer.writeln('  );');
  buffer.writeln('}\n');

  // Recursively generate nested model classes
  json.forEach((key, value) {
    if (_isNestedObject(value)) {
      final nestedClassName = _capitalize(key);
      buffer.writeln(
        riverpodModelGenerateClass(
          nestedClassName,
          value as Map<String, dynamic>,
          fileName,
          isNested: true,
        ),
      );
    } else if (_isListOfObjects(value)) {
      final nestedClassName = _capitalize(_singularize(key));
      buffer.writeln(
        riverpodModelGenerateClass(
          nestedClassName,
          (value as List).first as Map<String, dynamic>,
          fileName,
          isNested: true,
        ),
      );
    }
  });

  return buffer.toString();
}

/// Get Dart type based on value
String _getDartType(dynamic value, String key) {
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is List) {
    if (value.isNotEmpty && value.first is Map<String, dynamic>) {
      return 'List<${_capitalize(_singularize(key))}Model>';
    }
    return 'List<dynamic>';
  }
  if (value is Map<String, dynamic>) {
    return '${_capitalize(key)}Model';
  }
  return 'dynamic';
}

bool _isNestedObject(dynamic value) => value is Map<String, dynamic>;

bool _isListOfObjects(dynamic value) =>
    value is List && value.isNotEmpty && value.first is Map<String, dynamic>;

String _capitalize(String text) =>
    text.isEmpty ? '' : '${text[0].toUpperCase()}${text.substring(1)}';

String _singularize(String text) {
  if (text.endsWith('ies')) {
    return '${text.substring(0, text.length - 3)}y';
  }
  if (text.endsWith('s') && text.length > 1) {
    return text.substring(0, text.length - 1);
  }
  return text;
}

// // It's good practice to have the part files explicitly in your actual file.
// // For the generator itself, we don't need them here.
// // part 'productnamemodel.freezed.dart';
// // part 'productnamemodel.g.dart';

// /// Generates a Freezed model class and its corresponding toDomain() method
// /// from a given class name and JSON structure.
// ///
// /// [className]: The desired name for the generated Freezed model class (e.g., 'Product').
// /// [json]: The JSON data (as a Map) from which to infer types and fields.
// /// [isNested]: A flag to indicate if this is a nested class generation,
// ///             which affects import statements and part directives.
// String riverpodModelGenerateClass(
//   String className,
//   Map<String, dynamic> json, String fileName, {
//   bool isNested = false,
// }) {
//   final StringBuffer buffer = StringBuffer();

//   // Only add imports and part directives for the top-level class
//   if (!isNested) {
//     buffer.writeln("import 'package:freezed_annotation/freezed_annotation.dart';\n");
//     // Ensure file names are lowercase as per convention
//     // final String fileName = className.toLowerCase();
//     buffer.writeln("part '${fileName}_model.freezed.dart';");
//     buffer.writeln("part '${fileName}_model.g.dart';\n");
//   }

//   // Generate the Freezed class definition
//   buffer.writeln('@freezed');
//   buffer.writeln('class ${className}Model with _\$${className}Model {');
//   buffer.writeln('  ${className}Model._();'); // Private constructor for custom methods
//   buffer.writeln('  factory ${className}Model({');

//   // Add fields based on JSON keys and inferred types
//   json.forEach((key, value) {
//     // Determine the Dart type for the field
//     final String type = _getDartType(value, key);
//     // Add the nullable field declaration
//     buffer.writeln('    $type? $key,');
//   });

//   buffer.writeln('  }) = _${className}Model;\n');

//   // Add the fromJson factory constructor for JSON deserialization
//   buffer.writeln(
//       '  factory ${className}Model.fromJson(Map<String, dynamic> json) => _\$${className}ModelFromJson(json);\n');

//   // Add the toDomain() method for mapping to domain entities
//   buffer.writeln('  ${className}Entity toDomain() => ${className}Entity(');

//   json.forEach((key, value) {
//     // Check if the value is a nested object or a list of objects
//     if (_isNestedObject(value)) {
//       // If it's a nested object, call its toDomain()
//       buffer.writeln('    $key: $key?.toDomain(),');
//     } else if (_isListOfObjects(value)) {
//       // If it's a list of objects, map each element to its domain entity
//       buffer.writeln('    $key: $key?.map((e) => e.toDomain()).toList(),');
//     } else {
//       // Otherwise, directly assign the value
//       buffer.writeln('    $key: $key,');
//     }
//   });

//   buffer.writeln('  );');
//   buffer.writeln('}\n'); // Close the class definition

//   // Recursively generate additional classes for nested objects and lists of objects
//   json.forEach((key, value) {
//     if (_isNestedObject(value)) {
//       // Generate for a single nested object (Map)
//       buffer.writeln(riverpodModelGenerateClass(
//           _capitalize("${key}Model"), value as Map<String, dynamic>,fileName,
//           isNested: true));
//     } else if (_isListOfObjects(value)) {
//       // Generate for elements within a list of objects (List containing Maps)
//       buffer.writeln(riverpodModelGenerateClass(
//           _capitalize("${key}Model"), (value as List).first as Map<String, dynamic>,fileName,
//           isNested: true));
//     }
//   });

//   return buffer.toString();
// }

// /// Infers the appropriate Dart type for a given JSON value.
// ///
// /// [value]: The JSON value to inspect.
// /// [key]: The key associated with the value (used for naming nested classes).
// String _getDartType(dynamic value, String key) {
//   if (value is int) {
//     return 'int';
//   }
//   if (value is double) {
//     return 'double';
//   }
//   if (value is String) {
//     return 'String';
//   }
//   if (value is bool) {
//     return 'bool';
//   }
//   if (value is List) {
//     // If the list is not empty and its first element is a Map,
//     // it's a list of nested objects.
//     if (value.isNotEmpty && value.first is Map<String, dynamic>) {
//       return 'List<${_capitalize(key)}Model>';
//     }
//     // Otherwise, it's a list of primitives or mixed types, default to dynamic.
//     return 'List<dynamic>';
//   }
//   if (value is Map<String, dynamic>) {
//     // If it's a Map, it's a nested object.
//     return _capitalize(key);
//   }
//   // Fallback for any other unexpected types (e.g., null, or truly unknown)
//   return 'dynamic';
// }

// /// Checks if a dynamic value represents a nested JSON object (Map).
// bool _isNestedObject(dynamic value) => value is Map<String, dynamic>;

// /// Checks if a dynamic value represents a non-empty list of JSON objects (List containing Maps).
// bool _isListOfObjects(dynamic value) =>
//     value is List && value.isNotEmpty && value.first is Map<String, dynamic>;

// /// Capitalizes the first letter of a given string.
// String _capitalize(String text) {
//   if (text.isEmpty) {
//     return '';
//   }
//   return text[0].toUpperCase() + text.substring(1);
// }
