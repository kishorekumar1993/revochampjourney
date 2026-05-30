import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme.dart';
import '../../../application/studio_providers.dart';
import 'studio_panel_wrapper.dart';

// ─── Marketplace Presets ──────────────────────────────────────────────────────

class ThemePreset {
  final String id;
  final String name;
  final String category;
  final String description;
  final ThemeTokens tokens;
  const ThemePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.tokens,
  });
}

const _presets = <ThemePreset>[
  ThemePreset(
    id: 'banking',
    name: 'Royal Trust',
    category: 'Banking',
    description: 'Corporate navy with emerald accents for secure financial portals.',
    tokens: ThemeTokens(
      themeName: 'Royal Trust',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#0F172A',
      secondaryColor: '#10B981',
      backgroundColor: '#F8FAFC',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#0F172A',
      textSecondaryColor: '#475569',
      borderRadius: 4.0,
      buttonStyle: 'elevated',
      inputStyle: 'outline',
      dialogStyle: 'elevated',
      drawerStyle: 'standard',
      bottomSheetStyle: 'flat',
      tabBarStyle: 'pill',
      navigationBarStyle: 'standard',
      listTileStyle: 'card',
      tableStyle: 'bordered',
      stepperStyle: 'standard',
      snackbarStyle: 'floating',
    ),
  ),
  ThemePreset(
    id: 'insurance',
    name: 'Secure Guard',
    category: 'Insurance',
    description: 'Trustworthy royal blue paired with cyan sky highlights.',
    tokens: ThemeTokens(
      themeName: 'Secure Guard',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#1E40AF',
      secondaryColor: '#0EA5E9',
      backgroundColor: '#F3F4F6',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#111827',
      textSecondaryColor: '#4B5563',
      borderRadius: 8.0,
      buttonStyle: 'elevated',
      inputStyle: 'outline',
      dialogStyle: 'outlined',
      drawerStyle: 'modern',
      bottomSheetStyle: 'glass',
      tabBarStyle: 'underlined',
      navigationBarStyle: 'floating',
      listTileStyle: 'flat',
      tableStyle: 'striped',
      stepperStyle: 'timeline',
      snackbarStyle: 'left-accent',
    ),
  ),
  ThemePreset(
    id: 'crm',
    name: 'DealFlow CRM',
    category: 'CRM',
    description: 'Sleek dark slate workspace with energetic mint accents.',
    tokens: ThemeTokens(
      themeName: 'DealFlow CRM',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#0F172A',
      secondaryColor: '#10B981',
      backgroundColor: '#F1F5F9',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#0F172A',
      textSecondaryColor: '#64748B',
      borderRadius: 10.0,
      buttonStyle: 'tonal',
      inputStyle: 'filled',
      dialogStyle: 'flat',
      drawerStyle: 'modern',
      bottomSheetStyle: 'elevated',
      tabBarStyle: 'pill',
      navigationBarStyle: 'minimal',
      listTileStyle: 'bordered',
      tableStyle: 'simple',
      stepperStyle: 'dots',
      snackbarStyle: 'toast',
    ),
  ),
  ThemePreset(
    id: 'hrms',
    name: 'Pulse People',
    category: 'HRMS',
    description: 'Playful deep indigo and electric magenta for HR portals.',
    tokens: ThemeTokens(
      themeName: 'Pulse People',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#4F46E5',
      secondaryColor: '#EC4899',
      backgroundColor: '#FAF5FF',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#1E1B4B',
      textSecondaryColor: '#581C87',
      borderRadius: 12.0,
      buttonStyle: 'elevated',
      inputStyle: 'outline',
      dialogStyle: 'elevated',
      drawerStyle: 'floating',
      bottomSheetStyle: 'flat',
      tabBarStyle: 'standard',
      navigationBarStyle: 'standard',
      listTileStyle: 'card',
      tableStyle: 'striped',
      stepperStyle: 'standard',
      snackbarStyle: 'floating',
    ),
  ),
  ThemePreset(
    id: 'healthcare',
    name: 'Care Connect',
    category: 'Healthcare',
    description: 'Calming mint green and active cyan for clinical systems.',
    tokens: ThemeTokens(
      themeName: 'Care Connect',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#0D9488',
      secondaryColor: '#14B8A6',
      backgroundColor: '#F0FDFA',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#115E59',
      textSecondaryColor: '#0F766E',
      borderRadius: 16.0,
      buttonStyle: 'flat',
      inputStyle: 'underline',
      dialogStyle: 'glass',
      drawerStyle: 'modern',
      bottomSheetStyle: 'glass',
      tabBarStyle: 'underlined',
      navigationBarStyle: 'minimal',
      listTileStyle: 'flat',
      tableStyle: 'simple',
      stepperStyle: 'timeline',
      snackbarStyle: 'top-float',
    ),
  ),
  ThemePreset(
    id: 'business',
    name: 'Enterprise Hub',
    category: 'Business',
    description: 'Professional royal blue and modern steel grey.',
    tokens: ThemeTokens(
      themeName: 'Enterprise Hub',
      themeVersion: '1.0.0',
      themeAuthor: 'Revochamp',
      primaryColor: '#2563EB',
      secondaryColor: '#475569',
      backgroundColor: '#F8FAFC',
      cardColor: '#FFFFFF',
      textPrimaryColor: '#0F172A',
      textSecondaryColor: '#475569',
      borderRadius: 6.0,
      buttonStyle: 'outlined',
      inputStyle: 'outline',
      dialogStyle: 'outlined',
      drawerStyle: 'standard',
      bottomSheetStyle: 'flat',
      tabBarStyle: 'standard',
      navigationBarStyle: 'standard',
      listTileStyle: 'bordered',
      tableStyle: 'bordered',
      stepperStyle: 'standard',
      snackbarStyle: 'standard',
    ),
  ),
];

// ─── Panel ────────────────────────────────────────────────────────────────────

