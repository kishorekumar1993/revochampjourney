// lib/bloc/generators/di_generator.dart
// Uses combined use cases (${featureName}Usecases) – matches BLoC generator.

import 'field_schema.dart';

class DiGenerator {
  DiGenerator({
    required this.featureName,
    required this.fields,
    required this.baseName,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final String baseName;

  String generateInjection() {
    final snakeName = toSnakeCase(featureName);
    final asyncDropdowns = fields.where((f) => f.isAsyncDropdown).toList();
    final hasCached = asyncDropdowns.any(
        (f) => f.cacheKey != null || f.isLocalStorageEnabled);
    final buf = StringBuffer();

    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:get_it/get_it.dart';");
    buf.writeln("import 'package:shared_preferences/shared_preferences.dart';");
    buf.writeln("import 'core/network/dio_client.dart';");
    buf.writeln("import 'core/network/interceptors/auth_interceptor.dart';");
    if (hasCached) {
      buf.writeln("import 'core/storage/local_storage_service.dart';");
    }
    buf.writeln(
        "import 'features/$baseName/data/datasources/${snakeName}_datasource.dart';");
    buf.writeln(
        "import 'features/$baseName/data/repositories/${snakeName}_repository_impl.dart';");
    buf.writeln(
        "import 'features/$baseName/domain/repositories/${snakeName}_repository.dart';");
    buf.writeln(
        "import 'features/$baseName/domain/usecases/${snakeName}_usecases.dart';");
    buf.writeln(
        "import 'features/$baseName/presentation/bloc/${snakeName}_bloc.dart';");
    buf.writeln();
    buf.writeln('final getIt = GetIt.instance;');
    buf.writeln();
    buf.writeln('Future<void> configureDependencies() async {');
    buf.writeln();
    buf.writeln('  // ── Shared Preferences ──────────────────────────────────');
    buf.writeln('  final prefs = await SharedPreferences.getInstance();');
    if (hasCached) {
      buf.writeln(
          '  getIt.registerSingleton<LocalStorageService>(LocalStorageService(prefs));');
    }
    buf.writeln();
    buf.writeln('  // ── Dio Client ───────────────────────────────────────────');
    buf.writeln('  getIt.registerSingleton<DioClient>(DioClient(');
    buf.writeln(
        "    baseUrl: const String.fromEnvironment('API_BASE_URL',");
    buf.writeln("        defaultValue: 'https://api.example.com'),");
    buf.writeln('    extraInterceptors: [');
    buf.writeln('      AuthInterceptor(');
    buf.writeln(
        '        getToken: () async => prefs.getString(\'auth_token\'),');
    buf.writeln('      ),');
    buf.writeln('    ],');
    buf.writeln('  ));');
    buf.writeln();
    buf.writeln('  // ── DataSource ───────────────────────────────────────────');
    buf.writeln(
        '  getIt.registerLazySingleton<${featureName}RemoteDataSource>(');
    buf.writeln('    () => ${featureName}RemoteDataSourceImpl(');
    buf.writeln('      client: getIt<DioClient>(),');
    if (hasCached) {
      buf.writeln('      storage: getIt<LocalStorageService>(),');
    }
    buf.writeln('    ),');
    buf.writeln('  );');
    buf.writeln();
    buf.writeln('  // ── Repository ──────────────────────────────────────────');
    buf.writeln(
        '  getIt.registerLazySingleton<${featureName}Repository>(');
    buf.writeln(
        '    () => ${featureName}RepositoryImpl(getIt<${featureName}RemoteDataSource>()),');
    buf.writeln('  );');
    buf.writeln();
    buf.writeln('  // ── Use Cases (combined) ─────────────────────────────────');
    buf.writeln('  getIt.registerLazySingleton(() =>');
    buf.writeln(
        '      ${featureName}Usecases(getIt<${featureName}Repository>()));');
    buf.writeln();
    buf.writeln('  // ── BLoC ────────────────────────────────────────────────');
    buf.writeln('  getIt.registerFactory(() => ${featureName}Bloc(');
    buf.writeln('    usecases: getIt<${featureName}Usecases>(),');
    buf.writeln('  ));');
    buf.writeln('}');

    return buf.toString();
  }

  String generateMain() {
    final snakeName = toSnakeCase(featureName);
    final hasAsyncDropdown = fields.any((f) => f.isAsyncDropdown);
    final loadEventStr = hasAsyncDropdown
        ? '\n               ..add(const Load${featureName}DataEvent())'
        : '';

    return '''
// AUTO-GENERATED — do not edit
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/observer/bloc_observer.dart';
import 'injection.dart';
import 'features/$baseName/presentation/screens/${snakeName}_screen.dart';
import 'features/$baseName/presentation/bloc/${snakeName}_bloc.dart';
import 'features/$baseName/presentation/events/${snakeName}_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$featureName',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => getIt<${featureName}Bloc>()$loadEventStr,
        child: const ${featureName}Screen(),
      ),
    );
  }
}
''';
  }

  // ── Helper functions ──────────────────────────────────────────────────────
  String toSnakeCase(String input) {
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

  String toCap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

class FeatureInfo {
  final String featureName;
  final String baseName;
  final List<FieldSchema> fields;
  FeatureInfo({required this.featureName, required this.baseName, required this.fields});
}

class GlobalDiGenerator {
  GlobalDiGenerator(this.features, this.journeyNamespace);
  final List<FeatureInfo> features;
  final String journeyNamespace;

  String generateInjection() {
    final buf = StringBuffer();
    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:get_it/get_it.dart';");
    buf.writeln("import 'package:shared_preferences/shared_preferences.dart';");
    buf.writeln("import 'core/network/dio_client.dart';");
    buf.writeln("import 'core/network/interceptors/auth_interceptor.dart';");
    
    bool anyCached = false;
    for (final f in features) {
      if (f.fields.where((x) => x.isAsyncDropdown).any((x) => x.cacheKey != null || x.isLocalStorageEnabled)) {
        anyCached = true;
        break;
      }
    }
    if (anyCached) {
      buf.writeln("import 'core/storage/local_storage_service.dart';");
    }

    for (final feat in features) {
      final sn = _toSnakeCase(feat.featureName);
      final bn = feat.baseName;
      buf.writeln("import 'features/$journeyNamespace/$bn/data/datasources/${sn}_datasource.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/data/repositories/${sn}_repository_impl.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/domain/repositories/${sn}_repository.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/domain/usecases/${sn}_usecases.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/bloc/${sn}_bloc.dart';");
    }

    buf.writeln();
    buf.writeln('final getIt = GetIt.instance;');
    buf.writeln();
    buf.writeln('Future<void> configureDependencies() async {');
    buf.writeln('  final prefs = await SharedPreferences.getInstance();');
    if (anyCached) {
      buf.writeln('  getIt.registerSingleton<LocalStorageService>(LocalStorageService(prefs));');
    }
    buf.writeln('  getIt.registerSingleton<DioClient>(DioClient(');
    buf.writeln("    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com'),");
    buf.writeln('    extraInterceptors: [AuthInterceptor(getToken: () async => prefs.getString(\\\'auth_token\\\'))],');
    buf.writeln('  ));');

    for (final feat in features) {
      final fn = feat.featureName;
      final hasCached = feat.fields.where((x) => x.isAsyncDropdown).any((x) => x.cacheKey != null || x.isLocalStorageEnabled);
      buf.writeln();
      buf.writeln('  // -- $fn --');
      buf.writeln('  getIt.registerLazySingleton<${fn}RemoteDataSource>(');
      buf.writeln('    () => ${fn}RemoteDataSourceImpl(');
      buf.writeln('      client: getIt<DioClient>(),');
      if (hasCached) buf.writeln('      storage: getIt<LocalStorageService>(),');
      buf.writeln('    ),');
      buf.writeln('  );');
      buf.writeln('  getIt.registerLazySingleton<${fn}Repository>(');
      buf.writeln('    () => ${fn}RepositoryImpl(getIt<${fn}RemoteDataSource>()),');
      buf.writeln('  );');
      buf.writeln('  getIt.registerLazySingleton(() => ${fn}Usecases(getIt<${fn}Repository>()));');
      buf.writeln('  getIt.registerFactory(() => ${fn}Bloc(usecases: getIt<${fn}Usecases>()));');
    }
    buf.writeln('}');
    return buf.toString();
  }

  String generateMain() {
    final buf = StringBuffer();
    buf.writeln('// AUTO-GENERATED — do not edit');
    buf.writeln("import 'package:flutter/material.dart';");
    buf.writeln("import 'package:flutter_bloc/flutter_bloc.dart';");
    buf.writeln("import 'core/observer/bloc_observer.dart';");
    buf.writeln("import 'injection.dart';");
    
    for (final feat in features) {
      final sn = _toSnakeCase(feat.featureName);
      final bn = feat.baseName;
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/screens/${sn}_screen.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/bloc/${sn}_bloc.dart';");
      buf.writeln("import 'features/$journeyNamespace/$bn/presentation/events/${sn}_event.dart';");
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
    
    if (features.isNotEmpty) {
      final firstFeat = features.first;
      final hasAsync = firstFeat.fields.any((x) => x.isAsyncDropdown);
      final loadStr = hasAsync ? '..add(const Load${firstFeat.featureName}DataEvent())' : '';
      buf.writeln('      home: BlocProvider(');
      buf.writeln('        create: (_) => getIt<${firstFeat.featureName}Bloc>()$loadStr,');
      buf.writeln('        child: const ${firstFeat.featureName}Screen(),');
      buf.writeln('      ),');
    } else {
      buf.writeln('      home: const Scaffold(body: Center(child: Text("No screens generated"))),');
    }
    
    buf.writeln('    );');
    buf.writeln('  }');
    buf.writeln('}');
    return buf.toString();
  }

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