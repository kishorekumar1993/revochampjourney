// lib/bloc/generators/screen/screen_generator.dart

import 'package:revojourneytryone/codegenerator/filegegnerator/journey_step_codegen.dart';
import 'screen_field_writers.dart';

class ScreenGenerator {
  ScreenGenerator({
    required this.featureName,
    required this.flatFields,
    required this.hasSubmit,
    this.stepJson,
  });

  final String featureName;
  final List<Map<String, dynamic>> flatFields;
  final bool hasSubmit;
  final Map<String, dynamic>? stepJson;

  String generate() {
    final writers = ScreenFieldWriters(
      featureName: featureName,
      flatFields: flatFields,
    );
    final snakeName = writers.toSnakeCase(featureName);
    final stateName = '${featureName}State';
    final blocName = '${featureName}Bloc';
    final stepMeta = JourneyStepCodegen.fromJson(stepJson ?? {});
    final buf = StringBuffer();

    // ─── Imports ──────────────────────────────────────────────────────────
    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_bloc.dart';");
    buf.writeln("import '../bloc/${snakeName}_state.dart';");
    buf.writeln("import '../bloc/${snakeName}_event.dart';");
    buf.writeln("import '../../../../../core/widgets/widgets.dart';");
    buf.writeln("import '../../../../../../core/routing/journey_routes.dart';");
    buf.writeln("import '/core/runtime/async_state.dart' as runtime;");
    buf.writeln("import '../../presentation/bloc/async_value.dart' as asyncv;");
    buf.writeln("import '../../../../../core/runtime/failure.dart';");

    // Import both wrapper and inner entities for API dropdowns
    final wrapperImports = <String>{};
    final innerImports = <String>{};
    for (final f in flatFields.where(writers.isApiDropdown)) {
      final wrapperFile = writers.resolveEntityFile(f);
      final innerFile = writers.resolveInnerEntityFile(f);
      wrapperImports.add(
        "import '../../domain/entity/${wrapperFile}_entity.dart';",
      );
      innerImports.add(
        "import '../../domain/entity/${innerFile}_entity.dart';",
      );
    }
    for (final imp in wrapperImports) {
      buf.writeln(imp);
    }
    for (final imp in innerImports) {
      buf.writeln(imp);
    }
    buf.writeln();

    // ─── Helper: get label from entity via toJson() ──────────────────────
    buf.writeln("String _getDropdownLabel(dynamic item, String key) {");
    buf.writeln("  try {");
    buf.writeln("    final json = item.toJson();");
    buf.writeln("    final value = json[key];");
    buf.writeln("    if (value == null) return '';");
    buf.writeln("    return value.toString();");
    buf.writeln("  } catch (_) {");
    buf.writeln("    return '';");
    buf.writeln("  }");
    buf.writeln("}");
    buf.writeln();

    buf.writeln("""
runtime.AsyncState<T> _toAsyncState<T>(
  asyncv.AsyncValue<T> asyncValue,
) {
  return asyncValue.when(
    idle: () => runtime.AsyncIdle<T>(),
    loading: () => runtime.AsyncLoading<T>(),
    data: (data) => runtime.AsyncSuccess<T>(data),
    error: (err) => runtime.AsyncFailure<T>(
      runtime.Failure(
        message: err.toString(),
      ),
    ),
  );
}

""");

    // ─── Screen widget ────────────────────────────────────────────────────
    buf.writeln('class ${featureName}Screen extends StatelessWidget {');
    buf.writeln('  const ${featureName}Screen({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return BlocListener<$blocName, $stateName>(');
    buf.writeln('      listenWhen: (prev, curr) =>');
    buf.writeln(
      '          prev.navigationTargetStepId != curr.navigationTargetStepId,',
    );
    buf.writeln('      listener: (context, state) {');
    buf.writeln('        final target = state.navigationTargetStepId;');
    buf.writeln('        if (target != null && target.isNotEmpty) {');
    buf.writeln("          Navigator.of(context).pushNamed(JourneyRoutes.pathForStep(target));");
    buf.writeln('        }');
    buf.writeln('        if (state.errorMessage != null) {');
    buf.writeln('          ScaffoldMessenger.of(context).showSnackBar(');
    buf.writeln('            SnackBar(content: Text(state.errorMessage!)),');
    buf.writeln('          );');
    buf.writeln('        }');
    buf.writeln('      },');
    buf.writeln('      child: Scaffold(');
    buf.writeln("      backgroundColor: const Color(0xFFF8FAFC),");
    buf.writeln("      appBar: AppBar(");
    buf.writeln(
      "        title: const Text('${stepMeta.escapedTitle}', style: TextStyle(fontWeight: FontWeight.w600)),",
    );
    buf.writeln("        backgroundColor: Colors.transparent,");
    buf.writeln("        foregroundColor: const Color(0xFF0F172A),");
    buf.writeln("        elevation: 0,");
    buf.writeln("        centerTitle: true,");
    buf.writeln("        actions: [");
    buf.writeln("          IconButton(");
    buf.writeln(
      "            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),",
    );
    buf.writeln("            tooltip: 'Reset',");
    buf.writeln(
      "            onPressed: () => context.read<$blocName>().add(const Reset${featureName}Event()),",
    );
    buf.writeln("          ),");
    buf.writeln("        ],");
    buf.writeln("      ),");
    buf.writeln("      body: const SafeArea(child: _${featureName}Body()),");
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ─── Body widget ─────────────────────────────────────────────────────
    buf.writeln('class _${featureName}Body extends StatelessWidget {');
    buf.writeln('  const _${featureName}Body();');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return Center(');
    buf.writeln('      child: ConstrainedBox(');
    buf.writeln('        constraints: const BoxConstraints(maxWidth: 600),');
    buf.writeln('        child: SingleChildScrollView(');
    buf.writeln(
      '          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),',
    );
    buf.writeln('          child: Container(');
    buf.writeln('            padding: const EdgeInsets.all(24),');
    buf.writeln('            decoration: BoxDecoration(');
    buf.writeln('              color: Colors.white,');
    buf.writeln('              borderRadius: BorderRadius.circular(20),');
    buf.writeln(
      '              border: Border.all(color: const Color(0xFFE2E8F0)),',
    );
    buf.writeln('            ),');
    buf.writeln('            child: Column(');
    buf.writeln('              crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('              children: [');
    stepMeta.writeFlutterStepHeader(buf);
    for (final f in flatFields.where(writers.isFormField)) {
      final fieldKey = writers.fieldName(f);
      buf.writeln(
        "                _${writers.cap(fieldKey)}Field(key: const ValueKey('$fieldKey')),",
      );
    }
    if (hasSubmit) {
      stepMeta.writeBlocActionButton(buf, featureName);
    }
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('          ),');
    buf.writeln('        ),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    buf.writeln();

    // ─── Field widgets ───────────────────────────────────────────────────
    for (final f in flatFields.where(writers.isFormField)) {
      writers.writeFieldClass(buf, f, stateName, blocName);
      buf.writeln();
    }

    return buf.toString();
  }
}
