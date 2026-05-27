import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

class CodePreviewDialog extends StatefulWidget {
  final List<Map<String, String>> files;
  
  const CodePreviewDialog({super.key, required this.files});

  @override
  State<CodePreviewDialog> createState() => _CodePreviewDialogState();
}

class _CodePreviewDialogState extends State<CodePreviewDialog> {
  String? _selectedFile;

  @override
  void initState() {
    super.initState();
    if (widget.files.isNotEmpty) {
      _selectedFile = '${widget.files.first['folderPath']}/${widget.files.first['fileName']}';
    }
  }

  Map<String, List<Map<String, String>>> _groupFilesByFolder() {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var file in widget.files) {
      final folder = file['folderPath'] ?? 'lib';
      if (!grouped.containsKey(folder)) {
        grouped[folder] = [];
      }
      grouped[folder]!.add(file);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedFiles = _groupFilesByFolder();
    final selectedFileData = widget.files.firstWhere(
      (f) => '${f['folderPath']}/${f['fileName']}' == _selectedFile,
      orElse: () => widget.files.first,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: RevoTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: RevoTheme.sidebarBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_rounded, color: RevoTheme.primaryLight),
                      const SizedBox(width: 12),
                      Text(
                        "Code Preview",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RevoTheme.primary.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: RevoTheme.primary.withValues(alpha:0.3)),
                        ),
                        child: Text(
                          "${widget.files.length} Files Generated",
                          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: RevoTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Dual Pane Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: File Tree
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: RevoTheme.sidebarBackground.withValues(alpha:0.5),
                      border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: groupedFiles.length,
                      itemBuilder: (context, index) {
                        final folder = groupedFiles.keys.elementAt(index);
                        final filesInFolder = groupedFiles[folder]!;
                        return ExpansionTile(
                          initiallyExpanded: true,
                          iconColor: RevoTheme.textSecondary,
                          collapsedIconColor: RevoTheme.textSecondary,
                          title: Text(
                            folder,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RevoTheme.textPrimary,
                            ),
                          ),
                          children: filesInFolder.map((file) {
                            final fullPath = '${file['folderPath']}/${file['fileName']}';
                            final isSelected = _selectedFile == fullPath;
                            return Container(
                              color: isSelected ? RevoTheme.primary.withValues(alpha:0.1) : Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                leading: Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 16,
                                  color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                                ),
                                title: Text(
                                  file['fileName'] ?? '',
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 12,
                                    color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedFile = fullPath;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  
                  // Right Pane: Code Viewer
                  Expanded(
                    child: Container(
                      color: const Color(0xFF1E1E1E), // Darker IDE-like background
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File path header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: const Color(0xFF252526),
                            child: Row(
                              children: [
                                Icon(Icons.description_outlined, size: 16, color: RevoTheme.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedFile ?? '',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 13,
                                      color: RevoTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Code area
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                selectedFileData['textContent'] ?? '',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: const Color(0xFFD4D4D4), // VSCode-like text color
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
      ),
    );
  }
}
