import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../../../codegenerator/filegegnerator/revochamp_bloc_generator.dart' as bloc_gen;
import '../../../../codegenerator/generators/bloc/runtime/download.dart';

class RevoCodePreviewPanel extends ConsumerStatefulWidget {
  const RevoCodePreviewPanel({super.key});

  @override
  ConsumerState<RevoCodePreviewPanel> createState() => _RevoCodePreviewPanelState();
}

class _RevoCodePreviewPanelState extends ConsumerState<RevoCodePreviewPanel> {
  bool _blocSelected = true;
  bool _getxSelected = true;
  bool _riverpodSelected = true;
  String _selectedLayout = 'split';

  bool _isGenerating = false;
  List<Map<String, String>> _generatedFiles = [];
  Map<String, String>? _selectedFile;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _triggerCodeGeneration());
  }

  Future<void> _triggerCodeGeneration() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final journeyConfig = ref.read(journeyConfigProvider);
      final architectures = {
        if (_blocSelected) bloc_gen.Architecture.bloc,
        if (_getxSelected) bloc_gen.Architecture.getx,
        if (_riverpodSelected) bloc_gen.Architecture.riverpod,
      };

      final files = await bloc_gen.generateAllFilesDataIsolate(
        journeyConfig: journeyConfig,
        architectures: architectures,
        layoutStyle: _selectedLayout,
      );

      setState(() {
        _generatedFiles = files;
        _isGenerating = false;
        if (files.isNotEmpty) {
          // Keep selection if it still exists, else pick first
          final prevPath = _selectedFile != null ? '${_selectedFile!['folderPath']}/${_selectedFile!['fileName']}' : '';
          final match = files.firstWhere(
            (f) => '${f['folderPath']}/${f['fileName']}' == prevPath,
            orElse: () => files.first,
          );
          _selectedFile = match;
        } else {
          _selectedFile = null;
        }
      });
    } catch (e, stack) {
      debugPrint("Failed to generate code in preview panel: $e\n$stack");
      setState(() {
        _isGenerating = false;
        _generatedFiles = [];
        _selectedFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Generation failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _downloadCode() {
    if (_generatedFiles.isEmpty) return;
    try {
      downloadGeneratedFiles(_generatedFiles, context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Code generation started — select your project folder!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(color: RevoTheme.textPrimary);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Column(
        children: [
          // 1. Control Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: RevoTheme.sidebarBackground,
              border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Architectures Selector
                Row(
                  children: [
                    Text("Architectures:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary)),
                    const SizedBox(width: 12),
                    _buildArchCheckbox("BLoC", _blocSelected, (val) {
                      setState(() => _blocSelected = val ?? false);
                      _triggerCodeGeneration();
                    }),
                    _buildArchCheckbox("GetX", _getxSelected, (val) {
                      setState(() => _getxSelected = val ?? false);
                      _triggerCodeGeneration();
                    }),
                    _buildArchCheckbox("Riverpod", _riverpodSelected, (val) {
                      setState(() => _riverpodSelected = val ?? false);
                      _triggerCodeGeneration();
                    }),
                  ],
                ),

                // Layout Dropdown & Regenerate / Download Buttons
                Row(
                  children: [
                    Text("GetX Layout:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: RevoTheme.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RevoTheme.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLayout,
                          dropdownColor: RevoTheme.cardBg,
                          style: GoogleFonts.inter(color: RevoTheme.textPrimary, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'split', child: Text('Split Screen')),
                            DropdownMenuItem(value: 'focus', child: Text('Conversational')),
                            DropdownMenuItem(value: 'timeline', child: Text('Timeline')),
                            DropdownMenuItem(value: 'tabbed', child: Text('Tabbed Sidebar')),
                            DropdownMenuItem(value: 'carousel', child: Text('Carousel Slider')),
                            DropdownMenuItem(value: 'masterdetail', child: Text('Master Detail')),
                            DropdownMenuItem(value: 'accordion', child: Text('Accordion')),
                            DropdownMenuItem(value: 'form', child: Text('Simple Form')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLayout = val);
                              _triggerCodeGeneration();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isGenerating || _generatedFiles.isEmpty ? null : _downloadCode,
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: Text("Save Code Files", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B4FCF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Main split body or loader
          Expanded(
            child: _isGenerating
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF5B4FCF)),
                        const SizedBox(height: 16),
                        Text(
                          "Generating clean code patterns...",
                          style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _generatedFiles.isEmpty
                    ? Center(
                        child: Text(
                          "No code generated. Please configure fields or select at least one architecture.",
                          style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                        ),
                      )
                    : Row(
                        children: [
                          // Left Side File Explorer Sidebar
                          Container(
                            width: 280,
decoration: BoxDecoration(                            color: RevoTheme.sidebarBackground,
                            border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
),
                            child: ListView.builder(
                              itemCount: _generatedFiles.length,
                              itemBuilder: (context, index) {
                                final file = _generatedFiles[index];
                                final filePath = file['folderPath'] ?? '';
                                final fileName = file['fileName'] ?? '';
                                final fullPath = '$filePath/$fileName';
                                final isSelected = _selectedFile == file;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedFile = file;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0x0C5B4FCF) : Colors.transparent,
                                      border: Border(
                                        left: BorderSide(
                                          color: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file_outlined,
                                          size: 14,
                                          color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                filePath,
                                                style: GoogleFonts.sourceCodePro(
                                                  fontSize: 9,
                                                  color: RevoTheme.textSecondary.withOpacity(0.7),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Right Side Code Viewer
                          Expanded(
                            child: Container(
                              color: const Color(0xFF0C0C12),
                              child: _selectedFile == null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      children: [
                                        // Code header toolbar
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          color: const Color(0xFF14141E),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${_selectedFile!['folderPath']}/${_selectedFile!['fileName']}',
                                                  style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.grey[400]),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  final content = _selectedFile!['textContent'] ?? '';
                                                  Clipboard.setData(ClipboardData(text: content));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Copied to clipboard!"), duration: Duration(seconds: 1)),
                                                  );
                                                },
                                                icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF5B4FCF)),
                                                label: Text("Copy", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5B4FCF))),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Source code body
                                        Expanded(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.all(16),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: SelectableText(
                                                _selectedFile!['textContent'] ?? '',
                                                style: GoogleFonts.sourceCodePro(
                                                  fontSize: 12,
                                                  color: const Color(0xFFA9B1D6),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF5B4FCF),
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary)),
        ],
      ),
    );
  }
}
