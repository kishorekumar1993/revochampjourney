import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoSettingsScreen extends StatefulWidget {
  const RevoSettingsScreen({super.key});

  @override
  State<RevoSettingsScreen> createState() => _RevoSettingsScreenState();
}

class _RevoSettingsScreenState extends State<RevoSettingsScreen> {
  bool _autosave = true;
  bool _enableLogs = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Settings",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Configure workspace preferences, REST webhook secrets, and general configurations.",
            style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Workspace Settings Card
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
                Text("General Settings", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField("Workspace Domain Name", "revojourneytryone-admin-prod"),
                const SizedBox(height: 16),
                _buildSwitchRow("Automatic Step Auto-Save", _autosave, (val) => setState(() => _autosave = val)),
                const SizedBox(height: 8),
                _buildSwitchRow("Enable Verbose Application Logs", _enableLogs, (val) => setState(() => _enableLogs = val)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API & Secrets Card
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
                Text("Secrets & Security Keys", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField("Global Secret Webhook Key", "shsec_9821_revo_champ_verification_jwt"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Settings updated successfully!"), backgroundColor: RevoTheme.success),
                    );
                  },
                  child: const Text("Save System Configuration"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: initial),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13)),
        Switch(value: value, activeThumbColor: RevoTheme.primaryLight, onChanged: onChanged),
      ],
    );
  }
}
