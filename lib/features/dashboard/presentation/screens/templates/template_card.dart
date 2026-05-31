import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';

class TemplateCard extends StatefulWidget {
  final Map<String, dynamic> template;
  final Color badgeColor;
  final IconData icon;
  final bool isDark;
  final Color textBadgeColor;
  final VoidCallback onUse;

  const TemplateCard({
    super.key,
    required this.template,
    required this.badgeColor,
    required this.icon,
    required this.isDark,
    required this.textBadgeColor,
    required this.onUse,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: RevoTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? RevoTheme.primary.withValues(alpha: 0.8) : RevoTheme.cardBorder,
            width: _isHovered ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? RevoTheme.primary.withValues(alpha: 0.15) : const Color(0x0C000000),
              blurRadius: _isHovered ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Icon & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.textBadgeColor,
                    size: 24,
                  ),
                ),
                if (t['badge'] != null && (t['badge'] as String).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      t['badge'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: widget.textBadgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              t['title'] as String? ?? 'Untitled Journey',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: RevoTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                t['description'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: RevoTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Actions Row (Steps Count & Use Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 14, color: RevoTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      "${t['stepsCount'] ?? 0} Steps",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: RevoTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onUse,
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text("Use Template"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: RevoTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
