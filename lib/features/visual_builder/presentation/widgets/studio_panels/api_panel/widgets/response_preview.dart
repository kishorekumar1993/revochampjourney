import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoResponsePreview extends StatelessWidget {
  final bool isTesting;
  final String? testError;
  final int? responseStatus;
  final String? responseBody;

  const RevoResponsePreview({
    super.key,
    required this.isTesting,
    required this.testError,
    required this.responseStatus,
    required this.responseBody,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Response Preview",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        if (isTesting)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B4FCF)),
            ),
          )
        else if (testError != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              testError!,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
            ),
          )
        else if (responseStatus != null) ...[
          Row(
            children: [
              Text(
                "Status: ",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (responseStatus! >= 200 && responseStatus! < 300)
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  responseStatus.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (responseStatus! >= 200 && responseStatus! < 300) ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (responseBody != null)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: SelectableText(
                  responseBody!,
                  style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.greenAccent),
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "No response loaded yet. Click Send in the address bar.",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}
