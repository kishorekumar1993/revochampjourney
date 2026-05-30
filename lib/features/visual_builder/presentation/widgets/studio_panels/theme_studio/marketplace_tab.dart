import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';
import '../../../../application/theme_marketplace_service.dart';
import 'compare_view.dart';

class MarketplaceTab extends ConsumerStatefulWidget {
  final ThemeTokens tokens;
  const MarketplaceTab({super.key, required this.tokens});

  @override
  ConsumerState<MarketplaceTab> createState() => _State();
}

class _State extends ConsumerState<MarketplaceTab> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String? _compareId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
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

  @override
  Widget build(BuildContext context) {
    final presets = ThemeMarketplaceService.getPresets();
    final search = _searchCtrl.text.toLowerCase();
    
    final filtered = presets.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(search) ||
          p.category.toLowerCase().contains(search) ||
          p.description.toLowerCase().contains(search);
      return matchesCat && matchesSearch;
    }).toList();

    final n = ref.read(themeTokensProvider.notifier);

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
              ...filtered.map((preset) => _presetCard(preset, widget.tokens, n)),
              if (_compareId != null) ...[
                const SizedBox(height: 20),
                _sec('Visual Diff Comparison', Icons.compare_arrows_rounded),
                const SizedBox(height: 8),
                CompareThemeView(
                  cur: widget.tokens,
                  preset: presets.firstWhere((p) => p.id == _compareId),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetCard(ThemePresetModel p, ThemeTokens current, ThemeEditorNotifier n) {
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
            height: 95,
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
                                    height: 26,
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
}
