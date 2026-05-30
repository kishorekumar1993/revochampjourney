import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';
import '../../../../application/theme_marketplace_service.dart';

class CompareThemeView extends StatelessWidget {
  final ThemeTokens cur;
  final ThemePresetModel preset;

  const CompareThemeView({
    super.key,
    required this.cur,
    required this.preset,
  });

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.tryParse(h, radix: 16) ?? 0xFFAAAAAA);
  }

  Widget _dot(String hex) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: _hex(hex),
          shape: BoxShape.circle,
          border: Border.all(color: RevoTheme.cardBorder, width: 0.5),
        ),
      );

  Widget _diffBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber[800]),
      ),
    );
  }

  Widget _diffRow(String label, String curVal, String targetVal, bool isColor) {
    final isDifferent = curVal.toLowerCase() != targetVal.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 85,
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
          Icon(
            isDifferent ? Icons.arrow_right_alt_rounded : Icons.check_circle_outline,
            size: 14,
            color: isDifferent ? Colors.orange : Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
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
      ('DataGrid Style', cur.dataGridStyle, pre.dataGridStyle),
      ('Charts Style', cur.chartsStyle, pre.chartsStyle),
    ];

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
              Expanded(
                child: Text(
                  'Current Theme Settings',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                ),
              ),
              const Icon(Icons.compare_arrows_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  preset.name,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: RevoTheme.primary),
                  textAlign: TextAlign.right,
                ),
              ),
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
}