class RevoThemeStudioPanel extends ConsumerStatefulWidget {
  const RevoThemeStudioPanel({super.key});

  @override
  ConsumerState<RevoThemeStudioPanel> createState() => _State();
}

class _State extends ConsumerState<RevoThemeStudioPanel> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _compareId;
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();
  final _aiPromptCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  bool _isGeneratingAi = false;
  int _activeFileIndex = 0; // For code generator multi-file switcher

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _aiPromptCtrl.dispose();
    _versionCtrl.dispose();
    super.dispose();
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
                _marketplaceTab(tk, n),
                _colorsTab(tk, n),
                _typographyTab(tk, n),
                _componentsTab(tk, n),
                _analyticsTab(tk),
                _exportTab(tk, n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dashboard ─────────────────────────────────────────────────────────────

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
              _badge('14', 'Components'),
              _badge(tk.fontFamily, 'Font'),
              _badge('${tk.borderRadius.toInt()}px', 'Radius'),
              _badge(tk.isDarkMode ? '🌙 Dark' : '☀ Light', ''),
            ],
          ),
        ],
      ),
    );
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

  // ─── Undo/Redo ─────────────────────────────────────────────────────────────

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

  // ─── Marketplace Tab ───────────────────────────────────────────────────────

  Widget _marketplaceTab(ThemeTokens tk, ThemeEditorNotifier n) {
    final search = _searchCtrl.text.toLowerCase();
    final filtered = _presets.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(search) ||
          p.category.toLowerCase().contains(search) ||
          p.description.toLowerCase().contains(search);
      return matchesCat && matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search marketplace themes...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Banking', 'Insurance', 'CRM', 'HRMS', 'Healthcare', 'Business'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : RevoTheme.textPrimary)),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: RevoTheme.primary,
                        backgroundColor: RevoTheme.cardBg,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No themes found matching criteria.',
                        style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
                  ),
                ),
              ...filtered.map((preset) => _presetCard(preset, tk, n)),
              if (_compareId != null) ...[
                const SizedBox(height: 20),
                _sec('Visual Diff Comparison', Icons.compare_arrows_rounded),
                const SizedBox(height: 8),
                _compareView(tk, _presets.firstWhere((p) => p.id == _compareId)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetCard(ThemePreset p, ThemeTokens current, ThemeEditorNotifier n) {
    final isCompared = _compareId == p.id;
    final pri = _hex(p.tokens.primaryColor);
    final sec = _hex(p.tokens.secondaryColor);
    final bg = _hex(p.tokens.backgroundColor);
    final cardColor = _hex(p.tokens.cardColor);
    final text = _hex(p.tokens.textPrimaryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCompared ? RevoTheme.primary : RevoTheme.cardBorder, width: isCompared ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Theme Mock Preview
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Mini AppBar
                    Container(
                      height: 24,
                      color: pri,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Container(width: 25, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                          const Spacer(),
                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mini Side Drawer/Rail
                            Container(
                              width: 14,
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(3, (_) => Container(width: 6, height: 2, color: pri.withValues(alpha: 0.4))),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Mini Card and Buttons
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(p.tokens.borderRadius / 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2)],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(width: 30, height: 3, color: text),
                                        Container(width: 20, height: 2, color: text.withValues(alpha: 0.5)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 34, height: 10,
                                        decoration: BoxDecoration(color: pri, borderRadius: BorderRadius.circular(2)),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 25, height: 10,
                                        decoration: BoxDecoration(border: Border.all(color: sec, width: 0.5), borderRadius: BorderRadius.circular(2)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Category Badge
                Positioned(
                  top: 30,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pri.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.category, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: pri)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Info Block
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(p.description, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          n.updateTheme(p.tokens);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Applied ${p.name} theme successfully.'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RevoTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('Apply Theme', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _compareId = isCompared ? null : p.id;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        side: BorderSide(color: isCompared ? RevoTheme.primary : RevoTheme.cardBorder),
                      ),
                      child: Icon(
                        isCompared ? Icons.compare_arrows : Icons.compare_outlined,
                        size: 15,
                        color: isCompared ? RevoTheme.primary : RevoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Colors Tab ────────────────────────────────────────────────────────────

  Widget _colorsTab(ThemeTokens tk, ThemeEditorNotifier n) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('AI Theme Prompt Generator', Icons.psychology_rounded),
        const SizedBox(height: 8),
        _aiGeneratorCard(tk, n),
        const SizedBox(height: 16),
        _modeSwitcher(tk, n),
        const SizedBox(height: 12),
        _sec('Brand Colors', Icons.palette_rounded),
        const SizedBox(height: 6),
        _colorRow('Primary', tk.primaryColor, (v) => n.updateTheme(tk.copyWith(primaryColor: v))),
        _colorRow('Secondary', tk.secondaryColor, (v) => n.updateTheme(tk.copyWith(secondaryColor: v))),
        _colorRow('Background', tk.backgroundColor, (v) => n.updateTheme(tk.copyWith(backgroundColor: v))),
        _colorRow('Card BG', tk.cardColor, (v) => n.updateTheme(tk.copyWith(cardColor: v))),
        _colorRow('Text Primary', tk.textPrimaryColor, (v) => n.updateTheme(tk.copyWith(textPrimaryColor: v))),
        _colorRow('Text Secondary', tk.textSecondaryColor, (v) => n.updateTheme(tk.copyWith(textSecondaryColor: v))),
        _colorRow('Error Alert', tk.errorColor, (v) => n.updateTheme(tk.copyWith(errorColor: v))),
        _colorRow('Success Alert', tk.successColor, (v) => n.updateTheme(tk.copyWith(successColor: v))),
        _colorRow('Warning Alert', tk.warningColor, (v) => n.updateTheme(tk.copyWith(warningColor: v))),
        const SizedBox(height: 12),
        _sec('Gradient Studio', Icons.gradient_rounded),
        const SizedBox(height: 6),
        _colorRow('Start Color', tk.gradientStartColor.isEmpty ? '#5B4FCF' : tk.gradientStartColor,
            (v) => n.updateTheme(tk.copyWith(gradientStartColor: v))),
        _colorRow('End Color', tk.gradientEndColor.isEmpty ? '#9E95F5' : tk.gradientEndColor,
            (v) => n.updateTheme(tk.copyWith(gradientEndColor: v))),
        if (tk.gradientStartColor.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: () => n.updateTheme(tk.copyWith(gradientStartColor: '', gradientEndColor: '')),
              icon: const Icon(Icons.clear, size: 12),
              label: const Text('Clear Gradient', style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _aiGeneratorCard(ThemeTokens tk, ThemeEditorNotifier n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Describe the interface vibe:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _aiPromptCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 11),
            decoration: InputDecoration(
              hintText: 'e.g. Create a modern Insurance CRM theme with dark mode...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isGeneratingAi ? null : () => _runAiThemeGeneration(tk, n),
            icon: _isGeneratingAi
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
            label: Text(
              _isGeneratingAi ? 'Analyzing & generating...' : 'Generate Theme',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4FCF),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  void _runAiThemeGeneration(ThemeTokens tk, ThemeEditorNotifier n) async {
    final prompt = _aiPromptCtrl.text.toLowerCase().trim();
    if (prompt.isEmpty) return;

    setState(() => _isGeneratingAi = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // Dynamic feel

    // Local heuristic engine mapping colors
    bool isDark = prompt.contains('dark') || prompt.contains('black') || prompt.contains('night');
    String primary = '#5B4FCF';
    String secondary = '#9E95F5';
    String bg = isDark ? '#121212' : '#F8FAFC';
    String card = isDark ? '#1E1E1E' : '#FFFFFF';
    String textPri = isDark ? '#FFFFFF' : '#0F172A';
    String textSec = isDark ? '#9CA3AF' : '#475569';
    double radius = 8.0;
    String font = 'Outfit';

    if (prompt.contains('insurance')) {
      primary = '#1E40AF';
      secondary = '#0EA5E9';
      font = 'Inter';
    } else if (prompt.contains('crm') || prompt.contains('sales')) {
      primary = '#4F46E5';
      secondary = '#EC4899';
    } else if (prompt.contains('banking') || prompt.contains('finance') || prompt.contains('wealth')) {
      primary = '#0F172A';
      secondary = '#10B981';
      radius = 4.0;
    } else if (prompt.contains('healthcare') || prompt.contains('medical') || prompt.contains('care')) {
      primary = '#0D9488';
      secondary = '#14B8A6';
      radius = 12.0;
    } else if (prompt.contains('mint') || prompt.contains('forest') || prompt.contains('nature')) {
      primary = '#047857';
      secondary = '#34D399';
      bg = isDark ? '#064E3B' : '#ECFDF5';
    } else if (prompt.contains('neon') || prompt.contains('cyber') || prompt.contains('synthwave')) {
      primary = '#F43F5E';
      secondary = '#D946EF';
      isDark = true;
      bg = '#09090B';
      card = '#18181B';
      textPri = '#FFFFFF';
      textSec = '#A1A1AA';
    } else if (prompt.contains('warm') || prompt.contains('sunset') || prompt.contains('amber')) {
      primary = '#F97316';
      secondary = '#F59E0B';
    }

    if (prompt.contains('rounded') || prompt.contains('soft') || prompt.contains('bubble')) {
      radius = 16.0;
    } else if (prompt.contains('sharp') || prompt.contains('flat') || prompt.contains('grid')) {
      radius = 0.0;
    }

    if (prompt.contains('roboto')) font = 'Roboto';
    if (prompt.contains('poppins')) font = 'Poppins';
    if (prompt.contains('inter')) font = 'Inter';

    final generated = tk.copyWith(
      themeName: 'AI generated Theme',
      isDarkMode: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      backgroundColor: bg,
      cardColor: card,
      textPrimaryColor: textPri,
      textSecondaryColor: textSec,
      borderRadius: radius,
      fontFamily: font,
    );

    n.updateTheme(generated);
    setState(() => _isGeneratingAi = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('AI Theme generated & applied successfully!'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.indigo,
    ));
  }

  Widget _modeSwitcher(ThemeTokens tk, ThemeEditorNotifier n) {
    return Row(
      children: [
        const Icon(Icons.dark_mode_rounded, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text('Dark Theme View', style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary, fontWeight: FontWeight.bold)),
        const Spacer(),
        Switch(
          value: tk.isDarkMode,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (v) => n.updateTheme(tk.copyWith(
            isDarkMode: v,
            backgroundColor: v ? '#121212' : '#F8FAFC',
            cardColor: v ? '#1E1E1E' : '#FFFFFF',
            textPrimaryColor: v ? '#FFFFFF' : '#0F172A',
            textSecondaryColor: v ? '#9CA3AF' : '#475569',
          )),
        ),
      ],
    );
  }

  // ─── Typography Tab ────────────────────────────────────────────────────────

  Widget _typographyTab(ThemeTokens tk, ThemeEditorNotifier n) {
    const fonts = ['Outfit', 'Inter', 'Roboto', 'Poppins', 'Open Sans', 'Lato', 'Montserrat', 'Nunito', 'Raleway', 'DM Sans'];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Font Family', Icons.font_download_rounded),
        const SizedBox(height: 8),
        _dropdown('Font Family', tk.fontFamily, fonts, (v) => n.updateTheme(tk.copyWith(fontFamily: v))),
        const SizedBox(height: 12),
        _sec('Live Font Preview', Icons.text_snippet_rounded),
        const SizedBox(height: 8),
        _liveFontPreview(tk),
        const SizedBox(height: 16),
        _sec('Font Scale Sizes', Icons.text_fields_rounded),
        const SizedBox(height: 4),
        _slider('XS size', tk.fontSizeXs, 8, 16, (v) => n.updateTheme(tk.copyWith(fontSizeXs: v)), 'px'),
        _slider('SM size', tk.fontSizeSm, 10, 18, (v) => n.updateTheme(tk.copyWith(fontSizeSm: v)), 'px'),
        _slider('MD size', tk.fontSizeMd, 12, 22, (v) => n.updateTheme(tk.copyWith(fontSizeMd: v)), 'px'),
        _slider('LG size', tk.fontSizeLg, 14, 32, (v) => n.updateTheme(tk.copyWith(fontSizeLg: v)), 'px'),
        _slider('XL size', tk.fontSizeXl, 18, 48, (v) => n.updateTheme(tk.copyWith(fontSizeXl: v)), 'px'),
        const SizedBox(height: 12),
        _sec('Border Radius Defaults', Icons.rounded_corner_rounded),
        const SizedBox(height: 4),
        _slider('Small (sm)', tk.borderRadiusSm, 0, 16, (v) => n.updateTheme(tk.copyWith(borderRadiusSm: v)), 'px'),
        _slider('Medium (md)', tk.borderRadius, 0, 24, (v) => n.updateTheme(tk.copyWith(borderRadius: v)), 'px'),
        _slider('Large (lg)', tk.borderRadiusLg, 0, 48, (v) => n.updateTheme(tk.copyWith(borderRadiusLg: v)), 'px'),
        const SizedBox(height: 12),
        _sec('Spacing Dimensions', Icons.space_bar_rounded),
        const SizedBox(height: 4),
        _slider('XS gap', tk.spacingXs, 2, 12, (v) => n.updateTheme(tk.copyWith(spacingXs: v)), 'px'),
        _slider('SM gap', tk.spacingSm, 4, 16, (v) => n.updateTheme(tk.copyWith(spacingSm: v)), 'px'),
        _slider('MD gap', tk.spacingUnit, 8, 32, (v) => n.updateTheme(tk.copyWith(spacingUnit: v)), 'px'),
        _slider('LG gap', tk.spacingLg, 16, 48, (v) => n.updateTheme(tk.copyWith(spacingLg: v)), 'px'),
        _slider('XL gap', tk.spacingXl, 24, 64, (v) => n.updateTheme(tk.copyWith(spacingXl: v)), 'px'),
      ],
    );
  }

  Widget _liveFontPreview(ThemeTokens tk) {
    final textCol = _hex(tk.textPrimaryColor);
    final textSecCol = _hex(tk.textSecondaryColor);

    TextStyle fontStyle(double size, {FontWeight weight = FontWeight.normal, Color? color}) {
      try {
        return GoogleFonts.getFont(tk.fontFamily, fontSize: size, fontWeight: weight, color: color);
      } catch (_) {
        return TextStyle(fontFamily: 'sans-serif', fontSize: size, fontWeight: weight, color: color);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hex(tk.backgroundColor),
        borderRadius: BorderRadius.circular(tk.borderRadius),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tk.fontFamily,
                style: fontStyle(tk.fontSizeMd, weight: FontWeight.bold, color: textCol),
              ),
              const Spacer(),
              Text('Live Rendering', style: GoogleFonts.inter(fontSize: 8, color: RevoTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Aa Bb Cc', style: fontStyle(28, color: textCol)),
          const SizedBox(height: 6),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: fontStyle(tk.fontSizeSm, color: textSecCol),
          ),
          const SizedBox(height: 4),
          Text('1234567890', style: fontStyle(tk.fontSizeSm, color: textSecCol)),
        ],
      ),
    );
  }

  // ─── Components Tab ────────────────────────────────────────────────────────

  Widget _componentsTab(ThemeTokens tk, ThemeEditorNotifier n) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Dropdown Styles', Icons.settings_applications),
        const SizedBox(height: 8),
        _dropdown('Button Style', tk.buttonStyle, ['elevated', 'outlined', 'flat', 'tonal'], (v) => n.updateTheme(tk.copyWith(buttonStyle: v))),
        _dropdown('Input Field Style', tk.inputStyle, ['outline', 'filled', 'underline'], (v) => n.updateTheme(tk.copyWith(inputStyle: v))),
        _dropdown('Card Style', tk.cardStyle, ['flat', 'elevated', 'outlined', 'glass'], (v) => n.updateTheme(tk.copyWith(cardStyle: v))),
        _dropdown('AppBar Style', tk.appBarStyle, ['solid', 'transparent', 'gradient', 'glass'], (v) => n.updateTheme(tk.copyWith(appBarStyle: v))),
        _dropdown('Chip Style', tk.chipStyle, ['filled', 'outlined', 'elevated'], (v) => n.updateTheme(tk.copyWith(chipStyle: v))),
        _dropdown('Dialog Style', tk.dialogStyle, ['flat', 'elevated', 'outlined', 'glass'], (v) => n.updateTheme(tk.copyWith(dialogStyle: v))),
        _dropdown('Drawer Style', tk.drawerStyle, ['standard', 'modern', 'floating'], (v) => n.updateTheme(tk.copyWith(drawerStyle: v))),
        _dropdown('BottomSheet Style', tk.bottomSheetStyle, ['flat', 'elevated', 'glass'], (v) => n.updateTheme(tk.copyWith(bottomSheetStyle: v))),
        _dropdown('TabBar Style', tk.tabBarStyle, ['standard', 'pill', 'underlined'], (v) => n.updateTheme(tk.copyWith(tabBarStyle: v))),
        _dropdown('NavigationBar Style', tk.navigationBarStyle, ['standard', 'floating', 'minimal'], (v) => n.updateTheme(tk.copyWith(navigationBarStyle: v))),
        _dropdown('ListTile Style', tk.listTileStyle, ['flat', 'card', 'bordered'], (v) => n.updateTheme(tk.copyWith(listTileStyle: v))),
        _dropdown('Table Style', tk.tableStyle, ['standard', 'striped', 'bordered'], (v) => n.updateTheme(tk.copyWith(tableStyle: v))),
        _dropdown('Stepper Style', tk.stepperStyle, ['standard', 'timeline', 'dots'], (v) => n.updateTheme(tk.copyWith(stepperStyle: v))),
        _dropdown('Snackbar Style', tk.snackbarStyle, ['standard', 'floating', 'left-accent'], (v) => n.updateTheme(tk.copyWith(snackbarStyle: v))),
        const SizedBox(height: 16),
        _sec('Component Previews', Icons.remove_red_eye_outlined),
        const SizedBox(height: 10),
        _componentsPreviewGrid(tk),
      ],
    );
  }

  Widget _componentsPreviewGrid(ThemeTokens tk) {
    final pri = _hex(tk.primaryColor);
    final bg = _hex(tk.backgroundColor);
    final card = _hex(tk.cardColor);
    final text = _hex(tk.textPrimaryColor);
    final textSec = _hex(tk.textSecondaryColor);
    final rad = BorderRadius.circular(tk.borderRadius);

    Widget styleCard(String title, Widget content) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: rad,
          border: Border.all(color: RevoTheme.cardBorder),
          boxShadow: tk.cardStyle == 'elevated'
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: textSec)),
            const SizedBox(height: 8),
            Center(child: content),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: rad,
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          // 1. Button + Input + Chip
          styleCard('Buttons & Input Fields', Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pri,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: rad),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Button', style: TextStyle(fontSize: 10)),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: pri),
                      foregroundColor: pri,
                      shape: RoundedRectangleBorder(borderRadius: rad),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Outlined', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Themed Input',
                  labelStyle: TextStyle(color: textSec, fontSize: 10),
                  filled: tk.inputStyle == 'filled',
                  fillColor: pri.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  border: tk.inputStyle == 'outline'
                      ? OutlineInputBorder(borderRadius: rad)
                      : tk.inputStyle == 'underline'
                          ? const UnderlineInputBorder()
                          : OutlineInputBorder(borderSide: BorderSide.none, borderRadius: rad),
                ),
              ),
            ],
          )),

          // 2. Dialog Preview
          styleCard('Dialog (${tk.dialogStyle})', Container(
            width: 200,
            decoration: BoxDecoration(
              color: card,
              borderRadius: rad,
              border: tk.dialogStyle == 'outlined' ? Border.all(color: pri) : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: tk.dialogStyle == 'elevated'
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dialog Header', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
                const SizedBox(height: 4),
                Text('Dialog details and text description.', style: TextStyle(fontSize: 9, color: textSec)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Cancel', style: TextStyle(fontSize: 9, color: pri, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('OK', style: TextStyle(fontSize: 9, color: pri, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )),

          // 3. Drawer & BottomSheet Previews
          styleCard('Drawer (${tk.drawerStyle}) & BottomSheet (${tk.bottomSheetStyle})', Row(
            children: [
              // Mini Drawer
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: card,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: tk.drawerStyle == 'floating' ? rad : BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    Container(height: 15, color: pri),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (_) => Row(
                          children: [
                            const SizedBox(width: 4),
                            Icon(Icons.circle, size: 4, color: pri),
                            const SizedBox(width: 4),
                            Container(width: 20, height: 2, color: textSec.withValues(alpha: 0.5)),
                          ],
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Mini BottomSheet
              Container(
                width: 90,
                height: 70,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0, left: 2, right: 2,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          boxShadow: tk.bottomSheetStyle == 'elevated'
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                          border: tk.bottomSheetStyle == 'glass' ? Border.all(color: pri.withValues(alpha: 0.3)) : null,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 3),
                            Container(width: 14, height: 2, color: Colors.grey),
                            const Spacer(),
                            Text('Actions sheet', style: TextStyle(fontSize: 8, color: text)),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),

          // 4. TabBar & NavigationBar Previews
          styleCard('TabBar (${tk.tabBarStyle}) & NavigationBar (${tk.navigationBarStyle})', Column(
            children: [
              // TabBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tk.tabBarStyle == 'pill' ? pri : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: tk.tabBarStyle == 'underlined' ? Border(bottom: BorderSide(color: pri, width: 2)) : null,
                    ),
                    child: Text('Active', style: TextStyle(fontSize: 9, color: tk.tabBarStyle == 'pill' ? Colors.white : pri, fontWeight: FontWeight.bold)),
                  ),
                  Text('Inactive', style: TextStyle(fontSize: 9, color: textSec)),
                ],
              ),
              const SizedBox(height: 12),
              // NavigationBar
              Container(
                height: 25,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: tk.navigationBarStyle == 'floating' ? rad : BorderRadius.zero,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.home, size: 12, color: pri),
                    Icon(Icons.search, size: 12, color: textSec),
                    Icon(Icons.person, size: 12, color: textSec),
                  ],
                ),
              ),
            ],
          )),

          // 5. ListTile & Table Previews
          styleCard('ListTile (${tk.listTileStyle}) & Table (${tk.tableStyle})', Column(
            children: [
              // ListTile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tk.listTileStyle == 'card' ? card : Colors.transparent,
                  borderRadius: rad,
                  border: tk.listTileStyle == 'bordered' ? Border.all(color: Colors.grey.withValues(alpha: 0.3)) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: pri, child: const Icon(Icons.person, size: 8, color: Colors.white)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ListTile Title', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text)),
                        Text('Subtitle text', style: TextStyle(fontSize: 7, color: textSec)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 12, color: textSec),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Table
              Table(
                border: tk.tableStyle == 'bordered' ? TableBorder.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5) : const TableBorder(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: pri.withValues(alpha: 0.1)),
                    children: [
                      Padding(padding: const EdgeInsets.all(4), child: Text('Col 1', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text))),
                      Padding(padding: const EdgeInsets.all(4), child: Text('Col 2', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: text))),
                    ],
                  ),
                  TableRow(
                    decoration: BoxDecoration(color: tk.tableStyle == 'striped' ? Colors.grey.withValues(alpha: 0.05) : Colors.transparent),
                    children: [
                      Padding(padding: const EdgeInsets.all(4), child: Text('Val A', style: const TextStyle(fontSize: 8))),
                      Padding(padding: const EdgeInsets.all(4), child: Text('Val B', style: const TextStyle(fontSize: 8))),
                    ],
                  ),
                ],
              ),
            ],
          )),

          // 6. Stepper & Snackbar Previews
          styleCard('Stepper (${tk.stepperStyle}) & Snackbar (${tk.snackbarStyle})', Column(
            children: [
              // Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 6, backgroundColor: pri, child: const Text('1', style: TextStyle(fontSize: 6, color: Colors.white))),
                  Container(width: 25, height: 1.5, color: pri),
                  CircleAvatar(radius: 6, backgroundColor: textSec.withValues(alpha: 0.2), child: Text('2', style: TextStyle(fontSize: 6, color: textSec))),
                ],
              ),
              const SizedBox(height: 10),
              // Snackbar
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: text,
                  borderRadius: tk.snackbarStyle == 'floating' ? rad : BorderRadius.zero,
                  border: tk.snackbarStyle == 'left-accent' ? Border(left: BorderSide(color: pri, width: 3.5)) : null,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('Alert notification text', style: TextStyle(fontSize: 8, color: card))),
                    Text('Undo', style: TextStyle(fontSize: 8, color: pri, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ─── Analytics Tab ─────────────────────────────────────────────────────────

  Widget _analyticsTab(ThemeTokens tk) {
    final bg = _hex(tk.backgroundColor);
    final textCol = _hex(tk.textPrimaryColor);
    final primary = _hex(tk.primaryColor);

    final ratioTextBg = _contrastRatio(textCol, bg);
    final ratioPriBg = _contrastRatio(primary, bg);
    final ratioSecBg = _contrastRatio(_hex(tk.secondaryColor), bg);

    // Calculate score
    double score = 0;
    score += (ratioTextBg / 7.0).clamp(0.0, 1.0) * 50; // max 50 points
    score += (ratioPriBg / 4.5).clamp(0.0, 1.0) * 30;  // max 30 points
    if (tk.isDarkMode) score += 20; // 20 points for dark mode support

    final accessLevelText = _wcag(ratioTextBg);
    final accessLevelPri = _wcag(ratioPriBg);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Accessibility Score', Icons.accessibility_new_rounded),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 90, height: 90,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: RevoTheme.cardBorder,
                      color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${score.toInt()}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
                      Text('/ 100', style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sec('WCAG Contrast Ratios', Icons.contrast),
        const SizedBox(height: 8),
        _a11yRow('Body Text on Scaffold BG', ratioTextBg, accessLevelText),
        const SizedBox(height: 6),
        _a11yRow('Primary Color on Scaffold BG', ratioPriBg, accessLevelPri),
        const SizedBox(height: 6),
        _a11yRow('Secondary Color on Scaffold BG', ratioSecBg, _wcag(ratioSecBg)),
        const SizedBox(height: 16),
        _sec('Theme Audit Checklist', Icons.fact_check_outlined),
        const SizedBox(height: 8),
        _auditRow('Dark Mode variant defined', tk.isDarkMode),
        _auditRow('Readable primary color contrast (>= 3.0:1)', ratioPriBg >= 3.0),
        _auditRow('Readable text contrast (>= 4.5:1)', ratioTextBg >= 4.5),
        _auditRow('Standard layout font family configured', ['Outfit', 'Inter', 'Roboto', 'Poppins'].contains(tk.fontFamily)),
      ],
    );
  }

  Widget _auditRow(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle_rounded : Icons.cancel_outlined,
              size: 14, color: passed ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary))),
        ],
      ),
    );
  }

  // ─── Export Tab ────────────────────────────────────────────────────────────

  Widget _exportTab(ThemeTokens tk, ThemeEditorNotifier n) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Theme Actions', Icons.save_rounded),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.save_as_rounded, 'Save to Project', Colors.indigo, () => _saveThemeToProject(tk)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Icons.bookmark_added_rounded, 'Set As Default', Colors.blue, () => _setThemeAsDefault(tk, n)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.file_download_outlined, 'Export JSON', Colors.teal, () => _exportJsonFile(tk)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(Icons.file_upload_outlined, 'Import JSON', Colors.orange, () => _importJsonFile(n)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sec('Theme Package Code Generator', Icons.code_rounded),
        const SizedBox(height: 8),
        _multiFileGeneratorPreview(tk),
      ],
    );
  }

  Widget _multiFileGeneratorPreview(ThemeTokens tk) {
    final files = [
      'app_colors.dart',
      'app_typography.dart',
      'app_spacing.dart',
      'app_theme.dart',
      'theme_extensions.dart',
    ];

    final code = [
      _genAppColorsCode(tk),
      _genAppTypographyCode(tk),
      _genAppSpacingCode(tk),
      _genAppThemeCode(tk),
      _genThemeExtensionsCode(tk),
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
          // Header tabs switcher
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
          // Code output area
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
          // Actions bar
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
                  onPressed: () => _downloadThemePackage(tk),
                  icon: const Icon(Icons.file_download, size: 12, color: Colors.white),
                  label: const Text('Download Package', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Theme Diff View ───────────────────────────────────────────────────────

  Widget _compareView(ThemeTokens cur, ThemePreset preset) {
    final pre = preset.tokens;
    final curColors = [
      ('Primary', cur.primaryColor, pre.primaryColor),
      ('Secondary', cur.secondaryColor, pre.secondaryColor),
      ('Background', cur.backgroundColor, pre.backgroundColor),
      ('Card BG', cur.cardColor, pre.cardColor),
      ('Text Primary', cur.textPrimaryColor, pre.textPrimaryColor),
    ];
    final curMetrics = [
      ('Font Family', cur.fontFamily, pre.fontFamily),
      ('Border Radius', '${cur.borderRadius.toInt()}px', '${pre.borderRadius.toInt()}px'),
      ('Button Style', cur.buttonStyle, pre.buttonStyle),
      ('Input Style', cur.inputStyle, pre.inputStyle),
      ('Dialog Style', cur.dialogStyle, pre.dialogStyle),
    ];

    // Compute changed count
    int colsChanged = curColors.where((c) => c.$2 != c.$3).length;
    int metricsChanged = curMetrics.where((m) => m.$2 != m.$3).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Current Theme Settings', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary))),
              const Icon(Icons.compare_arrows_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(preset.name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primary), textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...curColors.map((c) => _diffRow(c.$1, c.$2, c.$3, true)),
          ...curMetrics.map((m) => _diffRow(m.$1, m.$2, m.$3, false)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _diffBadge('Colors changed: $colsChanged'),
                _diffBadge('Metrics changed: $metricsChanged'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber[800])),
    );
  }

  Widget _diffRow(String label, String curVal, String targetVal, bool isColor) {
    final isDifferent = curVal.toLowerCase() != targetVal.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
          ),
          Expanded(
            child: Row(
              children: [
                if (isColor) ...[
                  _dot(curVal),
                  const SizedBox(width: 4),
                  Text(curVal, style: GoogleFonts.inter(fontSize: 9, color: isDifferent ? Colors.orange : RevoTheme.textPrimary)),
                ] else
                  Text(curVal, style: GoogleFonts.inter(fontSize: 9, color: isDifferent ? Colors.orange : RevoTheme.textPrimary)),
              ],
            ),
          ),
          Icon(isDifferent ? Icons.arrow_right_alt_rounded : Icons.check_circle_outline, size: 14, color: isDifferent ? Colors.orange : Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isColor) ...[
                  _dot(targetVal),
                  const SizedBox(width: 4),
                  Text(targetVal, style: GoogleFonts.inter(fontSize: 9, color: isDifferent ? RevoTheme.primary : RevoTheme.textPrimary)),
                ] else
                  Text(targetVal, style: GoogleFonts.inter(fontSize: 9, color: isDifferent ? RevoTheme.primary : RevoTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Direct Saving/Loading Workspace Utilities ───────────────────────────────

  void _saveThemeToProject(ThemeTokens tk) async {
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

  void _setThemeAsDefault(ThemeTokens tk, ThemeEditorNotifier n) async {
    n.updateTheme(tk.copyWith(themeName: '${tk.themeName} (Default)'));
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
      // Fallback: Copy to clipboard if Save Dialog fails/unsupported
      Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(tk.toJson())));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Save failed. Theme JSON copied to Clipboard instead.'),
        duration: Duration(seconds: 3),
      ));
    }
  }

  void _importJsonFile(ThemeEditorNotifier n) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        n.updateTheme(ThemeTokens.fromJson(json));
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
    try {
      // Write package files directly into workspace lib/core/theme folder
      final directory = Directory('lib/core/theme');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await File('${directory.path}/app_colors.dart').writeAsString(_genAppColorsCode(tk));
      await File('${directory.path}/app_typography.dart').writeAsString(_genAppTypographyCode(tk));
      await File('${directory.path}/app_spacing.dart').writeAsString(_genAppSpacingCode(tk));
      await File('${directory.path}/app_theme.dart').writeAsString(_genAppThemeCode(tk));
      await File('${directory.path}/theme_extensions.dart').writeAsString(_genThemeExtensionsCode(tk));

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

  // ─── Code Generation Subroutine Scripts ──────────────────────────────────────

  String _genAppColorsCode(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF${tk.primaryColor.replaceAll('#', '')});
  static const secondary = Color(0xFF${tk.secondaryColor.replaceAll('#', '')});
  static const background = Color(0xFF${tk.backgroundColor.replaceAll('#', '')});
  static const card = Color(0xFF${tk.cardColor.replaceAll('#', '')});
  static const textPrimary = Color(0xFF${tk.textPrimaryColor.replaceAll('#', '')});
  static const textSecondary = Color(0xFF${tk.textSecondaryColor.replaceAll('#', '')});
  static const error = Color(0xFF${tk.errorColor.replaceAll('#', '')});
  static const success = Color(0xFF${tk.successColor.replaceAll('#', '')});
  static const warning = Color(0xFF${tk.warningColor.replaceAll('#', '')});

  static const hasGradient = ${tk.gradientStartColor.isNotEmpty && tk.gradientEndColor.isNotEmpty};
  static const gradientStart = Color(0xFF${(tk.gradientStartColor.isNotEmpty ? tk.gradientStartColor : tk.primaryColor).replaceAll('#', '')});
  static const gradientEnd = Color(0xFF${(tk.gradientEndColor.isNotEmpty ? tk.gradientEndColor : tk.secondaryColor).replaceAll('#', '')});

  static const gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}''';
  }

  String _genAppTypographyCode(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const fontFamily = '${tk.fontFamily}';

  static const fontSizeXs = ${tk.fontSizeXs};
  static const fontSizeSm = ${tk.fontSizeSm};
  static const fontSizeMd = ${tk.fontSizeMd};
  static const fontSizeLg = ${tk.fontSizeLg};
  static const fontSizeXl = ${tk.fontSizeXl};

  static TextStyle get bodyXs => GoogleFonts.getFont(fontFamily, fontSize: fontSizeXs, fontWeight: FontWeight.normal);
  static TextStyle get bodySm => GoogleFonts.getFont(fontFamily, fontSize: fontSizeSm, fontWeight: FontWeight.normal);
  static TextStyle get bodyMd => GoogleFonts.getFont(fontFamily, fontSize: fontSizeMd, fontWeight: FontWeight.normal);
  static TextStyle get bodyLg => GoogleFonts.getFont(fontFamily, fontSize: fontSizeLg, fontWeight: FontWeight.w600);
  static TextStyle get titleXl => GoogleFonts.getFont(fontFamily, fontSize: fontSizeXl, fontWeight: FontWeight.bold);
}''';
  }

  String _genAppSpacingCode(ThemeTokens tk) {
    return '''class AppSpacing {
  static const xs = ${tk.spacingXs};
  static const sm = ${tk.spacingSm};
  static const md = ${tk.spacingUnit};
  static const lg = ${tk.spacingLg};
  static const xl = ${tk.spacingXl};

  static const radiusSm = ${tk.borderRadiusSm};
  static const radiusMd = ${tk.borderRadius};
  static const radiusLg = ${tk.borderRadiusLg};
}''';
  }

  String _genAppThemeCode(ThemeTokens tk) {
    final borderStr = tk.inputStyle == 'outline'
        ? 'OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))'
        : tk.inputStyle == 'underline'
            ? 'const UnderlineInputBorder()'
            : 'OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(AppSpacing.radiusMd))';

    return '''import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData get themeData {
    final brightness = ${tk.isDarkMode} ? Brightness.dark : Brightness.light;
    return ThemeData(
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        bodySmall: AppTypography.bodySm,
        bodyMedium: AppTypography.bodyMd,
        bodyLarge: AppTypography.bodyLg,
        titleLarge: AppTypography.titleXl,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: $borderStr,
        filled: ${tk.inputStyle == 'filled'},
        fillColor: AppColors.primary.withValues(alpha: 0.05),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: ${tk.dialogStyle == 'outlined'}
              ? const BorderSide(color: AppColors.primary)
              : BorderSide.none,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.card,
        elevation: ${tk.drawerStyle == 'floating'} ? 4 : 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        elevation: ${tk.bottomSheetStyle == 'elevated'} ? 8 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusLg),
            topRight: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.primary,
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: ${tk.cardStyle == 'elevated'} ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: ${tk.cardStyle == 'outlined'}
              ? const BorderSide(color: AppColors.primary)
              : BorderSide.none,
        ),
      ),
      extensions: [
        RevoThemeExtension(
          cardShadow: AppThemeShadows.cardShadow,
          gradient: AppColors.hasGradient ? AppColors.gradient : null,
        ),
      ],
    );
  }
}''';
  }

  String _genThemeExtensionsCode(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';

class RevoThemeExtension extends ThemeExtension<RevoThemeExtension> {
  final List<BoxShadow>? cardShadow;
  final LinearGradient? gradient;

  RevoThemeExtension({this.cardShadow, this.gradient});

  @override
  RevoThemeExtension copyWith({List<BoxShadow>? cardShadow, LinearGradient? gradient}) {
    return RevoThemeExtension(
      cardShadow: cardShadow ?? this.cardShadow,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  RevoThemeExtension lerp(ThemeExtension<RevoThemeExtension>? other, double t) {
    if (other is! RevoThemeExtension) return this;
    return RevoThemeExtension(
      cardShadow: cardShadow,
      gradient: gradient,
    );
  }
}

class AppThemeShadows {
  static final cardShadow = [
    BoxShadow(
      color: const Color(0xFF${tk.shadowColor.replaceAll('#', '')}).withValues(alpha: 0.15),
      blurRadius: ${tk.shadowBlurRadius},
      spreadRadius: ${tk.shadowSpreadRadius},
      offset: const Offset(${tk.shadowOffsetX}, ${tk.shadowOffsetY}),
    ),
  ];
}''';
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
  }

  double _luminance(Color c) {
    double lin(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  double _contrastRatio(Color fg, Color bg) {
    final l1 = _luminance(fg), l2 = _luminance(bg);
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  String _wcag(double ratio) {
    if (ratio >= 7.0) return 'AAA';
    if (ratio >= 4.5) return 'AA';
    if (ratio >= 3.0) return 'AA Large';
    return 'Fail';
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _sec(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: RevoTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
        const Spacer(),
        Container(height: 1, width: 40, color: RevoTheme.cardBorder),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> cb, String suf) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 65, child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: cb)),
          SizedBox(
            width: 40,
            child: Text('${value.toStringAsFixed(0)}$suf', style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> opts, ValueChanged<String?> cb) {
    final safe = opts.contains(value) ? value : opts.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey(safe),
        initialValue: safe,
        onChanged: cb,
        isDense: true,
        style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter(fontSize: 12)))).toList(),
      ),
    );
  }

  Widget _colorRow(String label, String hex, ValueChanged<String> cb) {
    final curatedColors = [
      '#5B4FCF', '#6750A4', '#3B82F6', '#0EA5E9', '#10B981', '#22C55E', '#F97316', '#EF4444',
      '#E91E63', '#9C27B0', '#F59E0B', '#0F172A', '#0D9488', '#607D8B', '#1E293B',
      '#121212', '#1F2937', '#FFFFFF', '#F8FAFC', '#F4F9FF', '#000000', '#FFFBFE',
    ];
    final parsedColor = _hex(hex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: RevoTheme.sidebarBackground,
                title: Text(label, style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: 230,
                  height: 180,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: curatedColors.length,
                    itemBuilder: (_, idx) {
                      final h = curatedColors[idx];
                      final c = _hex(h);
                      final sel = hex.toUpperCase() == h.toUpperCase();
                      return GestureDetector(
                        onTap: () {
                          cb(h);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: sel ? RevoTheme.primary : Colors.grey.withValues(alpha: 0.3), width: sel ? 2.5 : 1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: parsedColor,
                shape: BoxShape.circle,
                border: Border.all(color: RevoTheme.cardBorder, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 2)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(
            child: TextFormField(
              key: ValueKey(hex),
              initialValue: hex,
              onChanged: cb,
              style: GoogleFonts.inter(fontSize: 11),
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _a11yRow(String label, double ratio, String level) {
    final c = level == 'AAA' ? Colors.green : level == 'AA' ? const Color(0xFF3B82F6) : level == 'AA Large' ? Colors.orange : Colors.red;
    return Row(
      children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary))),
        Text('${ratio.toStringAsFixed(1)}:1', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: c.withValues(alpha: 0.4)),
          ),
          child: Text(level, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: c)),
        ),
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
}
