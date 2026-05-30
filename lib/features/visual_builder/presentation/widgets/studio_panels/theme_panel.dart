import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../application/studio_providers.dart';

import 'studio_panel_wrapper.dart';

// 2. Theme Studio customize panel
class RevoThemeStudioPanel extends ConsumerWidget {
  const RevoThemeStudioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(themeTokensProvider);
    final notifier = ref.read(themeTokensProvider.notifier);

    final presets = [
      {
        'name': 'Midnight Indigo',
        'primary': '#5B4FCF',
        'secondary': '#9E95F5',
        'bg': '#F4F9FF',
        'card': '#FFFFFF',
        'text': '#1A1A2E',
        'dark': false,
      },
      {
        'name': 'Forest Mint',
        'primary': '#009688',
        'secondary': '#00BCD4',
        'bg': '#E0F2F1',
        'card': '#FFFFFF',
        'text': '#004D40',
        'dark': false,
      },
      {
        'name': 'Sunset Amber',
        'primary': '#FF9800',
        'secondary': '#FF5722',
        'bg': '#FFF3E0',
        'card': '#FFFFFF',
        'text': '#E65100',
        'dark': false,
      },
      {
        'name': 'Slate (Dark)',
        'primary': '#607D8B',
        'secondary': '#90A4AE',
        'bg': '#1E293B',
        'card': '#334155',
        'text': '#F8FAFC',
        'dark': true,
      },
      {
        'name': 'Cyber Neon',
        'primary': '#E91E63',
        'secondary': '#9C27B0',
        'bg': '#121212',
        'card': '#1E1E1E',
        'text': '#FFFFFF',
        'dark': true,
      },
    ];

