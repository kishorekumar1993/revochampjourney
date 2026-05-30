import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/component_engine/models/app_variable.dart';
import '../../../application/studio_providers.dart';

import 'studio_panel_wrapper.dart';

// 5. App Variables studio manager panel
class RevoVariablesPanel extends ConsumerWidget {
  const RevoVariablesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appVariablesProvider);
    final notifier = ref.read(appVariablesProvider.notifier);

    void showGenerateSnippet(BuildContext context) {
      final code = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStateController extends StateNotifier<Map<String, dynamic>> {
  AppStateController() : super({
    ${list.map((v) => "'${v.name}': ${v.defaultValue is String ? "'${v.defaultValue}'" : v.defaultValue}").join(',\n    ')}
  });

  void updateVariable(String key, dynamic value) {
    state = {...state, key: value};
  }
}

final appStateProvider = StateNotifierProvider<AppStateController, Map<String, dynamic>>((ref) {
  return AppStateController();
});
''';

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text("Generated Riverpod Provider", style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: TextField(
                controller: TextEditingController(text: code),
                maxLines: null,
                readOnly: true,
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Colors.black,
                  filled: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          );
        },
      );
    }

    return RevoStudioPanelWrapper(
      title: "State Variables",
      subtitle: "Manage app-level reactive state variables",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final id = 'var_${DateTime.now().millisecondsSinceEpoch}';
            final newVar = AppVariable(
              id: id,
              name: 'newVariable',
              type: 'String',
              defaultValue: 'Default',
              currentValue: 'Default',
              scope: VariableScope.app,
            );
            notifier.addVariable(newVar);
          },
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final v = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  v.name,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => notifier.deleteVariable(v.id),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: "Type",
                                  value: v.type,
                                  options: ['String', 'int', 'double', 'bool', 'List', 'Map'],
                                  onChanged: (val) {
                                    notifier.updateVariable(v.id, v.copyWith(type: val));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDropdown(
                                  label: "Scope",
                                  value: v.scope.toString().split('.').last,
                                  options: ['app', 'page', 'component', 'session'],
                                  onChanged: (val) {
                                    final sc = VariableScope.values.firstWhere((e) => e.toString().split('.').last == val);
                                    notifier.updateVariable(v.id, v.copyWith(scope: sc));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => showGenerateSnippet(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.code_rounded, color: Colors.white),
              label: const Text("Generate Providers", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Common UI helper widgets ---

Widget _buildTextField({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}

