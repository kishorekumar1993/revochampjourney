// lib/bloc/generators/mapper/mapper_generator.dart
//
// Generates the Mapper class: FeatureState → Domain Entity

import 'package:revojourneytryone/blocnew/field_schema.dart';


class MapperGenerator {
  MapperGenerator({
    required this.featureName,
    required this.fields,
    required this.entityClassName,
    required this.stateName,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String entityClassName;
  final String stateName;

  String generate() {
    final mapperName = '${featureName}Mapper';
    final snakeName  = toSnakeCase(featureName);
    final buf        = StringBuffer();

    buf.writeln("import '../../domain/entities/${snakeName}_entity.dart';");
    buf.writeln("import '../state/${snakeName}_feature_state.dart';");
    buf.writeln();
    buf.writeln('/// Maps a validated [$stateName] to a [$entityClassName].');
    buf.writeln('abstract final class $mapperName {');
    buf.writeln('  static $entityClassName toEntity($stateName state) {');
    buf.writeln('    return $entityClassName(');
    for (final f in fields) {
      buf.writeln('      ${f.fieldName}: state.${f.fieldName}.value,');
    }
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');

    return buf.toString();
  }
}