    void showGeneratedCode(BuildContext context, String code) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: RevoTheme.sidebarBackground,
            title: Text("Generated theme.dart", style: GoogleFonts.outfit(color: RevoTheme.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: TextField(
                controller: TextEditingController(text: code),
                maxLines: null,
                readOnly: true,
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Colors.black,
                  filled: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF5B4FCF))),
              ),
            ],
          );
        },
      );
    }

    String generateThemeDart(ThemeTokens tk) {
      return '''
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GeneratedAppTheme {
  static const primaryColor = Color(0xFF\${tk.primaryColor.replaceAll('#', '')});
  static const secondaryColor = Color(0xFF\${tk.secondaryColor.replaceAll('#', '')});
  static const backgroundColor = Color(0xFF\${tk.backgroundColor.replaceAll('#', '')});
  static const cardColor = Color(0xFF\${tk.cardColor.replaceAll('#', '')});
  static const textPrimaryColor = Color(0xFF\${tk.textPrimaryColor.replaceAll('#', '')});

  static ThemeData get themeData {
    final brightness = ${tk.isDarkMode} ? Brightness.dark : Brightness.light;
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.\${tk.fontFamily.toLowerCase()}TextTheme(
        ThemeData(brightness: brightness).textTheme.copyWith(
          bodyLarge: TextStyle(color: textPrimaryColor),
          bodyMedium: TextStyle(color: textPrimaryColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(\${tk.borderRadius}),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: \${tk.inputStyle == 'outline' ? 'OutlineInputBorder(borderRadius: BorderRadius.circular(\${tk.borderRadius}))' : tk.inputStyle == 'underline' ? 'UnderlineInputBorder()' : 'OutlineInputBorder()'},
        filled: \${tk.inputStyle == 'filled'},
        fillColor: primaryColor.withOpacity(0.05),
      ),
    );
  }
}
''';
    }

    Widget buildColorPickerRow(String label, String hexValue, ValueChanged<String> onChanged) {
      final parsedColor = Color(int.parse(hexValue.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
      final curatedColors = [
        '#5B4FCF', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4', '#009688', 
        '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', 
        '#FF5722', '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#795548', 
        '#607D8B', '#121212', '#1E1E1E', '#FFFFFF', '#F4F9FF', '#F4F5F7'
      ];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: RevoTheme.sidebarBackground,
                          title: Text("Select $label", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 16)),
                          content: SizedBox(
                            width: 250,
                            height: 200,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: curatedColors.length,
                              itemBuilder: (context, idx) {
                                final hex = curatedColors[idx];
                                final c = Color(int.parse(hex.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
                                final isSelected = hexValue.toUpperCase() == hex.toUpperCase();
                                return GestureDetector(
                                  onTap: () {
                                    onChanged(hex);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF5B4FCF) : Colors.grey.withValues(alpha: 0.3),
                                        width: isSelected ? 3.0 : 1.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: parsedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: RevoTheme.cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(hexValue),
                    initialValue: hexValue,
                    onChanged: onChanged,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildTypographyPreview(ThemeTokens tk) {
      final primary = Color(int.parse(tk.primaryColor.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
      final textCol = Color(int.parse(tk.textPrimaryColor.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tk.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Typography Preview (${tk.fontFamily})",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Heading Preview",
              style: GoogleFonts.getFont(
                tk.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "This is a preview paragraph showing body copy under your selected font family.",
              style: GoogleFonts.getFont(
                tk.fontFamily,
                fontSize: 11,
                color: textCol,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildComponentPreview(ThemeTokens tk) {
      final primary = Color(int.parse(tk.primaryColor.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
      final textCol = Color(int.parse(tk.textPrimaryColor.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
      final cardBg = Color(int.parse(tk.cardColor.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tk.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RevoTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Component Style Preview",
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tk.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Themed Card Container",
                      style: GoogleFonts.getFont(tk.fontFamily, fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      enabled: false,
                      style: GoogleFonts.getFont(tk.fontFamily, fontSize: 10),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Themed Input',
                        labelStyle: TextStyle(fontSize: 10, color: primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: tk.inputStyle == 'underline'
                            ? const UnderlineInputBorder()
                            : OutlineInputBorder(borderRadius: BorderRadius.circular(tk.borderRadius)),
                        filled: tk.inputStyle == 'filled',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tk.borderRadius)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        "Themed Button",
                        style: GoogleFonts.getFont(tk.fontFamily, fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RevoStudioPanelWrapper(
      title: "Theme Studio",
      subtitle: "Customize visual theme design tokens",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text("Dark Theme Mode", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
            subtitle: Text("Invert canvas colors for night view", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary)),
            value: tokens.isDarkMode,
            onChanged: (val) {
              final newBg = val ? '#121212' : '#FFFFFF';
              final newCard = val ? '#1E1E1E' : '#FFFFFF';
              final newText = val ? '#FFFFFF' : '#1A1A2E';
              notifier.updateTheme(tokens.copyWith(
                isDarkMode: val,
                backgroundColor: newBg,
                cardColor: newCard,
                textPrimaryColor: newText,
              ));
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            "Color Presets Palette",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              itemBuilder: (context, idx) {
                final p = presets[idx];
                final primaryColor = Color(int.parse((p['primary'] as String).replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
                final bgColor = Color(int.parse((p['bg'] as String).replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    onPressed: () {
                      notifier.updateTheme(tokens.copyWith(
                        primaryColor: p['primary'] as String,
                        secondaryColor: p['secondary'] as String,
                        backgroundColor: p['bg'] as String,
                        cardColor: p['card'] as String,
                        textPrimaryColor: p['text'] as String,
                        isDarkMode: p['dark'] as bool,
                      ));
                    },
                    avatar: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                        const SizedBox(width: 2),
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle)),
                      ],
                    ),
                    label: Text(p['name'] as String, style: const TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          buildColorPickerRow(
            "Primary Color (Hex)",
            tokens.primaryColor,
            (val) => notifier.updateTheme(tokens.copyWith(primaryColor: val)),
          ),
          buildColorPickerRow(
            "Secondary Color (Hex)",
            tokens.secondaryColor,
            (val) => notifier.updateTheme(tokens.copyWith(secondaryColor: val)),
          ),
          buildColorPickerRow(
            "Background Color (Hex)",
            tokens.backgroundColor,
            (val) => notifier.updateTheme(tokens.copyWith(backgroundColor: val)),
          ),
          buildColorPickerRow(
            "Card Container Color (Hex)",
            tokens.cardColor,
            (val) => notifier.updateTheme(tokens.copyWith(cardColor: val)),
          ),
          buildColorPickerRow(
            "Text Primary Color (Hex)",
            tokens.textPrimaryColor,
            (val) => notifier.updateTheme(tokens.copyWith(textPrimaryColor: val)),
          ),
          _buildDropdown(
            label: "Font Family",
            value: tokens.fontFamily,
            options: ['Outfit', 'Inter', 'Roboto', 'Poppins', 'Open Sans'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(fontFamily: val)),
          ),
          const SizedBox(height: 8),
          Text(
            "Border Radius: ${tokens.borderRadius.toInt()} px",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          Slider(
            min: 0,
            max: 24,
            value: tokens.borderRadius,
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(borderRadius: val)),
          ),
          _buildDropdown(
            label: "Button Theme",
            value: tokens.buttonStyle,
            options: ['elevated', 'outlined', 'flat'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(buttonStyle: val)),
          ),
          _buildDropdown(
            label: "Input Decoration Theme",
            value: tokens.inputStyle,
            options: ['outline', 'filled', 'underline'],
            onChanged: (val) => notifier.updateTheme(tokens.copyWith(inputStyle: val)),
          ),
          const SizedBox(height: 12),
          buildTypographyPreview(tokens),
          const SizedBox(height: 12),
          buildComponentPreview(tokens),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final code = generateThemeDart(tokens);
              showGeneratedCode(context, code);
            },
            icon: const Icon(Icons.code_rounded, size: 16, color: Colors.white),
            label: const Text("Generate theme.dart", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4FCF),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Common UI helper widgets ---

Widget _buildTextField({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}


