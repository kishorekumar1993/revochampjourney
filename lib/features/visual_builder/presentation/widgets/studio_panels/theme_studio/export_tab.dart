import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';
import '../../../../application/theme_generator_service.dart';

class ExportTab extends ConsumerStatefulWidget {
  final ThemeTokens tk;
  final ThemeEditorNotifier n;

  const ExportTab({
    super.key,
    required this.tk,
    required this.n,
  });

  @override
  ConsumerState<ExportTab> createState() => _State();
}

class _State extends ConsumerState<ExportTab> {
  final _versionCtrl = TextEditingController();
  int _activeFileIndex = 0;

  @override
  void dispose() {
    _versionCtrl.dispose();
    super.dispose();
  }

  Widget _sec(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: RevoTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: RevoTheme.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Container(height: 1, width: 40, color: RevoTheme.cardBorder),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        alignment: Alignment.center,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ─── Direct Saving/Loading Workspace Utilities ───────────────────────────────

  void _saveThemeToProject(ThemeTokens tk) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Save-to-Project is not supported on Web. Please Export JSON or Download ZIP package instead.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      final json = const JsonEncoder.withIndent('  ').convert(tk.toJson());
      final directory = Directory('lib/core/theme');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('lib/core/theme/revo_theme.json');
      await file.writeAsString(json);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Theme saved directly in project: ${file.path}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save to project: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _setThemeAsDefault(ThemeTokens tk) async {
    widget.n.updateTheme(tk.copyWith(themeName: '${tk.themeName} (Default)'));
    _saveThemeToProject(tk);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Theme set as active default configuration!'),
      backgroundColor: Colors.blue,
    ));
  }

  void _exportJsonFile(ThemeTokens tk) async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(tk.toJson());
      final output = await FilePicker.saveFile(
        dialogTitle: 'Save Theme JSON File',
        fileName: 'theme_${tk.themeName.toLowerCase().replaceAll(' ', '_')}.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (output != null) {
        final file = File(output);
        await file.writeAsString(json);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme JSON saved successfully!')));
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(tk.toJson())));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Save dialog failed. Theme JSON copied to Clipboard instead.'),
        duration: Duration(seconds: 3),
      ));
    }
  }

  void _importJsonFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        widget.n.updateTheme(ThemeTokens.fromJson(json));
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Theme JSON imported successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to import JSON: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _downloadThemePackage(ThemeTokens tk) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Direct file generation not supported on Web. Please Download ZIP package instead.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      final directory = Directory('lib/core/theme');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await File('${directory.path}/app_colors.dart').writeAsString(ThemeGeneratorService.generateAppColors(tk));
      await File('${directory.path}/app_typography.dart').writeAsString(ThemeGeneratorService.generateAppTypography(tk));
      await File('${directory.path}/app_spacing.dart').writeAsString(ThemeGeneratorService.generateAppSpacing(tk));
      await File('${directory.path}/app_dimensions.dart').writeAsString(ThemeGeneratorService.generateAppDimensions(tk));
      await File('${directory.path}/app_elevation.dart').writeAsString(ThemeGeneratorService.generateAppElevation(tk));
      await File('${directory.path}/app_breakpoints.dart').writeAsString(ThemeGeneratorService.generateAppBreakpoints(tk));
      await File('${directory.path}/app_animations.dart').writeAsString(ThemeGeneratorService.generateAppAnimations(tk));
      await File('${directory.path}/app_icons.dart').writeAsString(ThemeGeneratorService.generateAppIcons(tk));
      await File('${directory.path}/component_themes.dart').writeAsString(ThemeGeneratorService.generateComponentThemes(tk));
      await File('${directory.path}/theme_extensions.dart').writeAsString(ThemeGeneratorService.generateThemeExtensions(tk));
      await File('${directory.path}/app_theme.dart').writeAsString(ThemeGeneratorService.generateAppTheme(tk));
      await File('${directory.path}/app_tokens.dart').writeAsString(ThemeGeneratorService.generateAppTokens(tk));
      await File('${directory.path}/theme_metadata.dart').writeAsString(ThemeGeneratorService.generateThemeMetadata(tk));
      await File('${directory.path}/theme.json').writeAsString(ThemeGeneratorService.generateThemeJson(tk));
      await File('${directory.path}/README.md').writeAsString(ThemeGeneratorService.generateReadme(tk));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Theme package files generated inside project directory: ${directory.path}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to generate local package files: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ─── Zip Archiving Exporter ──────────────────────────────────────────────────

  void _downloadZipPackage(ThemeTokens tk) async {
    try {
      final archive = Archive();
      final codes = ThemeGeneratorService.generateThemePackage(tk);

      codes.forEach((filename, content) {
        final bytes = utf8.encode(content);
        archive.addFile(ArchiveFile('theme/$filename', bytes.length, bytes));
      });

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        throw Exception("Failed to encode ZIP archive");
      }

      final output = await FilePicker.saveFile(
        dialogTitle: 'Download Theme ZIP Package',
        fileName: 'theme_package.zip',
        bytes: Uint8List.fromList(zipBytes),
      );

      if (output != null && !kIsWeb) {
        final file = File(output);
        await file.writeAsBytes(zipBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Theme ZIP package saved successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ZIP package downloaded successfully.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to export ZIP package: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
  }

  Widget _versionTile(ThemeVersion v, ThemeVersionsNotifier vn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: RevoTheme.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: RevoTheme.cardBorder)),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: _hex(v.tokens.primaryColor), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RevoTheme.textPrimary)),
            Text(_fmtDate(v.savedAt), style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
          ]),
        ),
        GestureDetector(onTap: () => widget.n.updateTheme(v.tokens), child: Icon(Icons.restore_rounded, size: 18, color: RevoTheme.primary)),
        const SizedBox(width: 8),
        GestureDetector(onTap: () => vn.deleteVersion(v.id), child: Icon(Icons.delete_outline_rounded, size: 18, color: RevoTheme.error)),
      ]),
    );
  }

  Widget _multiFileGeneratorPreview(ThemeTokens tk) {
    final files = [
      'app_colors.dart',
      'app_typography.dart',
      'app_spacing.dart',
      'app_dimensions.dart',
      'app_elevation.dart',
      'app_breakpoints.dart',
      'app_animations.dart',
      'app_icons.dart',
      'component_themes.dart',
      'theme_extensions.dart',
      'app_theme.dart',
      'app_tokens.dart',
      'theme_metadata.dart',
      'theme.json',
      'README.md',
    ];

    final code = [
      ThemeGeneratorService.generateAppColors(tk),
      ThemeGeneratorService.generateAppTypography(tk),
      ThemeGeneratorService.generateAppSpacing(tk),
      ThemeGeneratorService.generateAppDimensions(tk),
      ThemeGeneratorService.generateAppElevation(tk),
      ThemeGeneratorService.generateAppBreakpoints(tk),
      ThemeGeneratorService.generateAppAnimations(tk),
      ThemeGeneratorService.generateAppIcons(tk),
      ThemeGeneratorService.generateComponentThemes(tk),
      ThemeGeneratorService.generateThemeExtensions(tk),
      ThemeGeneratorService.generateAppTheme(tk),
      ThemeGeneratorService.generateAppTokens(tk),
      ThemeGeneratorService.generateThemeMetadata(tk),
      ThemeGeneratorService.generateThemeJson(tk),
      ThemeGeneratorService.generateReadme(tk),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(files.length, (idx) {
                final isSel = _activeFileIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _activeFileIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: isSel ? const Color(0xFF1E293B) : Colors.black,
                    child: Text(
                      files[idx],
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 10,
                        color: isSel ? Colors.greenAccent : Colors.grey,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Container(
            height: 250,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Text(
                code[_activeFileIndex],
                style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code[_activeFileIndex]));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                  label: const Text('Copy File', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _downloadZipPackage(tk),
                  icon: const Icon(Icons.archive_outlined, size: 12, color: Colors.white),
                  label: const Text('Download ZIP', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final versions = ref.watch(themeVersionsProvider);
    final vn = ref.read(themeVersionsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Theme Actions', Icons.save_rounded),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.save_as_rounded, 'Save to Project', Colors.indigo, () => _saveThemeToProject(widget.tk)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Icons.bookmark_added_rounded, 'Set As Default', Colors.blue, () => _setThemeAsDefault(widget.tk)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.file_download_outlined, 'Export JSON', Colors.teal, () => _exportJsonFile(widget.tk)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Icons.file_upload_outlined, 'Import JSON', Colors.orange, _importJsonFile),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.code_rounded, 'Generate Files in Project', Colors.deepOrange, () => _downloadThemePackage(widget.tk)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Icons.archive_rounded, 'Export Theme ZIP', const Color(0xFF6750A4), () => _downloadZipPackage(widget.tk)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sec('Theme Versions', Icons.history_rounded),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _versionCtrl,
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Version name…',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final name = _versionCtrl.text.trim();
              if (name.isEmpty) return;
              vn.saveVersion(name, widget.tk);
              _versionCtrl.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: RevoTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), minimumSize: Size.zero),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
        if (versions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...versions.map((v) => _versionTile(v, vn)),
        ],
        const SizedBox(height: 16),
        _sec('Theme Package Code Generator', Icons.code_rounded),
        const SizedBox(height: 8),
        _multiFileGeneratorPreview(widget.tk),
      ],
    );
  }
}
