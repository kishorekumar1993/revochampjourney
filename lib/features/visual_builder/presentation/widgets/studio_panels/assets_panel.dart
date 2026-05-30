import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';

import 'studio_panel_wrapper.dart';

// 7. Assets list panel
class RevoAssetsPanel extends StatelessWidget {
  const RevoAssetsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final mockAssets = [
      {'name': 'app_logo.png', 'type': 'Image', 'size': '45 KB'},
      {'name': 'onboarding_hero.jpg', 'type': 'Image', 'size': '230 KB'},
      {'name': 'default_avatar.png', 'type': 'Image', 'size': '15 KB'},
      {'name': 'inter_font_regular.ttf', 'type': 'Font', 'size': '120 KB'},
    ];

    return RevoStudioPanelWrapper(
      title: "Assets Studio",
      subtitle: "Manage images, fonts, and assets",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockAssets.length,
        itemBuilder: (context, index) {
          final asset = mockAssets[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              child: ListTile(
                leading: Icon(
                  asset['type'] == 'Image' ? Icons.image_outlined : Icons.font_download_outlined,
                  color: const Color(0xFF5B4FCF),
                ),
                title: Text(
                  asset['name']!,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${asset['type']} • ${asset['size']}",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
                trailing: const Icon(Icons.more_vert_rounded, size: 18),
              ),
            ),
          );
        },
      ),
    );
  }
}

