import 'dart:convert';

/// PascalCase conversion (e.g., "post title" → "PostTitle").
String toPascalCase(String input) {
  return input
      .split(RegExp(r'[\s_\-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

/// PascalCase/camelCase → snake_case.
String toSnakeCase(String input) {
  return input
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .toLowerCase();
}

/// Holds info about one async dropdown.
class _DropdownInfo {
  final String originalLabel;
  final String pascalName;
  final bool isSingleObject;
  const _DropdownInfo({
    required this.originalLabel,
    required this.pascalName,
    required this.isSingleObject,
  });
}

class JourneyUseCaseGenerator {
  final Map<String, dynamic> journeyJson;
  final String repositoryClassName; // e.g. "UserjourneyFormRepository"

  const JourneyUseCaseGenerator(
    this.journeyJson, {
    this.repositoryClassName = '',
  });

  String generate() {
    // Use provided class name, or fallback to journey name (without spaces)
    final repoClass = repositoryClassName.isNotEmpty
        ? repositoryClassName
        : (journeyJson['journeyName'] as String? ?? 'Feature').replaceAll(
            ' ',
            '',
          );

    final snakeFeature = toSnakeCase(repoClass.replaceAll('Repository', ''));
    final buf = StringBuffer();

    buf.writeln('// AUTO‑GENERATED — do not edit');
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln("import '/core/error/failures.dart';");
    buf.writeln(
      "import '../repository/${snakeFeature}_repository.dart';",
    ); // singular 'repository'

    // Collect async dropdowns
    final asyncDropdowns = <_DropdownInfo>[];
    _extractDropdowns(journeyJson, asyncDropdowns);

    // Import entities (deduplicated)
    final imported = <String>{};
    for (final d in asyncDropdowns) {
      final entityName = '${d.pascalName}Entity';
      if (imported.add(entityName)) {
        buf.writeln(
          "import '../entity/${toSnakeCase(d.pascalName)}_entity.dart';",
        );
      }
    }
    buf.writeln();

    // Use cases
    final generated = <String>{};
    for (final d in asyncDropdowns) {
      final className = 'Load${d.pascalName}ListUseCase';
      if (!generated.add(className)) continue;

      buf.writeln(
        '/// Fetches the list of ${d.originalLabel} for the dropdown.',
      );
      buf.writeln('class $className {');
      buf.writeln('  const $className(this._repository);');
      buf.writeln('  final $repoClass _repository;');
      buf.writeln();
      if (d.isSingleObject) {
        buf.writeln('  Future<Either<Failure, ${d.pascalName}Entity>> call() =>');
      } else {
        buf.writeln('  Future<Either<Failure, List<${d.pascalName}Entity>>> call() =>');
      }
      buf.writeln('      _repository.getAll${_pluralize(d.pascalName)}();');
      buf.writeln('}');
      buf.writeln();
    }

    return buf.toString();
  }

  String _pluralize(String word) {
    if (word.endsWith('y') && !word.endsWith('ey')) {
      return '${word.substring(0, word.length - 1)}ies';
    }

    if (word.endsWith('s')) {
      return word;
    }

    return '${word}s';
  }

  void _extractDropdowns(dynamic source, List<_DropdownInfo> out) {
    if (source == null) return;
    if (source is List) {
      for (final item in source) _extractDropdowns(item, out);
      return;
    }
    if (source is! Map<String, dynamic>) return;

    if (source.containsKey('steps')) {
      _extractDropdowns(source['steps'], out);
      return;
    }
    if (source.containsKey('fields')) {
      _extractDropdowns(source['fields'], out);
      return;
    }
    if (source.containsKey('type')) {
      final type = source['type'] as String?;
      if (type == 'dropdown' || type == 'api_dropdown') {
        final useStatic = source['useStaticOptions'] as bool? ?? false;
        final apiUrl = source['dropdownApiUrl'] as String?;
        final apiRequired = source['apiRequired'] == true;

        if (!useStatic && ((apiUrl != null && apiUrl.isNotEmpty) || apiRequired)) {
          final label = (source['label'] as String?) ?? 'Option';

          final isSingleObject = source['isSingleObject'] == true ||
              source['responseType'] == 'object' ||
              source['dropdowndata'] is Map;

          out.add(
            _DropdownInfo(
              originalLabel: label,
              pascalName: toPascalCase(label),
              isSingleObject: isSingleObject,
            ),
          );
        }
      }

      _extractDropdowns(source['nestedFields'], out);
      final config = source['componentConfig'];
      if (config is Map) {
        _extractDropdowns(config['fields'], out);
        _extractDropdowns(config['columns'], out);
      }
    }
  }
}
