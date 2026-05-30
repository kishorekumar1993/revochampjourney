import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../../../core/theme.dart';
import '../../../../application/studio_providers.dart';

class AiThemeGeneratorWidget extends ConsumerStatefulWidget {
  final ThemeTokens tokens;
  const AiThemeGeneratorWidget({super.key, required this.tokens});

  @override
  ConsumerState<AiThemeGeneratorWidget> createState() => _State();
}

class _State extends ConsumerState<AiThemeGeneratorWidget> {
  final _promptCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _showApiKeyDialog() {
    final apiKey = ref.read(geminiApiKeyProvider);
    final ctrl = TextEditingController(text: apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Text(
          'Gemini API Key Settings',
          style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your Gemini API key to enable real LLM theme generation. The key is stored in-memory during this session.',
                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: true,
                style: GoogleFonts.inter(fontSize: 11),
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  isDense: true,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(geminiApiKeyProvider.notifier).state = ctrl.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Gemini API Key saved successfully.'),
                duration: Duration(seconds: 2),
              ));
            },
            child: const Text('Save Key', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTheme() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isLoading = true);

    final apiKey = ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty) {
      // Local Heuristic Fallback
      await _runLocalFallback(prompt);
      return;
    }

    try {
      final systemInstruction = '''
You are an expert UI design system generator.
The user wants to generate design tokens matching the prompt: "$prompt".
Respond ONLY with a valid JSON matching the following schema.
No markdown backticks, no wrapping text. Just raw JSON.
Schema:
{
  "themeName": "Theme name matching style",
  "isDarkMode": true or false,
  "primaryColor": "#HEX",
  "secondaryColor": "#HEX",
  "backgroundColor": "#HEX",
  "cardColor": "#HEX",
  "textPrimaryColor": "#HEX",
  "textSecondaryColor": "#HEX",
  "errorColor": "#HEX",
  "successColor": "#HEX",
  "warningColor": "#HEX",
  "fontFamily": "Outfit" or "Inter" or "Poppins" or "Roboto" or "Montserrat",
  "borderRadius": double between 0.0 and 20.0,
  "buttonStyle": "elevated" or "outlined" or "flat" or "tonal",
  "inputStyle": "outline" or "filled" or "underline",
  "dialogStyle": "flat" or "elevated" or "outlined" or "glass",
  "drawerStyle": "standard" or "modern" or "floating",
  "bottomSheetStyle": "flat" or "elevated" or "glass",
  "tabBarStyle": "standard" or "pill" or "underlined",
  "navigationBarStyle": "standard" or "floating" or "minimal",
  "listTileStyle": "flat" or "card" or "bordered",
  "tableStyle": "standard" or "striped" or "bordered",
  "stepperStyle": "standard" or "timeline" or "dots",
  "snackbarStyle": "standard" or "floating" or "left-accent",
  "dataGridStyle": "compact" or "striped" or "clean",
  "calendarStyle": "minimalist" or "card" or "inline",
  "treeViewStyle": "tree-lines" or "minimalist" or "indent-pill",
  "chartsStyle": "solid" or "gradient-line" or "bar-flat",
  "timelineStyle": "left-align" or "alternate" or "dot-only",
  "kanbanStyle": "board-flat" or "column-outline" or "glass"
}
''';

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemInstruction}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body) as Map<String, dynamic>;
        final text = resJson['candidates'][0]['content']['parts'][0]['text'] as String;
        final tokenMap = jsonDecode(text.trim()) as Map<String, dynamic>;

        // Merge generated tokens with active ones
        final updated = ThemeTokens.fromJson({...widget.tokens.toJson(), ...tokenMap});
        ref.read(themeTokensProvider.notifier).updateTheme(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('AI Theme "${updated.themeName}" generated successfully using Gemini LLM!'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("LLM Generation failed, running fallback: $e");
      await _runLocalFallback(prompt, fromError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runLocalFallback(String prompt, {bool fromError = false}) async {
    final query = prompt.toLowerCase();
    await Future.delayed(const Duration(milliseconds: 900));

    bool isDark = query.contains('dark') || query.contains('black') || query.contains('night');
    String primary = '#5B4FCF';
    String secondary = '#9E95F5';
    String bg = isDark ? '#121212' : '#F8FAFC';
    String card = isDark ? '#1E1E1E' : '#FFFFFF';
    String textPri = isDark ? '#FFFFFF' : '#0F172A';
    String textSec = isDark ? '#9CA3AF' : '#475569';
    double radius = 8.0;
    String font = 'Outfit';

    // Heuristics
    if (query.contains('insurance')) {
      primary = '#1E40AF';
      secondary = '#0EA5E9';
      font = 'Inter';
    } else if (query.contains('crm') || query.contains('sales')) {
      primary = '#4F46E5';
      secondary = '#EC4899';
    } else if (query.contains('banking') || query.contains('finance') || query.contains('wealth')) {
      primary = '#0F172A';
      secondary = '#10B981';
      radius = 4.0;
    } else if (query.contains('healthcare') || query.contains('medical') || query.contains('care')) {
      primary = '#0D9488';
      secondary = '#14B8A6';
      radius = 12.0;
    } else if (query.contains('mint') || query.contains('forest') || query.contains('nature')) {
      primary = '#047857';
      secondary = '#34D399';
      bg = isDark ? '#064E3B' : '#ECFDF5';
    } else if (query.contains('neon') || query.contains('cyber') || query.contains('synthwave')) {
      primary = '#F43F5E';
      secondary = '#D946EF';
      isDark = true;
      bg = '#09090B';
      card = '#18181B';
      textPri = '#FFFFFF';
      textSec = '#A1A1AA';
    }

    if (query.contains('rounded') || query.contains('soft')) {
      radius = 16.0;
    } else if (query.contains('sharp') || query.contains('flat')) {
      radius = 0.0;
    }

    final generated = widget.tokens.copyWith(
      themeName: 'AI generated Theme',
      isDarkMode: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      backgroundColor: bg,
      cardColor: card,
      textPrimaryColor: textPri,
      textSecondaryColor: textSec,
      borderRadius: radius,
      fontFamily: font,
    );

    ref.read(themeTokensProvider.notifier).updateTheme(generated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fromError
            ? 'Gemini error. Generated cohesive theme locally.'
            : 'Generated theme locally using design heuristics.'),
        backgroundColor: fromError ? Colors.orange : Colors.blue,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(geminiApiKeyProvider).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Theme Prompt Generator',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              GestureDetector(
                onTap: _showApiKeyDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasKey ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: hasKey ? Colors.green : Colors.amber, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hasKey ? Icons.vpn_key : Icons.vpn_key_outlined, size: 9, color: hasKey ? Colors.green : Colors.amber),
                      const SizedBox(width: 3),
                      Text(hasKey ? 'Gemini Active' : 'Configure Gemini',
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: hasKey ? Colors.green : Colors.amber)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 11),
            decoration: InputDecoration(
              hintText: 'e.g., Create a modern neon health tracking app style with dark mode...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateTheme,
            icon: _isLoading
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
            label: Text(
              _isLoading ? 'Generating tokens...' : 'Generate Theme',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4FCF),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
