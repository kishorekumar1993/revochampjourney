import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoAuditLogsScreen extends StatelessWidget {
  const RevoAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = [
      {'user': 'admin@revojourneytryone.com', 'action': 'Published Motor Insurance v1.0.0', 'ip': '192.168.1.12', 'time': '10 mins ago'},
      {'user': 'sarah.k@revo.com', 'action': 'Created step: Nominee Details', 'ip': '192.168.1.48', 'time': '2 hours ago'},
      {'user': 'admin@revojourneytryone.com', 'action': 'Imported template ' 'User KYC Onboarding', 'ip': '192.168.1.12', 'time': '1 day ago'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System Audit Logs",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "Activity history tracking configuration updates, deployments, and access logs.",
              style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history_edu_outlined, color: RevoTheme.primaryLight, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log['action']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text("By ${log['user']} • IP: ${log['ip']}", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Text(log['time']!, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
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
