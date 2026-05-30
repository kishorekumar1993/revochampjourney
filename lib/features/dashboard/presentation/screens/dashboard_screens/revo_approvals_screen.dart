import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoApprovalsScreen extends StatelessWidget {
  const RevoApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final approvals = [
      {'title': 'Publish Motor Insurance v1.2.0', 'user': 'sarah.k@revo.com', 'date': '2 hours ago', 'status': 'Pending Approval'},
      {'title': 'Add PAN verification API endpoint', 'user': 'john.d@revo.com', 'date': '1 day ago', 'status': 'Approved'},
      {'title': 'Deploy Loan App to Production environment', 'user': 'alice.s@revo.com', 'date': '3 days ago', 'status': 'Approved'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Approval Board",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Review publication changes and REST endpoint setups before going live.",
              style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: approvals.length,
                itemBuilder: (context, index) {
                  final app = approvals[index];
                  final isPending = app['status'] == 'Pending Approval';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app['title']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text("Requested by ${app['user']} • ${app['date']}", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending ? RevoTheme.warning.withValues(alpha:0.15) : RevoTheme.success.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isPending ? RevoTheme.warning.withValues(alpha:0.4) : RevoTheme.success.withValues(alpha:0.4)),
                              ),
                              child: Text(
                                app['status']!,
                                style: GoogleFonts.inter(fontSize: 10, color: isPending ? RevoTheme.warning : RevoTheme.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (isPending) ...[
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text("Request Approved successfully!"), backgroundColor: RevoTheme.success),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: RevoTheme.primary,
                                ),
                                child: const Text("Approve", style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
