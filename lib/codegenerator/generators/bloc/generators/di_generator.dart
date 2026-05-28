// lib/bloc/generators/di_generator.dart

import '../engine/field_schema.dart';

/// Converts a PascalCase or camelCase string to snake_case.
String toSnakeCase(String name) {
  return name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  ).replaceFirst(RegExp(r'^_'), '');
}

/// Converts a string to PascalCase.
String toPascalCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split(RegExp(r'[\s_\-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}

class DiGenerator { /* unchanged single‑feature generator, same as your code */ }

class FeatureInfo {
  final String featureName;
  final String baseName;
  final List<FieldSchema> fields;
  final bool isInitialScreen;
  /// If true, the feature has API calls (submit, fetch dynamic options, etc.)
  /// and needs a remote data source + repository.
  final bool hasRemoteDataSource;

  FeatureInfo({
    required this.featureName,
    required this.baseName,
    required this.fields,
    this.isInitialScreen = false,
    this.hasRemoteDataSource = false, // default false, so you must opt‑in
  });
}

class GlobalDiGenerator {
  GlobalDiGenerator(this.features, this.journeyNamespace);
  final List<FeatureInfo> features;
  final String journeyNamespace;
  String generateMain() {
    final buf = StringBuffer();
    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    buf.writeln("import 'core/observer/bloc_observer.dart';");
    buf.writeln("import 'injection.dart';");

    FeatureInfo? targetFeat;
    if (features.isNotEmpty) {
      targetFeat = features.any((f) => f.isInitialScreen)
          ? features.firstWhere((f) => f.isInitialScreen)
          : features.first;
          
      final sn = toSnakeCase(targetFeat.featureName);
      final bn = targetFeat.baseName;
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/screens/${sn}_screen.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/bloc/${sn}_bloc.dart';");
      for (final feat in features) {
        final featSn = toSnakeCase(feat.featureName);
        final featBn = feat.baseName;
        if (featBn == bn) continue;
        buf.writeln("import 'features/$journeyNamespace/$featBn/presentation/screens/${featSn}_screen.dart';");
        buf.writeln("import 'features/$journeyNamespace/$featBn/presentation/bloc/${featSn}_bloc.dart';");
      }
    }

    buf.writeln();
    buf.writeln('Future<void> main() async {');
    buf.writeln('  WidgetsFlutterBinding.ensureInitialized();');
    buf.writeln('  Bloc.observer = AppBlocObserver();');
    buf.writeln('  await configureDependencies();');
    buf.writeln('  runApp(const MyApp());');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('class MyApp extends StatelessWidget {');
    buf.writeln('  const MyApp({super.key});');
    buf.writeln('  @override');
    buf.writeln('  Widget build(BuildContext context) {');
    buf.writeln('    return MaterialApp(');
    buf.writeln("      title: 'Journey',");
    buf.writeln('      debugShowCheckedModeBanner: false,');
    buf.writeln('      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),');

    if (targetFeat != null) {
      final pascalFeat = toPascalCase(targetFeat.featureName);
      buf.writeln('      home: BlocProvider(');
      buf.writeln('        create: (_) => getIt<${pascalFeat}Bloc>(),');
      buf.writeln('        child: const ${pascalFeat}Screen(),');
      buf.writeln('      ),');
      buf.writeln('      onGenerateRoute: (settings) {');
      buf.writeln("        final name = settings.name ?? '';");
      buf.writeln("        if (name.startsWith('/journey/')) {");
      buf.writeln("          final stepId = name.substring('/journey/'.length);");
      buf.writeln('          switch (stepId) {');
      for (final feat in features) {
        final featPascal = toPascalCase(feat.featureName);
        buf.writeln("            case '${feat.baseName}':");
        buf.writeln('              return MaterialPageRoute(');
        buf.writeln('                builder: (_) => BlocProvider(');
        buf.writeln('                  create: (_) => getIt<${featPascal}Bloc>(),');
        buf.writeln('                  child: const ${featPascal}Screen(),');
        buf.writeln('                ),');
        buf.writeln('              );');
      }
      buf.writeln('            default:');
      buf.writeln('              return null;');
      buf.writeln('          }');
      buf.writeln('        }');
      buf.writeln('        return null;');
      buf.writeln('      },');
    } else {
      buf.writeln('      home: const Scaffold(body: Center(child: Text("No screens generated"))),');
    }

    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    return buf.toString();
  }
  
  String generateInjection() {
    final buf = StringBuffer();
    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:get_it/get_it.dart';");
    buf.writeln("import 'package:shared_preferences/shared_preferences.dart';");

    final needsRemote = features.any((f) => f.hasRemoteDataSource);
    if (needsRemote) {
      buf.writeln("import 'core/service/api_service.dart';");
    }

    // Storage service (for caching async dropdowns) if any feature uses it
    bool anyCached = false;
    for (final f in features) {
      if (f.fields.where((x) => x.isAsyncDropdown).any(
            (x) => x.cacheKey != null || x.isLocalStorageEnabled)) {
        anyCached = true;
        break;
      }
    }
    if (anyCached) {
      buf.writeln("import 'core/storage/storage_service.dart';");
      buf.writeln("import 'core/storage/shared_prefs_storage_service.dart';");
    }

    // Feature‑specific imports
    for (final feat in features) {
      final sn = toSnakeCase(feat.featureName);
      final bn = feat.baseName;

      buf.writeln(
          "import 'features/$journeyNamespace/$bn/data/dataSource/${sn}_data_source.dart';");
      buf.writeln(
          "import 'features/$journeyNamespace/$bn/data/repositoryimpl/${sn}_repositoryimpl.dart';");
      buf.writeln(
          "import 'features/$journeyNamespace/$bn/domain/repository/${sn}_repository.dart';");
      buf.writeln(
          "import 'features/$journeyNamespace/$bn/domain/usecases/${sn}_usecases.dart';");
      buf.writeln(
          "import 'features/$journeyNamespace/$bn/presentation/bloc/${sn}_bloc.dart';");
    }

    buf.writeln();
    buf.writeln('final getIt = GetIt.instance;');
    buf.writeln();
    buf.writeln('Future<void> configureDependencies() async {');
    buf.writeln('  await configureAppDependencies();');
    for (final feat in features) {
      final pascalFeat = toPascalCase(feat.featureName);
      buf.writeln('  await configure${pascalFeat}Dependencies();');
    }
    buf.writeln('}');
    buf.writeln();

    buf.write(buildAppDependenciesMethod(anyCached, needsRemote));

    for (final feat in features) {
      final fn = feat.featureName;
      final hasCached = feat.fields.where((x) => x.isAsyncDropdown).any(
          (x) => x.cacheKey != null || x.isLocalStorageEnabled);
      buf.writeln();
      buf.write(
        buildFeatureDiMethod(fn, hasCached, true, feat.hasRemoteDataSource),
      );
    }

    return buf.toString();
  }

  // generateMain() method unchanged – same as yours
}

// ── Shared builder functions ──────────────────────────────────────

String buildAppDependenciesMethod(bool hasCached, bool needsDio) {
  final buf = StringBuffer();
  buf.writeln('Future<void> configureAppDependencies() async {');
  buf.writeln();
  buf.writeln('  // ── Shared Preferences ──────────────────────────────────');
  buf.writeln('  final prefs = await SharedPreferences.getInstance();');
  if (hasCached) {
    buf.writeln('  if (!getIt.isRegistered<StorageService>()) {');
    buf.writeln(
        '    getIt.registerLazySingleton<StorageService>(() => SharedPrefsStorageService(prefs));');
    buf.writeln('  }');
  }
  if (needsDio) {
    buf.writeln();
    buf.writeln('  // ── ApiService (lazy singleton) ─────────────────────────');
    buf.writeln('  if (!getIt.isRegistered<ApiService>()) {');
    buf.writeln('    getIt.registerLazySingleton<ApiService>(() => ApiService(');
    buf.writeln("      baseUrl: '',");
    buf.writeln('    ));');
    buf.writeln('  }');
  }
  buf.writeln('}');
  return buf.toString();
}

String buildFeatureDiMethod(
    String featureName, bool hasCached, bool hasUseCases, bool hasRemoteDataSource) {
  final pascalFeat = toPascalCase(featureName);
  final buf = StringBuffer();
  buf.writeln(
      'Future<void> configure${pascalFeat}Dependencies() async {');
  buf.writeln();

  if (hasRemoteDataSource) {
    buf.writeln(
        '  // ── DataSource ───────────────────────────────────────────');
    buf.writeln(
        '  if (!getIt.isRegistered<${pascalFeat}DataSource>()) {');
    buf.writeln(
        '    getIt.registerLazySingleton<${pascalFeat}DataSource>(');
    buf.writeln(
        '      () => ${pascalFeat}DataSourceImpl(getIt<ApiService>()),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
    buf.writeln(
        '  // ── Repository ──────────────────────────────────────────');
    buf.writeln(
        '  if (!getIt.isRegistered<${pascalFeat}Repository>()) {');
    buf.writeln(
        '    getIt.registerLazySingleton<${pascalFeat}Repository>(');
    buf.writeln(
        '      () => ${pascalFeat}RepoImpl(getIt<${pascalFeat}DataSource>()),');
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln();
  }

  buf.writeln(
      '  // ── Use Cases (combined) ─────────────────────────────────');
  buf.writeln(
      '  if (!getIt.isRegistered<${pascalFeat}Usecases>()) {');
  buf.writeln(
      '    getIt.registerLazySingleton<${pascalFeat}Usecases>(');
  buf.writeln('      () => ${pascalFeat}Usecases(');
  buf.writeln('        repository: getIt<${pascalFeat}Repository>(),');
  buf.writeln('      ),');
  buf.writeln('    );');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln(
      '  // ── BLoC ────────────────────────────────────────────────');
  buf.writeln('  if (!getIt.isRegistered<${pascalFeat}Bloc>()) {');
  buf.writeln('    getIt.registerFactory(');
  buf.writeln('      () => ${pascalFeat}Bloc(');
  buf.writeln('        usecases: getIt<${pascalFeat}Usecases>(),');
  buf.writeln('      ),');
  buf.writeln('    );');
  buf.writeln('  }');
  buf.writeln('}');
  return buf.toString();
}