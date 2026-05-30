import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';

class TypographyTab extends StatelessWidget {
  final ThemeTokens tk;
  final ThemeEditorNotifier n;

  const TypographyTab({
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

  Widget _liveFontPreview() {
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

  @override
  Widget build(BuildContext context) {
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
        _liveFontPreview(),
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
}
