// lib/features/visual_builder/application/variables_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/component_engine/models/app_variable.dart';

// App Variables notifier
class AppVariablesNotifier extends StateNotifier<List<AppVariable>> {
  AppVariablesNotifier() : super([
    AppVariable(
      id: 'var_user_name',
      name: 'userName',
      type: 'String',
      defaultValue: 'Guest',
      currentValue: 'Guest',
      scope: VariableScope.app,
    ),
    AppVariable(
      id: 'var_is_logged_in',
      name: 'isLoggedIn',
      type: 'bool',
      defaultValue: false,
      currentValue: false,
      scope: VariableScope.session,
    ),
  ]);

  void addVariable(AppVariable variable) {
    state = [...state, variable];
  }

  void updateVariable(String id, AppVariable updated) {
    state = state.map((v) => v.id == id ? updated : v).toList();
  }

  void deleteVariable(String id) {
    state = state.where((v) => v.id != id).toList();
  }
}

final appVariablesProvider = StateNotifierProvider<AppVariablesNotifier, List<AppVariable>>((ref) {
  return AppVariablesNotifier();
});

final selectedVariableIdProvider = StateProvider<String?>((ref) => null);

final selectedVariableProvider = Provider<AppVariable?>((ref) {
  final selectedId = ref.watch(selectedVariableIdProvider);
  if (selectedId == null) return null;
  final vars = ref.watch(appVariablesProvider);
  for (final v in vars) {
    if (v.id == selectedId) return v;
  }
  return null;
});

final variableSearchQueryProvider = StateProvider<String>((ref) => '');
