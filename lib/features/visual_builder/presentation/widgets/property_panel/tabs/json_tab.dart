import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/visual_builder_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InteractiveJsonEditor — JSON schema editor widget used in the JSON tab.
// ─────────────────────────────────────────────────────────────────────────────

class InteractiveJsonEditor extends ConsumerStatefulWidget {
  final String initialJson;
  final bool Function(String) onApply;

  const InteractiveJsonEditor({
    super.key,
    required this.initialJson,
    required this.onApply,
  });

  @override
  ConsumerState<InteractiveJsonEditor> createState() => _InteractiveJsonEditorState();
}

class _InteractiveJsonEditorState extends ConsumerState<InteractiveJsonEditor> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialJson);
  }

  @override
  void didUpdateWidget(covariant InteractiveJsonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialJson != widget.initialJson) {
      _controller.text = widget.initialJson;
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importJsonFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        String? jsonStr;
        final file = result.files.first;
        if (file.bytes != null) {
          jsonStr = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          final ioFile = io.File(file.path!);
          jsonStr = await ioFile.readAsString();
        }

        if (jsonStr != null) {
          final success = widget.onApply(jsonStr);
          if (success) {
            _controller.text = jsonStr;
            setState(() => _error = null);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("JSON file imported successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            setState(() => _error = "Failed to parse JSON file content. Verify standard keys.");
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking file: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _applyJson(BuildContext context) {
    final success = widget.onApply(_controller.text);
    setState(() {
      if (success) {
        _error = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Visual Canvas applied successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _error = "Invalid JSON Layout Schema";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "JSON Screen Schema Editor",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _iconBtn(
                    icon: Icons.check_rounded,
                    tooltip: "Apply JSON Schema",
                    onPressed: () => _applyJson(context),
                  ),
                  _iconBtn(
                    icon: Icons.paste_rounded,
                    tooltip: "Paste & Import",
                    onPressed: () => _showImportPasteDialog(context),
                  ),
                  _iconBtn(
                    icon: Icons.upload_file_rounded,
                    tooltip: "Import JSON File",
                    onPressed: () => _importJsonFile(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.black,
                filled: true,
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(4),
      tooltip: tooltip,
      icon: Icon(icon, size: 16, color: const Color(0xFF5B4FCF)),
      onPressed: onPressed,
    );
  }

  void _showImportPasteDialog(BuildContext context) {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Text("Paste & Import Screen Layout JSON", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14)),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Paste your custom ComponentNode JSON structure below:",
                style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TextField(
                    controller: pasteController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      fillColor: Colors.black,
                      filled: true,
                      hintText: '{\n  "id": "root-scaffold",\n  "type": "Column",\n  ...\n}',
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
            onPressed: () {
              final success = widget.onApply(pasteController.text);
              if (success) {
                _controller.text = pasteController.text;
                setState(() => _error = null);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("JSON Screen Layout imported successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to parse JSON schema. Verify standard keys."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Import Layout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RevoJsonTab — Wrapper widget for use in the JSON tab of the property panel.
// ─────────────────────────────────────────────────────────────────────────────

class RevoJsonTab extends ConsumerWidget {
  final VisualBuilderController controller;

  const RevoJsonTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: InteractiveJsonEditor(
        initialJson: controller.exportToJson(),
        onApply: (jsonVal) => controller.importFromJson(jsonVal),
      ),
    );
  }
}
