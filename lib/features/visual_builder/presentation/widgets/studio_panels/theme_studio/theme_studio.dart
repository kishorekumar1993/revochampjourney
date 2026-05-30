import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';
import '../studio_panel_wrapper.dart';
import 'marketplace_tab.dart';
import 'colors_tab.dart';
import 'typography_tab.dart';
import 'components_tab.dart';
import 'analytics_tab.dart';
import 'export_tab.dart';

class RevoThemeStudioPanel extends ConsumerStatefulWidget {
  const RevoThemeStudioPanel({super.key});

  @override
  ConsumerState<RevoThemeStudioPanel> createState() => _State();
}

class _State extends ConsumerState<RevoThemeStudioPanel> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
  }

  Widget _dot(String hex) => Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: _hex(hex),
          shape: BoxShape.circle,
          border: Border.all(color: RevoTheme.cardBorder, width: 1),
        ),
      );

  Widget _badge(String val, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: RevoTheme.cardBg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(text: '$val ', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primary)),
            if (label.isNotEmpty)
              TextSpan(text: label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
          ]),
        ),
      );

  Widget _dashboard(ThemeTokens tk) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RevoTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RevoTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tk.themeName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      'v${tk.themeVersion}${tk.themeAuthor.isNotEmpty ? " · ${tk.themeAuthor}" : ""}',
                      style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              _dot(tk.primaryColor), const SizedBox(width: 4), _dot(tk.secondaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: [
              _badge('20', 'Components'),
              _badge(tk.fontFamily, 'Font'),
              _badge('${tk.borderRadius.toInt()}px', 'Radius'),
              _badge(tk.isDarkMode ? '🌙 Dark' : '☀ Light', ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _undoRedoBar(ThemeEditorState es, ThemeEditorNotifier n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.undo_rounded, 'Undo', es.canUndo, () => n.undo()),
          const SizedBox(width: 12),
          _iconBtn(Icons.redo_rounded, 'Redo', es.canRedo, () => n.redo()),
          const Spacer(),
          GestureDetector(
            onTap: () => n.updateTheme(const ThemeTokens()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: Text('Reset Default', style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, bool enabled, VoidCallback onTap) {
    final c = enabled ? RevoTheme.primary : RevoTheme.textSecondary.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(themeTokensProvider);
    final tk = es.tokens;
    final n = ref.read(themeTokensProvider.notifier);

    return RevoStudioPanelWrapper(
      title: 'Theme Studio',
      subtitle: 'Enterprise Design System Builder',
      child: Column(
        children: [
          _dashboard(tk),
          _undoRedoBar(es, n),
          Container(
            color: RevoTheme.sidebarBackground,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
              labelColor: RevoTheme.primary,
              unselectedLabelColor: RevoTheme.textSecondary,
              indicatorColor: RevoTheme.primary,
              indicatorWeight: 2,
              dividerColor: RevoTheme.cardBorder,
              tabs: const [
                Tab(text: 'Marketplace'),
                Tab(text: 'Colors'),
                Tab(text: 'Typography'),
                Tab(text: 'Components'),
                Tab(text: 'Analytics'),
                Tab(text: 'Export'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                MarketplaceTab(tokens: tk),
                ColorsTab(tk: tk, n: n),
                TypographyTab(tk: tk, n: n),
                ComponentsTab(tk: tk, n: n),
                AnalyticsTab(tk: tk),
                ExportTab(tk: tk, n: n),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
