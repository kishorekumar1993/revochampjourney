import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';

class RevoApiHubScreen extends StatelessWidget {
  const RevoApiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectors = [
      {'name': 'Get Vehicle Manufacturers', 'method': 'GET', 'url': 'https://api.revojourneytryone.com/v1/vehicles', 'status': 'Connected'},
      {'name': 'Verify PAN Card Number', 'method': 'POST', 'url': 'https://api.kycprovider.org/v1/pan-verify', 'status': 'Connected'},
      {'name': 'Calculate Policy Premium', 'method': 'POST', 'url': 'https://api.insuranceengine.net/premium', 'status': 'Testing'},
      {'name': 'Payment Processing Webhook', 'method': 'POST', 'url': 'https://api.stripe.com/v3/charges', 'status': 'Disconnected'},
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
                      "API Connectors Hub",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Setup endpoint connectors that power your async dropdown selections and onSubmit validation actions.",
                      style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_link_rounded, size: 16),
                  label: const Text("New Connector"),
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
                itemCount: connectors.length,
                itemBuilder: (context, index) {
                  final conn = connectors[index];
                  final isGET = conn['method'] == 'GET';
                  
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
                        // Method tag
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isGET ? RevoTheme.secondary.withValues(alpha:0.15) : RevoTheme.accent.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            conn['method']!,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11, 
                              color: isGET ? RevoTheme.secondary : RevoTheme.accent, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Endpoint
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conn['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(conn['url']!, style: GoogleFonts.sourceCodePro(fontSize: 10, color: RevoTheme.textSecondary)),
                            ],
                          ),
                        ),

                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConnStatusColor(conn['status']!).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getConnStatusColor(conn['status']!).withValues(alpha:0.4)),
                          ),
                          child: Text(
                            conn['status']!,
                            style: GoogleFonts.inter(fontSize: 10, color: _getConnStatusColor(conn['status']!), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 24),

                        IconButton(
                          icon: Icon(Icons.settings_input_component_outlined, color: RevoTheme.primaryLight, size: 16),
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

  Color _getConnStatusColor(String status) {
    if (status == 'Connected') return RevoTheme.success;
    if (status == 'Testing') return RevoTheme.warning;
    return RevoTheme.error;
  }
}
