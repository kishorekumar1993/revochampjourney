// lib/bloc/generators/barrel/barrel_generator.dart
//
// Generates barrel (index) export files for every layer so consumers
// import one file instead of many:
//   import 'features/user/user_feature.dart';  // exports everything

import 'package:revojourneytryone/blocnew/field_schema.dart';
import 'package:revojourneytryone/blocnew/field_schema.dart';


class BarrelGenerator {
  BarrelGenerator({
    required this.featureName,
    required this.fields,
    required this.baseName,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String baseName;

  /// Returns `Map<relativePath, content>`
  Map<String, String> generateAll() {
    final snakeName = toSnakeCase(featureName);
    final result    = <String, String>{};

    // Domain barrel
    result['${snakeName}_domain.dart'] = _domainBarrel(snakeName);

    // Data barrel
    result['${snakeName}_data.dart'] = _dataBarrel(snakeName);

    // Presentation barrel
    result['${snakeName}_presentation.dart'] = _presentationBarrel(snakeName);

    // Feature root barrel (exports all three)
    result['${snakeName}_feature.dart'] = _featureBarrel(snakeName);

    return result;
  }

  String _domainBarrel(String sn) {
    final asyncDropdowns = fields.where((f) => f.hasDropdownData).toList();
    final buf = StringBuffer();
    buf.writeln('// Domain layer exports for $featureName');
    buf.writeln("export 'domain/entities/${sn}_entity.dart';");
    buf.writeln("export 'domain/repositories/${sn}_repository.dart';");
    buf.writeln("export 'domain/usecases/${sn}_usecases.dart';");
    for (final f in asyncDropdowns) {
      final es = toSnakeCase(f.entityClassName.replaceAll('Entity', ''));
      buf.writeln("export 'domain/entities/${es}_entity.dart';");
    }
    return buf.toString();
  }

  String _dataBarrel(String sn) {
    final asyncDropdowns = fields.where((f) => f.hasDropdownData).toList();
    final buf = StringBuffer();
    buf.writeln('// Data layer exports for $featureName');
    buf.writeln("export 'data/datasources/${sn}_datasource.dart';");
    buf.writeln("export 'data/repositories/${sn}_repository_impl.dart';");
    for (final f in asyncDropdowns) {
      final ms = toSnakeCase(f.modelClassName.replaceAll('Model', ''));
      buf.writeln("export 'data/model/${ms}_model.dart';");
    }
    return buf.toString();
  }

  String _presentationBarrel(String sn) {
    final buf = StringBuffer();
    buf.writeln('// Presentation layer exports for $featureName');
    buf.writeln("export 'presentation/bloc/${sn}_bloc.dart';");
    buf.writeln("export 'presentation/state/${sn}_feature_state.dart';");
    buf.writeln("export 'presentation/events/${sn}_event.dart';");
    buf.writeln("export 'presentation/mapper/${sn}_mapper.dart';");
    buf.writeln("export 'presentation/validation/${sn}_validators.dart';");
    buf.writeln("export 'presentation/screens/${sn}_screen.dart';");
    return buf.toString();
  }

  String _featureBarrel(String sn) {
    final buf = StringBuffer();
    buf.writeln('// $featureName feature — single import entry point');
    buf.writeln("export '${sn}_domain.dart';");
    buf.writeln("export '${sn}_data.dart';");
    buf.writeln("export '${sn}_presentation.dart';");
    return buf.toString();
  }
}
