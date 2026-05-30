import 'package:revojourneytryone/core/component_engine/models/app_variable.dart';

class VariableCodeGenerator {
  static String formatValue(dynamic val) {
    if (val == null) return 'null';
    if (val is String) return "'$val'";
    return val.toString();
  }

  static String generateRiverpodCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';\n");
    buffer.writeln("class AppStateController extends StateNotifier<Map<String, dynamic>> {");
    buffer.writeln("  AppStateController() : super({");
    for (final v in list) {
      buffer.writeln("    '${v.name}': ${formatValue(v.defaultValue)},");
    }
    buffer.writeln("  });\n");
    buffer.writeln("  void updateVariable(String key, dynamic value) {");
    buffer.writeln("    state = {...state, key: value};");
    buffer.writeln("  }");
    buffer.writeln("}\n");
    buffer.writeln("final appStateProvider = StateNotifierProvider<AppStateController, Map<String, dynamic>>((ref) {");
    buffer.writeln("  return AppStateController();");
    buffer.writeln("});");
    return buffer.toString();
  }

  static String generateGetXCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:get/get.dart';\n");
    buffer.writeln("class AppStateController extends GetxController {");
    for (final v in list) {
      final obsSuffix = v.type == 'int' ? 'obs' : v.type == 'double' ? 'obs' : v.type == 'bool' ? 'obs' : 'obs';
      buffer.writeln("  final ${v.name} = ${formatValue(v.defaultValue)}.$obsSuffix;");
    }
    buffer.writeln("\n  void updateVariable(String key, dynamic value) {");
    buffer.writeln("    switch (key) {");
    for (final v in list) {
      buffer.writeln("      case '${v.name}':");
      buffer.writeln("        ${v.name}.value = value;");
      buffer.writeln("        break;");
    }
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln("}");
    return buffer.toString();
  }

  static String generateBlocCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_bloc/flutter_bloc.dart';\n");
    buffer.writeln("class AppState {");
    for (final v in list) {
      buffer.writeln("  final ${v.type} ${v.name};");
    }
    buffer.writeln("\n  AppState({");
    for (final v in list) {
      buffer.writeln("    required this.${v.name},");
    }
    buffer.writeln("  });\n");
    buffer.writeln("  AppState copyWith({");
    for (final v in list) {
      buffer.writeln("    ${v.type}? ${v.name},");
    }
    buffer.writeln("  }) {");
    buffer.writeln("    return AppState({");
    for (final v in list) {
      buffer.writeln("      ${v.name}: ${v.name} ?? this.${v.name},");
    }
    buffer.writeln("    });");
    buffer.writeln("  }");
    buffer.writeln("}\n");
    buffer.writeln("class AppStateCubit extends Cubit<AppState> {");
    buffer.writeln("  AppStateCubit() : super(AppState(");
    for (final v in list) {
      buffer.writeln("    ${v.name}: ${formatValue(v.defaultValue)},");
    }
    buffer.writeln("  ));\n");
    buffer.writeln("  void updateVariable(String key, dynamic value) {");
    for (final v in list) {
      buffer.writeln("    if (key == '${v.name}') {");
      buffer.writeln("      emit(state.copyWith(${v.name}: value as ${v.type}?));");
      buffer.writeln("    }");
    }
    buffer.writeln("  }");
    buffer.writeln("}");
    return buffer.toString();
  }

  static String generateProviderCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';\n");
    buffer.writeln("class AppStateProvider extends ChangeNotifier {");
    for (final v in list) {
      buffer.writeln("  ${v.type} _${v.name} = ${formatValue(v.defaultValue)};");
      buffer.writeln("  ${v.type} get ${v.name} => _${v.name};");
      buffer.writeln("  set ${v.name}(${v.type} val) {");
      buffer.writeln("    _${v.name} = val;");
      buffer.writeln("    notifyListeners();");
      buffer.writeln("  }\n");
    }
    buffer.writeln("}");
    return buffer.toString();
  }

  static String generateMobXCode(List<AppVariable> list) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:mobx/mobx.dart';\n");
    buffer.writeln("part 'app_state.g.dart';\n");
    buffer.writeln("class AppState = _AppStateBase with _\$AppState;\n");
    buffer.writeln("abstract class _AppStateBase with Store {");
    for (final v in list) {
      buffer.writeln("  @observable");
      buffer.writeln("  ${v.type} ${v.name} = ${formatValue(v.defaultValue)};\n");
      buffer.writeln("  @action");
      buffer.writeln("  void set${v.name[0].toUpperCase()}${v.name.substring(1)}(${v.type} val) => ${v.name} = val;\n");
    }
    buffer.writeln("}");
    return buffer.toString();
  }
}
