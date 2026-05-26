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
  const _DropdownInfo({required this.originalLabel, required this.pascalName});
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
    _extractDropdowns(
      (journeyJson['steps'] as List?)?.expand((step) => step['fields'] ?? []) ??
          [],
      asyncDropdowns,
    );

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
    for (final d in asyncDropdowns) {
      final className = 'Load${d.pascalName}ListUseCase';
      buf.writeln(
        '/// Fetches the list of ${d.originalLabel} for the dropdown.',
      );
      buf.writeln('class $className {');
      buf.writeln('  const $className(this._repository);');
      buf.writeln('  final $repoClass _repository;');
      buf.writeln();
      // Return single entity, method name matches existing API
      buf.writeln('  Future<Either<Failure, ${d.pascalName}Entity>> call() =>');
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

  void _extractDropdowns(Iterable<dynamic> fields, List<_DropdownInfo> out) {
    for (final field in fields) {
      if (field is! Map<String, dynamic>) continue;

      final type = field['type'] as String?;
      if (type == 'dropdown') {
        final useStatic = field['useStaticOptions'] as bool? ?? true;
        final apiUrl = field['dropdownApiUrl'] as String?;
        if (!useStatic && apiUrl != null && apiUrl.isNotEmpty) {
          final label = (field['label'] as String?) ?? 'Option';
          out.add(
            _DropdownInfo(
              originalLabel: label,
              pascalName: toPascalCase(label),
            ),
          );
        }
      }

      final nested = field['nestedFields'];
      if (nested is List) _extractDropdowns(nested, out);
    }
  }
}
