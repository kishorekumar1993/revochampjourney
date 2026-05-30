import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoAnalyticsScreen extends StatelessWidget {
  const RevoAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Conversions & Funnels",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Examine completion funnels, dropout steps, and durations to optimize performance.",
            style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Funnel design mockup
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "KYC Funnel Drop-off Rate Analysis",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildFunnelRow("Step 1: Identity Profile", 1.00, "1,200 entered (100%)"),
                _buildFunnelRow("Step 2: Upload Documents", 0.82, "984 reached (82%)"),
                _buildFunnelRow("Step 3: Facial Selfie Capture", 0.68, "816 reached (68%)"),
                _buildFunnelRow("Step 4: Confirm & Checkout", 0.55, "660 completed (55%)"),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Average durations list
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Average User Session Durations",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDurationItem("Upload Documents Page", "4m 42s", "Slow document scanning validation"),
                _buildDurationItem("Identity Profile Info", "1m 18s", "Standard typing inputs"),
                _buildDurationItem("Premium Payment Gateway", "2m 05s", "Awaiting OTP validation code"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String stepName, double value, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(stepName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: RevoTheme.isDark ? const Color(0xFF2C2C4A) : const Color(0xFFE2E8F0),
                color: RevoTheme.accent,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(details, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationItem(String step, String time, String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: RevoTheme.textSecondary),
              const SizedBox(width: 12),
              Text(step, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          Text(reason, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
        ],
      ),
    );
  }
}
