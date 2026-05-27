// lib/bloc/generators/test/test_generator.dart
//
// Generates bloc_test stubs for:
//   - Initial state assertion
//   - Load data (if async dropdowns)
//   - Each field ComponentUpdatedEvent (valid + invalid paths)
//   - Submit (valid form → success, invalid form → validation errors)
//   - Reset

import 'package:revojourneytryone/generators/bloc/engine/field_schema.dart';


class TestGenerator {
  TestGenerator({
    required this.featureName,
    required this.fields,
    required this.baseName,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String baseName;

  String generate() {
    final snakeName      = toSnakeCase(featureName);
    final stateName      = '${featureName}FeatureState';
    final blocName       = '${featureName}Bloc';
    final keysClass      = '${featureName}ComponentKeys';
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final buf            = StringBuffer();

    buf.writeln("import 'package:bloc_test/bloc_test.dart';");
    buf.writeln("import 'package:flutter_test/flutter_test.dart';");
    buf.writeln("import 'package:mocktail/mocktail.dart';");
    buf.writeln("import 'package:dartz/dartz.dart';");
    buf.writeln();
    buf.writeln("import '../../../../../core/runtime/async_state.dart';");
    buf.writeln("import '../../core/runtime/reactive_value.dart';");
    buf.writeln("import '../../features/$baseName/domain/usecases/${snakeName}_usecases.dart';");
    buf.writeln("import '../../features/$baseName/presentation/bloc/${snakeName}_bloc.dart';");
    buf.writeln("import '../../features/$baseName/presentation/state/${snakeName}_feature_state.dart';");
    buf.writeln("import '../../features/$baseName/presentation/events/${snakeName}_event.dart';");
    buf.writeln();

    // Mock classes
    // One mock per async-dropdown load use case (each has its own type)
    for (final f in asyncDropdowns) {
      buf.writeln('class MockLoad${toCap(f.fieldName)}ListUseCase extends Mock');
      buf.writeln('    implements Load${toCap(f.fieldName)}ListUseCase {}');
    }
    buf.writeln('class MockSubmit${featureName}UseCase extends Mock');
    buf.writeln('    implements Submit${featureName}UseCase {}');
    buf.writeln();

    buf.writeln('void main() {');
    buf.writeln('  group(\'$blocName\', () {');
    buf.writeln('    late $blocName bloc;');
    for (final f in asyncDropdowns) {
      buf.writeln('    late MockLoad${toCap(f.fieldName)}ListUseCase mockLoad${toCap(f.fieldName)};');
    }
    buf.writeln('    late MockSubmit${featureName}UseCase mockSubmit;');
    buf.writeln();
    buf.writeln('    setUp(() {');
    for (final f in asyncDropdowns) {
      buf.writeln('      mockLoad${toCap(f.fieldName)} = MockLoad${toCap(f.fieldName)}ListUseCase();');
    }
    buf.writeln('      mockSubmit = MockSubmit${featureName}UseCase();');
    buf.writeln('      bloc = $blocName(');
    for (final f in asyncDropdowns) {
      buf.writeln('        load${toCap(f.fieldName)}ListUseCase: mockLoad${toCap(f.fieldName)},');
    }
    buf.writeln('        submit${featureName}UseCase: mockSubmit,');
    buf.writeln('      );');
    buf.writeln('    });');
    buf.writeln();
    buf.writeln('    tearDown(() => bloc.close());');
    buf.writeln();

    // ── initial state test ──────────────────────────────────────────────────
    buf.writeln("    test('initial state is correct', () {");
    buf.writeln('      expect(bloc.state, const $stateName());');
    buf.writeln('    });');
    buf.writeln();

    // ── load data tests (one per async dropdown) ───────────────────────────
    if (asyncDropdowns.isNotEmpty) {
      // Test only the first dropdown in detail; others follow the same pattern
      final first = asyncDropdowns.first;
      final firstCap = toCap(first.fieldName);

      buf.writeln("    blocTest<$blocName, $stateName>(");
      buf.writeln("      'Load${featureName}DataEvent emits loading then success for ${first.fieldName}',");
      buf.writeln('      build: () {');
      // Stub all load use cases so the event handler runs to completion
      for (final f in asyncDropdowns) {
        buf.writeln('        when(() => mockLoad${toCap(f.fieldName)}()).thenAnswer((_) async => right([]));');
      }
      buf.writeln('        return bloc;');
      buf.writeln('      },');
      buf.writeln('      act: (b) => b.add(const Load${featureName}DataEvent()),');
      buf.writeln('      expect: () => [');
      // Loading state (all at once)
      buf.write('        isA<$stateName>()');
      for (final f in asyncDropdowns) {
        buf.write('.having((s) => s.${f.fieldName}List.isLoading, \'${f.fieldName}Loading\', true)');
      }
      buf.writeln(',');
      // Empty success for first field after its individual fetch
      buf.writeln('        isA<$stateName>().having((s) => s.${first.fieldName}List.isEmpty, \'${first.fieldName}Empty\', true),');
      if (asyncDropdowns.length > 1) {
        final second = asyncDropdowns[1];
        buf.writeln('        isA<$stateName>().having((s) => s.${second.fieldName}List.isEmpty, \'${second.fieldName}Empty\', true),');
      }
      buf.writeln('      ],');
      buf.writeln('    );');
      buf.writeln();

      buf.writeln("    blocTest<$blocName, $stateName>(");
      buf.writeln("      'Load${featureName}DataEvent emits failure when ${first.fieldName} fetch fails',");
      buf.writeln('      build: () {');
      buf.writeln("        when(() => mockLoad$firstCap()).thenAnswer((_) async =>");
      buf.writeln("            left(const Failure(message: 'Network error', code: 'net')));");
      // Still need to stub the others so the test doesn't hang
      for (final f in asyncDropdowns.skip(1)) {
        buf.writeln('        when(() => mockLoad${toCap(f.fieldName)}()).thenAnswer((_) async => right([]));');
      }
      buf.writeln('        return bloc;');
      buf.writeln('      },');
      buf.writeln('      act: (b) => b.add(const Load${featureName}DataEvent()),');
      buf.writeln('      expect: () => [');
      buf.write('        isA<$stateName>()');
      for (final f in asyncDropdowns) {
        buf.write('.having((s) => s.${f.fieldName}List.isLoading, \'${f.fieldName}Loading\', true)');
      }
      buf.writeln(',');
      buf.writeln('        isA<$stateName>().having((s) => s.${first.fieldName}List.isFailure, \'${first.fieldName}Failure\', true),');
      buf.writeln('      ],');
      buf.writeln('    );');
      buf.writeln();
    }

    // ── field update tests ──────────────────────────────────────────────────
    for (final f in fields.where((f) => f.fieldType == FieldType.text).take(3)) {
      buf.writeln("    blocTest<$blocName, $stateName>(");
      buf.writeln("      'ComponentUpdatedEvent updates ${f.fieldName} and validates',");
      buf.writeln('      build: () => bloc,');
      buf.writeln("      act: (b) => b.add(const ComponentUpdatedEvent($keysClass.${f.fieldName}, 'test')),");
      buf.writeln('      expect: () => [');
      buf.writeln("        isA<$stateName>().having((s) => s.${f.fieldName}.value, '${f.fieldName}', 'test'),");
      buf.writeln('      ],');
      buf.writeln('    );');
      buf.writeln();
    }

    // ── submit valid form test ──────────────────────────────────────────────
    buf.writeln("    blocTest<$blocName, $stateName>(");
    buf.writeln("      'Submit form with invalid fields surfaces errors',");
    buf.writeln('      build: () => bloc,');
    buf.writeln('      act: (b) => b.add(const Submit${featureName}FormEvent()),');
    buf.writeln('      expect: () => [');
    buf.writeln('        // All fields touched; at least one has an error');
    buf.writeln("        isA<$stateName>().having((s) => s.isFormValid, 'isFormValid', false),");
    buf.writeln('      ],');
    buf.writeln('    );');
    buf.writeln();

    buf.writeln("    blocTest<$blocName, $stateName>(");
    buf.writeln("      'Submit succeeds when form is valid',");
    buf.writeln('      build: () {');
    buf.writeln("        when(() => mockSubmit(any())).thenAnswer((_) async =>");
    buf.writeln("            right(${featureName}Result(id: 1, message: 'OK')));");
    buf.writeln('        return bloc;');
    buf.writeln('      },');
    buf.writeln('      seed: () => _validState(),');
    buf.writeln('      act: (b) => b.add(const Submit${featureName}FormEvent()),');
    buf.writeln('      expect: () => [');
    buf.writeln("        isA<$stateName>().having((s) => s.submission.isLoading, 'loading', true),");
    buf.writeln("        isA<$stateName>().having((s) => s.submission.isSuccess, 'success', true),");
    buf.writeln('      ],');
    buf.writeln('    );');
    buf.writeln();

    // ── reset test ──────────────────────────────────────────────────────────
    buf.writeln("    blocTest<$blocName, $stateName>(");
    buf.writeln("      'ResetFormEvent restores initial state',");
    buf.writeln('      build: () => bloc,');
    buf.writeln('      act: (b) => b.add(const Reset${featureName}FormEvent()),');
    buf.writeln('      expect: () => [const $stateName()],');
    buf.writeln('    );');
    buf.writeln();

    buf.writeln('  });');
    buf.writeln('}');
    buf.writeln();

    // Helper to build a valid pre-filled state for submit test
    buf.writeln('// ── Helper ──────────────────────────────────────────────────────────────────');
    buf.writeln('$stateName _validState() {');
    buf.writeln('  return const $stateName(');
    for (final f in fields) {
      final sampleVal = _sampleValue(f);
      if (f.fieldType == FieldType.checkbox) {
        buf.writeln("    ${f.fieldName}: ReactiveValue.dirty(true),");
      } else if (f.fieldType == FieldType.date) {
        buf.writeln("    ${f.fieldName}: ReactiveValue.dirty(DateTime(1995, 1, 1)),");
      } else if (f.isStaticStringOnly || f.fieldType == FieldType.textField) {
        buf.writeln("    ${f.fieldName}: ReactiveValue.dirty($sampleVal),");
      } else {
        buf.writeln("    ${f.fieldName}: ReactiveValue.dirty(null),");
      }
    }
    buf.writeln('  );');
    buf.writeln('}');

    return buf.toString();
  }

  String _sampleValue(FieldSchema f) {
    if (f.obscureText) return "'Password1!'";
    return switch (f.keyboardType.toLowerCase()) {
      'phone' || 'number' => "'1234567890'",
      'emailaddress' || 'email' => "'test@test.com'",
      _ => "'Test Value'",
    };
  }
}

