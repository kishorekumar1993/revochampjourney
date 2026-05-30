import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoUsersScreen extends StatelessWidget {
  const RevoUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Admin User', 'email': 'admin@revojourneytryone.com', 'role': 'Super Admin', 'status': 'Active'},
      {'name': 'Sarah Kerigan', 'email': 'sarah.k@revo.com', 'role': 'Journey Editor', 'status': 'Active'},
      {'name': 'Alice Smith', 'email': 'alice.s@revo.com', 'role': 'Designer', 'status': 'Invited'},
    ];

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Workspace Team Members",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage team roles, access levels, and invite collaborators.",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text("Invite Member"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: RevoTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  final isActive = u['status'] == 'Active';

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
                        CircleAvatar(
                          backgroundColor: RevoTheme.primary.withValues(alpha:0.12),
                          child: Text(u['name']!.substring(0, 2).toUpperCase(), style: TextStyle(color: RevoTheme.primaryLight)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(u['email']!, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(u['role']!, style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? RevoTheme.success.withValues(alpha:0.15) : RevoTheme.warning.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? RevoTheme.success.withValues(alpha:0.4) : RevoTheme.warning.withValues(alpha:0.4)),
                          ),
                          child: Text(
                            u['status']!,
                            style: GoogleFonts.inter(fontSize: 10, color: isActive ? RevoTheme.success : RevoTheme.warning, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          icon: Icon(Icons.more_vert_rounded, color: RevoTheme.textSecondary, size: 16),
                          onPressed: () {},
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
