import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';
import 'ai_generator.dart';

class ColorsTab extends StatelessWidget {
  final ThemeTokens tk;
  final ThemeEditorNotifier n;

  const ColorsTab({
    super.key,
    required this.tk,
    required this.n,
  });

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

  Widget _modeSwitcher() {
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

  Widget _colorRow(BuildContext context, String label, String hex, ValueChanged<String> cb) {
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AiThemeGeneratorWidget(tokens: tk),
        const SizedBox(height: 16),
        _modeSwitcher(),
        const SizedBox(height: 12),
        _sec('Brand Colors', Icons.palette_rounded),
        const SizedBox(height: 6),
        _colorRow(context, 'Primary', tk.primaryColor, (v) => n.updateTheme(tk.copyWith(primaryColor: v))),
        _colorRow(context, 'Secondary', tk.secondaryColor, (v) => n.updateTheme(tk.copyWith(secondaryColor: v))),
        _colorRow(context, 'Background', tk.backgroundColor, (v) => n.updateTheme(tk.copyWith(backgroundColor: v))),
        _colorRow(context, 'Card BG', tk.cardColor, (v) => n.updateTheme(tk.copyWith(cardColor: v))),
        _colorRow(context, 'Text Primary', tk.textPrimaryColor, (v) => n.updateTheme(tk.copyWith(textPrimaryColor: v))),
        _colorRow(context, 'Text Secondary', tk.textSecondaryColor, (v) => n.updateTheme(tk.copyWith(textSecondaryColor: v))),
        _colorRow(context, 'Error Alert', tk.errorColor, (v) => n.updateTheme(tk.copyWith(errorColor: v))),
        _colorRow(context, 'Success Alert', tk.successColor, (v) => n.updateTheme(tk.copyWith(successColor: v))),
        _colorRow(context, 'Warning Alert', tk.warningColor, (v) => n.updateTheme(tk.copyWith(warningColor: v))),
        const SizedBox(height: 12),
        _sec('Gradient Studio', Icons.gradient_rounded),
        const SizedBox(height: 6),
        _colorRow(context, 'Start Color', tk.gradientStartColor.isEmpty ? '#5B4FCF' : tk.gradientStartColor,
            (v) => n.updateTheme(tk.copyWith(gradientStartColor: v))),
        _colorRow(context, 'End Color', tk.gradientEndColor.isEmpty ? '#9E95F5' : tk.gradientEndColor,
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
}
