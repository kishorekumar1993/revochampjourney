import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';

enum _Device { mobile, tablet, desktop }

class AnalyticsTab extends StatefulWidget {
  final ThemeTokens tk;
  const AnalyticsTab({super.key, required this.tk});

  @override
  State<AnalyticsTab> createState() => _State();
}

class _State extends State<AnalyticsTab> {
  _Device _device = _Device.mobile;

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

  Widget _responsivePreview() {
    const double panelW = 256.0;
    
    final Map<_Device, IconData> deviceIcon = {
      _Device.mobile: Icons.phone_iphone,
      _Device.tablet: Icons.tablet_mac,
      _Device.desktop: Icons.desktop_mac
    };
    final Map<_Device, String> deviceLabel = {
      _Device.mobile: 'Mobile',
      _Device.tablet: 'Tablet',
      _Device.desktop: 'Desktop'
    };
    final Map<_Device, double> deviceWidth = {
      _Device.mobile: 390.0,
      _Device.tablet: 768.0,
      _Device.desktop: 1024.0
    };

    final devW = deviceWidth[_device]!;
    final scale = panelW / devW;
    final devH = _device == _Device.mobile ? 520.0 : _device == _Device.tablet ? 540.0 : 380.0;
    final scaledH = devH * scale;

    final pri = _hex(widget.tk.primaryColor);
    final sec = _hex(widget.tk.secondaryColor);
    final bg = _hex(widget.tk.backgroundColor);
    final card = _hex(widget.tk.cardColor);
    final text = _hex(widget.tk.textPrimaryColor);
    final textSec = _hex(widget.tk.textSecondaryColor);
    final rad = BorderRadius.circular(widget.tk.borderRadius);

    final gradient = widget.tk.gradientStartColor.isNotEmpty && widget.tk.gradientEndColor.isNotEmpty
        ? LinearGradient(colors: [_hex(widget.tk.gradientStartColor), _hex(widget.tk.gradientEndColor)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : null;

    final shadow = widget.tk.shadowBlurRadius > 0
        ? [BoxShadow(color: _hex(widget.tk.shadowColor).withValues(alpha: 0.15), blurRadius: widget.tk.shadowBlurRadius, spreadRadius: widget.tk.shadowSpreadRadius, offset: Offset(widget.tk.shadowOffsetX, widget.tk.shadowOffsetY))]
        : null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _Device.values.map((d) {
            final sel = _device == d;
            return GestureDetector(
              onTap: () => setState(() => _device = d),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? RevoTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? RevoTheme.primary : RevoTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(deviceIcon[d]!, size: 18, color: sel ? Colors.white : RevoTheme.textSecondary),
                    const SizedBox(height: 2),
                    Text(deviceLabel[d]!, style: GoogleFonts.inter(fontSize: 10, color: sel ? Colors.white : RevoTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          height: scaledH + 16,
          decoration: BoxDecoration(color: RevoTheme.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: RevoTheme.cardBorder)),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: devW,
                height: devH,
                child: ClipRect(
                  child: Column(
                    children: [
                      // Simulated App Bar
                      Container(
                        width: devW,
                        color: widget.tk.appBarStyle == 'transparent' ? Colors.transparent : pri,
                        decoration: widget.tk.appBarStyle == 'gradient' && gradient != null
                            ? BoxDecoration(gradient: gradient)
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.menu, color: widget.tk.appBarStyle == 'transparent' ? text : Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text('App Dashboard', style: TextStyle(color: widget.tk.appBarStyle == 'transparent' ? text : Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Icon(Icons.notifications_outlined, color: widget.tk.appBarStyle == 'transparent' ? text : Colors.white, size: 20),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: bg,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: rad,
                                  boxShadow: shadow,
                                  border: widget.tk.cardStyle == 'outlined' ? Border.all(color: pri) : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Simulated Card', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
                                    const SizedBox(height: 6),
                                    Text('Layout tokens are propagated live across responsive grid structures.', style: TextStyle(fontSize: 11, color: textSec)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: pri, borderRadius: rad),
                                          child: const Text('Primary Action', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(border: Border.all(color: sec), borderRadius: rad),
                                          child: Text('Secondary', style: TextStyle(color: sec, fontSize: 11)),
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
                      // Navigation Bar
                      Container(
                        color: card,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [Icons.home_rounded, Icons.search_rounded, Icons.person_rounded]
                              .map((ic) => Icon(ic, color: pri, size: 22))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _hex(widget.tk.backgroundColor);
    final textCol = _hex(widget.tk.textPrimaryColor);
    final primary = _hex(widget.tk.primaryColor);
    final cardBg = _hex(widget.tk.cardColor);

    final ratioTextBg = _contrastRatio(textCol, bg);
    final ratioPriBg = _contrastRatio(primary, bg);
    final ratioSecBg = _contrastRatio(_hex(widget.tk.secondaryColor), bg);

    double score = 0;
    score += (ratioTextBg / 7.0).clamp(0.0, 1.0) * 50;
    score += (ratioPriBg / 4.5).clamp(0.0, 1.0) * 30;
    if (widget.tk.isDarkMode) score += 20;

    final accessLevelText = _wcag(ratioTextBg);
    final accessLevelPri = _wcag(ratioPriBg);

    // Layout Validation Engine Conflicts
    final List<String> conflicts = [];
    if (ratioTextBg < 3.0) {
      conflicts.add('CRITICAL: Primary text contrast is extremely low. Increase text weight or select a contrasting tone.');
    }
    if (widget.tk.cardStyle == 'flat' && bg.toARGB32() == cardBg.toARGB32()) {
      conflicts.add('CONFLICT: Flat card color is identical to canvas background. Add card elevations/borders to separate layers.');
    }
    if (widget.tk.isDarkMode && _luminance(bg) > 0.5) {
      conflicts.add('WARNING: Dark Mode is active but background color is light. We recommend setting background hex below #303030.');
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sec('Responsive Device Studio', Icons.devices_rounded),
        const SizedBox(height: 8),
        _responsivePreview(),
        const SizedBox(height: 16),
        _sec('Accessibility Score', Icons.accessibility_new_rounded),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor: RevoTheme.cardBorder,
                      color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${score.toInt()}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
                      Text('/ 100', style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary)),
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
        _sec('Design Engine Warnings', Icons.warning_amber_rounded),
        const SizedBox(height: 8),
        if (conflicts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text('No token conflicts detected.', style: GoogleFonts.inter(fontSize: 11, color: Colors.green)),
              ],
            ),
          )
        else
          ...conflicts.map((warning) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, size: 12, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.redAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 12),
        _sec('Theme Audit Checklist', Icons.fact_check_outlined),
        const SizedBox(height: 8),
        _auditRow('Dark Mode variant defined', widget.tk.isDarkMode),
        _auditRow('Readable primary color contrast (>= 3.0:1)', ratioPriBg >= 3.0),
        _auditRow('Readable text contrast (>= 4.5:1)', ratioTextBg >= 4.5),
        _auditRow('Standard layout font family configured', ['Outfit', 'Inter', 'Roboto', 'Poppins'].contains(widget.tk.fontFamily)),
      ],
    );
  }
}
