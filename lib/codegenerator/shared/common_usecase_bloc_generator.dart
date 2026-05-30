
/// PascalCase conversion
/// "post title" -> "PostTitle"
String toPascalCase(String input) {
  return input
      .split(RegExp(r'[\s_\-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

/// PascalCase/camelCase -> snake_case
String toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]}_${m[2]}',
      )
      .toLowerCase();
}

/// ======================================================
/// DROPDOWN INFO MODEL
/// ======================================================

class _DropdownInfo {
  final String originalLabel;
  final String pascalName;

  const _DropdownInfo({
    required this.originalLabel,
    required this.pascalName,
  });
}

/// ======================================================
/// JOURNEY USECASE GENERATOR
/// ======================================================

class JourneyBlocUseCaseGenerator {
  final Map<String, dynamic> journeyJson;

  /// Example:
  /// UserjourneyFormRepository
  final String repositoryClassName;

  const JourneyBlocUseCaseGenerator(
    this.journeyJson, {
    this.repositoryClassName = '',
  });

  /// ======================================================
  /// GENERATE
  /// ======================================================

  String generate() {
    /// --------------------------------------------------
    /// Resolve Repository Class
    /// --------------------------------------------------

    final repoClass = repositoryClassName.isNotEmpty
        ? repositoryClassName
        : (journeyJson['journeyName'] as String? ?? 'Feature')
            .replaceAll(' ', '');

    final snakeFeature = toSnakeCase(
      repoClass.replaceAll('Repository', ''),
    );

    final buf = StringBuffer();

    /// ==================================================
    /// HEADER
    /// ==================================================

    buf.writeln('// AUTO-GENERATED — do not edit');

    buf.writeln("import 'package:dartz/dartz.dart';");

    buf.writeln("import '/core/runtime/failure.dart';");

    buf.writeln(
      "import '../repository/${snakeFeature}_repository.dart';",
    );

    /// ==================================================
    /// FIND ALL API DROPDOWNS
    /// ==================================================

    final asyncDropdowns = <_DropdownInfo>[];

    _extractDropdowns(
      (journeyJson['steps'] as List?)
              ?.expand((step) => step['fields'] ?? [])
              .toList() ??
          [],
      asyncDropdowns,
    );

    /// ==================================================
    /// IMPORT ENTITIES
    /// ==================================================

    final imported = <String>{};

    for (final d in asyncDropdowns) {
      final field = _findFieldByLabel(d.originalLabel);
      final returnType = _resolveReturnType(field, '${d.pascalName}Entity');
      
      final isList = returnType.startsWith('List<');
      final actualEntity = isList 
          ? returnType.replaceAll('List<', '').replaceAll('>', '') 
          : returnType;

      if (imported.add(actualEntity)) {
        final snakeName = toSnakeCase(
          actualEntity.replaceAll('Entity', ''),
        );
        
        buf.writeln(
          "import '../entity/${snakeName}_entity.dart';",
        );
      }
    }

    buf.writeln();
    buf.writeln('class StepSubmissionResult {');
    buf.writeln('  final String? nextStepId;');
    buf.writeln('  final Map<String, dynamic>? payload;');
    buf.writeln();
    buf.writeln('  const StepSubmissionResult({');
    buf.writeln('    this.nextStepId,');
    buf.writeln('    this.payload,');
    buf.writeln('  });');
    buf.writeln();
    buf.writeln('  factory StepSubmissionResult.fromMap(Map<String, dynamic>? map) {');
    buf.writeln('    if (map == null) return const StepSubmissionResult();');
    buf.writeln("    return StepSubmissionResult(nextStepId: map['nextStepId']?.toString(), payload: map);");
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    /// ==================================================
    /// GENERATE INDIVIDUAL USECASES
    /// ==================================================

    final generatedUsecases = <String>{};
    final uniqueDropdowns = <_DropdownInfo>[];

    for (final d in asyncDropdowns) {
      final field = _findFieldByLabel(
        d.originalLabel,
      );

      final className =
          _buildUsecaseName(d, field);

      if (!generatedUsecases.add(className)) {
        continue;
      }
      
      uniqueDropdowns.add(d);

      final entityName =
          '${d.pascalName}Entity';

      final repositoryMethod =
          'getAll${_pluralize(d.pascalName)}';

      final returnType =
          _resolveReturnType(
        field,
        entityName,
      );

      buf.writeln(
        '/// Fetches the list of ${d.originalLabel} for the dropdown.',
      );

      buf.writeln(
        'class $className {',
      );

      buf.writeln(
        '  const $className(this._repository);',
      );

      buf.writeln();

      buf.writeln(
        '  final $repoClass _repository;',
      );

      buf.writeln();

      buf.writeln(
        '  Future<Either<Failure, $returnType>> call() async {',
      );

      buf.writeln(
        '    return await _repository.$repositoryMethod();',
      );

      buf.writeln(
        '  }',
      );

      buf.writeln('}');

      buf.writeln();
    }

    /// ==================================================
    /// GENERATE FACADE CLASS
    /// ==================================================

    final facadeClass =
        '${repoClass.replaceAll("Repository", "")}Usecases';

    buf.writeln('class $facadeClass {');

    /// --------------------------------------------------
    /// Constructor
    /// --------------------------------------------------

    buf.writeln('  const $facadeClass({required this.repository});');

    buf.writeln();

    /// --------------------------------------------------
    /// Variables
    /// --------------------------------------------------

    buf.writeln('  final $repoClass repository;');

    buf.writeln();

    /// --------------------------------------------------
    /// Methods
    /// --------------------------------------------------

    for (final d in uniqueDropdowns) {
      final field = _findFieldByLabel(
        d.originalLabel,
      );

      final entityName =
          '${d.pascalName}Entity';

      final returnType =
          _resolveReturnType(
        field,
        entityName,
      );
      
      final isList =
          returnType.startsWith('List<');

      final methodName = isList
          ? 'load${_pluralize(d.pascalName)}'
          : 'load${d.pascalName}';

      final repositoryMethod =
          'getAll${_pluralize(d.pascalName)}';

      buf.writeln(
        '  Future<Either<Failure, $returnType>> $methodName() async {',
      );

      buf.writeln(
        '    return await repository.$repositoryMethod();',
      );

      buf.writeln('  }');

      buf.writeln();
    }

    final steps = (journeyJson['steps'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final currentStep =
        steps.isNotEmpty ? steps.first : const <String, dynamic>{};
    final stepNext = currentStep['nextStep']?.toString();
    final stepValidations = (currentStep['validations'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final stepApiCalls = (currentStep['apiCalls'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final defaultApi = stepApiCalls.isNotEmpty
        ? stepApiCalls.first
        : const <String, dynamic>{};
    final defaultMethod = (defaultApi['method'] ?? 'POST').toString();
    final defaultUrl = (defaultApi['url'] ?? '').toString();

    buf.writeln('  Future<StepSubmissionResult?> submitStep({');
    buf.writeln('    required String stepId,');
    buf.writeln('    required Map<String, dynamic> formData,');
    buf.writeln('    required String trigger,');
    buf.writeln('  }) async {');
    for (final v in stepValidations) {
      final type = (v['type'] ?? '').toString().toLowerCase();
      final field = (v['field'] ?? '').toString();
      final msg = (v['message'] ?? 'Validation failed')
          .toString()
          .replaceAll("'", "\\'");
      if (field.isEmpty) continue;
      if (type == 'required') {
        buf.writeln("    final v_$field = formData['$field'];");
        buf.writeln(
            "    if (v_$field == null || v_$field.toString().trim().isEmpty) {");
        buf.writeln("      throw Exception('$msg');");
        buf.writeln('    }');
      } else if (type == 'regex' || type == 'pattern') {
        final regex = (v['regexPattern'] ?? '')
            .toString()
            .replaceAll(r"\", r"\\")
            .replaceAll("'", "\\'");
        if (regex.isEmpty) continue;
        buf.writeln("    final v_$field = formData['$field']?.toString() ?? '';");
        buf.writeln(
            "    if (v_$field.isNotEmpty && !RegExp(r'$regex').hasMatch(v_$field)) {");
        buf.writeln("      throw Exception('$msg');");
        buf.writeln('    }');
      }
    }
    if (defaultUrl.isNotEmpty) {
      buf.writeln("    final method = '$defaultMethod';");
      buf.writeln("    final url = '$defaultUrl';");
      buf.writeln('    final result = await repository.submitStep(');
      buf.writeln('      stepId: stepId,');
      buf.writeln('      formData: formData,');
      buf.writeln('      trigger: trigger,');
      buf.writeln('      method: method,');
      buf.writeln('      url: url,');
      buf.writeln('      body: formData,');
      buf.writeln('    );');
      buf.writeln('    return result.fold(');
      buf.writeln("      (failure) => throw Exception(failure.toString()),");
      if (stepNext != null && stepNext.isNotEmpty) {
        buf.writeln(
            "      (data) => StepSubmissionResult.fromMap({'nextStepId': '$stepNext', ...?data}),");
      } else {
        buf.writeln(
            "      (data) => StepSubmissionResult.fromMap(data),");
      }
      buf.writeln('    );');
    } else {
      if (stepNext != null && stepNext.isNotEmpty) {
        buf.writeln(
            "    return const StepSubmissionResult(nextStepId: '$stepNext');");
      } else {
        buf.writeln('    return const StepSubmissionResult();');
      }
    }
    buf.writeln('  }');
    buf.writeln();

    buf.writeln('}');

    return buf.toString();
  }

  /// ======================================================
  /// DETECT RESPONSE TYPE
  /// ======================================================

  bool _isWrapperResponse(
    Map<String, dynamic> field,
  ) {
    if (field['isWrapperResponse'] == true || 
        field['responseType'] == 'wrapper') {
      return true;
    }

    final data = field['dropdowndata'];

    if (data is! Map<String, dynamic>) {
      return false;
    }

    final listKeys = data.entries
        .where((e) => e.value is List)
        .toList();

    if (listKeys.isEmpty) {
      return false;
    }

    final hasMetadata = data.keys.any(
      (k) => k != listKeys.first.key,
    );

    return hasMetadata;
  }

  /// ======================================================
  /// RESOLVE RETURN TYPE
  /// ======================================================

  String _resolveReturnType(
    Map<String, dynamic> field,
    String entityName,
  ) {
    final isWrapper =
        _isWrapperResponse(field);

    if (isWrapper) {
      return entityName.replaceAll('Entity', 'ResponseEntity');
    }

    return 'List<$entityName>';
  }
  
  /// ======================================================
  /// BUILD USECASE NAME
  /// ======================================================

  String _buildUsecaseName(
    _DropdownInfo d,
    Map<String, dynamic> field,
  ) {
    final entityName =
        '${d.pascalName}Entity';

    final returnType =
        _resolveReturnType(field, entityName);

    final isList =
        returnType.startsWith('List<');

    return isList
        ? 'Load${d.pascalName}ListUseCase'
        : 'Load${d.pascalName}UseCase';
  }

  /// ======================================================
  /// FIND FIELD BY LABEL
  /// ======================================================

  Map<String, dynamic> _findFieldByLabel(
    String label,
  ) {
    final fields =
        (journeyJson['steps'] as List?)
                ?.expand(
                  (step) =>
                      step['fields'] ?? [],
                )
                .toList() ??
            [];

    return _findRecursive(
          fields,
          label,
        ) ??
        {};
  }

  Map<String, dynamic>? _findRecursive(
    List<dynamic> fields,
    String label,
  ) {
    for (final field in fields) {
      if (field is! Map<String, dynamic>) {
        continue;
      }

      if (field['label'] == label) {
        return field;
      }

      final nested =
          field['nestedFields'];

      if (nested is List) {
        final found =
            _findRecursive(
          nested,
          label,
        );

        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  /// ======================================================
  /// EXTRACT DROPDOWNS
  /// ======================================================

  void _extractDropdowns(
    Iterable<dynamic> fields,
    List<_DropdownInfo> out,
  ) {
    for (final field in fields) {
      if (field is! Map<String, dynamic>) {
        continue;
      }

      final type =
          field['type'] as String?;

      if (type == 'dropdown' || type == 'api_dropdown') {
        final useStatic =
            field['useStaticOptions']
                    as bool? ??
                false;

        final apiUrl =
            field['dropdownApiUrl']
                as String?;

        if (!useStatic &&
            apiUrl != null &&
            apiUrl.isNotEmpty) {
          final label =
              (field['label']
                      as String?) ??
                  'Option';

          out.add(
            _DropdownInfo(
              originalLabel:
                  label,
              pascalName:
                  toPascalCase(
                label,
              ),
            ),
          );
        }
      }

      /// Nested Fields
      final nested =
          field['nestedFields'];

      if (nested is List) {
        _extractDropdowns(
          nested,
          out,
        );
      }
    }
  }

  /// ======================================================
  /// HELPERS
  /// ======================================================

  String _pluralize(String word) {
    if (word.endsWith('y') &&
        !word.endsWith('ey')) {
      return '${word.substring(0, word.length - 1)}ies';
    }

    if (word.endsWith('s')) {
      return word;
    }

    return '${word}s';
  }

  String _toCamelCase(
    String input,
  ) {
    if (input.isEmpty) {
      return input;
    }

    return input[0].toLowerCase() +
        input.substring(1);
  }
}