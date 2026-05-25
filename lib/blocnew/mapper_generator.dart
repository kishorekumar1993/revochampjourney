// lib/bloc/generators/mapper/mapper_generator.dart
//
// Generates the Mapper class: FeatureState → Domain Entity

import 'package:revojourneytryone/blocnew/field_schema.dart';

class MapperGenerator {
  MapperGenerator({
    required this.featureName,
    required this.fields,
    required this.entityClassName,
    this.stateName, // optional, defaults to ${featureName}State
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String entityClassName;
  final String? stateName;

  String get _stateName => stateName ?? '${featureName}State';
  String get _snakeName => _toSnakeCase(featureName);

  String generate() {
    final mapperName = '${featureName}Mapper';
    final buf = StringBuffer();

    buf.writeln("import '../../domain/entities/${_snakeName}_entity.dart';");
    buf.writeln("import '../../presentation/state/${_snakeName}_feature_state.dart';");
    buf.writeln();
    buf.writeln('/// Maps a validated [$_stateName] to a [$entityClassName].');
    buf.writeln('abstract final class $mapperName {');
    buf.writeln('  static $entityClassName toEntity(${_stateName.replaceAll("Feature", '')} state) {');
    buf.writeln('    return $entityClassName(');
    for (final f in fields) {
      buf.writeln('      ${f.fieldName}: state.${f.fieldName}.value,');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }

  // Helper: convert PascalCase/camelCase to snake_case
  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    buffer.write(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      final char = input[i];
      if (char.toUpperCase() == char && char != char.toLowerCase()) {
        buffer.write('_${char.toLowerCase()}');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}