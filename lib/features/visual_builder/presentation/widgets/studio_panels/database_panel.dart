import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../core/component_engine/models/database_config.dart';

import '../../../application/studio_providers.dart';
import 'studio_panel_wrapper.dart';

// 4. Database builder studio panel
class RevoDatabaseStudioPanel extends ConsumerStatefulWidget {
  const RevoDatabaseStudioPanel({super.key});

  @override
  ConsumerState<RevoDatabaseStudioPanel> createState() => _RevoDatabaseStudioPanelState();
}

class _RevoDatabaseStudioPanelState extends ConsumerState<RevoDatabaseStudioPanel> {
  TableConfig? _selectedTable;

  void _showGeneratedCode(String title, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text(title, style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
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

  String _generateRepository(TableConfig tc) {
    final capitalized = tc.name[0].toUpperCase() + tc.name.substring(1);
    return '''
import 'package:supabase_flutter/supabase_flutter.dart';

class ${capitalized}Repository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _supabase.from('${tc.name}').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insert(Map<String, dynamic> data) async {
    await _supabase.from('${tc.name}').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _supabase.from('${tc.name}').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('${tc.name}').delete().eq('id', id);
  }
}
''';
  }

  @override
  Widget build(BuildContext context) {
    final dbConfig = ref.watch(databaseConfigProvider);
    final notifier = ref.read(databaseConfigProvider.notifier);

    if (_selectedTable != null) {
      final table = _selectedTable!;
      return RevoStudioPanelWrapper(
        title: "Edit Table Scheme",
        subtitle: table.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            onPressed: () => setState(() => _selectedTable = null),
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    label: "Table Name",
                    value: table.name,
                    onChanged: (val) {
                      final upd = table.copyWith(name: val);
                      setState(() => _selectedTable = upd);
                      notifier.updateTable(table.name, upd);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Fields / Attributes", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF5B4FCF)),
                        onPressed: () {
                          final newField = FieldConfig(
                            name: 'field_${table.fields.length}',
                            type: 'String',
                          );
                          final upd = table.copyWith(fields: [...table.fields, newField]);
                          setState(() => _selectedTable = upd);
                          notifier.updateTable(table.name, upd);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  ...table.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              field.name,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            field.type,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5B4FCF)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () {
                              final upd = table.copyWith(
                                fields: table.fields.where((f) => f.name != field.name).toList(),
                              );
                              setState(() => _selectedTable = upd);
                              notifier.updateTable(table.name, upd);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showGeneratedCode(
                    "Generated Repository Class",
                    _generateRepository(table),
                  );
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.code_rounded, color: Colors.white),
                label: const Text("Generate Repository", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    return RevoStudioPanelWrapper(
      title: "Database Studio",
      subtitle: "Manage database models & endpoints",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () {
            final table = TableConfig(
              name: 'new_table_${dbConfig.tables.length}',
              fields: [
                FieldConfig(name: 'id', type: 'String', isPrimaryKey: true, isNullable: false),
              ],
            );
            notifier.addTable(table);
            setState(() => _selectedTable = table);
          },
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildDropdown(
              label: "Database Provider",
              value: dbConfig.type.toString().split('.').last,
              options: ['Firebase', 'Supabase', 'RestBackend'],
              onChanged: (val) {
                final type = DatabaseType.values.firstWhere((e) => e.toString().split('.').last == val);
                notifier.updateConfig(dbConfig.copyWith(type: type));
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dbConfig.tables.length,
              itemBuilder: (context, index) {
                final table = dbConfig.tables[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    child: ListTile(
                      onTap: () => setState(() => _selectedTable = table),
                      leading: const Icon(Icons.table_rows_rounded, color: Color(0xFF5B4FCF), size: 20),
                      title: Text(
                        table.name,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Columns: ${table.fields.length}",
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                        onPressed: () => notifier.deleteTable(table.name),
                      ),
                    ),
                  ),
                );
              },
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

