import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/theme.dart';
import '../../../../journey_builder/presentation/providers/journey_provider.dart';
import 'template_card.dart';

class RevoTemplatesScreen extends ConsumerStatefulWidget {
  final VoidCallback onTemplateLoaded;

  const RevoTemplatesScreen({
    super.key,
    required this.onTemplateLoaded,
  });

  @override
  ConsumerState<RevoTemplatesScreen> createState() => _RevoTemplatesScreenState();
}

class _RevoTemplatesScreenState extends ConsumerState<RevoTemplatesScreen> {
  List<dynamic> _templates = [];
  bool _isLoadingTemplates = true;
  String? _errorMessage;
  bool _isDownloadingConfig = false;

  // Search and filter state
  String _searchQuery = "";
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchTemplatesList();
  }

  Future<void> _fetchTemplatesList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTemplates = true;
      _errorMessage = null;
    });

    try {
      final client = http.Client();
      final response = await client
          .get(Uri.parse('https://json.revochamp.site/journeyflow/configlist.json'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final rawDecoded = json.decode(utf8.decode(response.bodyBytes));
        final decoded = json.decode(json.encode(rawDecoded));

        List<dynamic> templatesList = [];
        if (decoded is List) {
          templatesList = decoded;
        } else if (decoded is Map && decoded['value'] is List) {
          templatesList = decoded['value'] as List;
        } else {
          throw const FormatException("API response is neither a list nor a map with 'value' list.");
        }

        if (mounted) {
          setState(() {
            _templates = templatesList;
            _isLoadingTemplates = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Server returned HTTP ${response.statusCode}: ${response.reasonPhrase}";
            _isLoadingTemplates = false;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = "Request timed out. Please check your internet connection.";
          _isLoadingTemplates = false;
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Response format error: ${e.message}";
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to fetch template list: ${e.toString()}";
          _isLoadingTemplates = false;
        });
      }
    }
  }

  Future<void> _useTemplate(Map<String, dynamic> template) async {
    final configName = template['config'] as String?;
    if (configName == null || configName.isEmpty) {
      _showErrorSnackBar("Template configuration name is missing.");
      return;
    }

    setState(() {
      _isDownloadingConfig = true;
    });

    try {
      final url = 'https://json.revochamp.site/journeyflow/list/$configName.json';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        
        // Update journey config using the provider
        final success = ref.read(journeyConfigProvider.notifier).updateFromJson(bodyString);
        
        if (success) {
          if (mounted) {
            _showSuccessSnackBar("Loaded template: ${template['title'] ?? 'Journey'} successfully!");
            widget.onTemplateLoaded();
          }
        } else {
          _showErrorSnackBar("Error: The fetched configuration could not be parsed.");
        }
      } else {
        _showErrorSnackBar("Failed to download template (HTTP ${response.statusCode})");
      }
    } on TimeoutException {
      _showErrorSnackBar("Download timed out. Server may be slow.");
    } catch (e) {
      _showErrorSnackBar("Download error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingConfig = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: RevoTheme.success),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'directions_car_filled_outlined':
        return Icons.directions_car_filled_outlined;
      case 'badge_outlined':
        return Icons.badge_outlined;
      case 'monetization_on_outlined':
        return Icons.monetization_on_outlined;
      case 'rate_review_outlined':
        return Icons.rate_review_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return RevoTheme.primaryLight;
    }
    try {
      final hexString = hex.replaceAll('#', '');
      if (hexString.length == 6) {
        return Color(int.parse('FF$hexString', radix: 16));
      } else if (hexString.length == 8) {
        return Color(int.parse(hexString, radix: 16));
      }
    } catch (e) {
      // Fallback
    }
    return RevoTheme.primaryLight;
  }

  Color _getBadgeTextColor(Color badgeColor, bool isDark) {
    final hsl = HSLColor.fromColor(badgeColor);
    if (isDark) {
      if (hsl.lightness < 0.4) {
        return hsl.withLightness(0.7).toColor();
      }
      return badgeColor;
    } else {
      if (hsl.lightness > 0.5) {
        return hsl.withLightness(0.35).toColor();
      }
      return badgeColor;
    }
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 300,
      height: 42,
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textPrimary),
        decoration: InputDecoration(
          hintText: "Search templates...",
          hintStyle: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textSecondary),
          prefixIcon: Icon(Icons.search, color: RevoTheme.textSecondary, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: RevoTheme.textSecondary, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: RevoTheme.cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RevoTheme.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RevoTheme.cardBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : RevoTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              selectedColor: RevoTheme.primary,
              backgroundColor: RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : RevoTheme.cardBorder,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the themeModeProvider to trigger UI rebuilds on theme toggle
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamically extract categories from available templates list
    final List<String> categories = ["All"];
    for (var t in _templates) {
      final badge = t['badge'] as String? ?? '';
      if (badge.isNotEmpty && !categories.contains(badge)) {
        categories.add(badge);
      }
    }

    // Filter templates list based on search query and category
    final filteredTemplates = _templates.where((t) {
      final title = (t['title'] as String? ?? '').toLowerCase();
      final desc = (t['description'] as String? ?? '').toLowerCase();
      final badge = (t['badge'] as String? ?? '').toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) ||
          desc.contains(_searchQuery.toLowerCase());
          
      if (_selectedCategory == "All") {
        return matchesSearch;
      } else {
        return matchesSearch && badge == _selectedCategory.toLowerCase();
      }
    }).toList();

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Header
                Text(
                  "Journey Templates",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: RevoTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Select a premade template structure to import and customize in the builder canvas.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: RevoTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Responsive Search and Filters Controls
                if (!_isLoadingTemplates && _errorMessage == null && _templates.isNotEmpty) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildFilterChips(categories)),
                            const SizedBox(width: 24),
                            _buildSearchBar(),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 12),
                            _buildFilterChips(categories),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Content Area
                Expanded(
                  child: _buildContent(filteredTemplates, isDark),
                ),
              ],
            ),
          ),
          if (_isDownloadingConfig)
            Container(
              color: Colors.black54,
              child: Center(
                child: RevoTheme.glassmorphicContainer(
                  padding: const EdgeInsets.all(32),
                  borderRadius: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: RevoTheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Downloading template configuration...",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RevoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(List<dynamic> filteredTemplates, bool isDark) {
    if (_isLoadingTemplates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: RevoTheme.primary),
            const SizedBox(height: 16),
            Text(
              "Loading templates from API...",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: RevoTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: RevoTheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: RevoTheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTemplatesList,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: RevoTheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Text(
          "No templates available.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: RevoTheme.textSecondary,
          ),
        ),
      );
    }

    if (filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: RevoTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              "No templates match your search filters.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: RevoTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 480,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 260,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final t = filteredTemplates[index] as Map<String, dynamic>;
        final rawColor = _parseHexColor(t['badgeColor'] as String?);
        final icon = _getIconData(t['icon'] as String?);
        final textBadgeColor = _getBadgeTextColor(rawColor, isDark);

        return TemplateCard(
          template: t,
          badgeColor: rawColor,
          icon: icon,
          isDark: isDark,
          textBadgeColor: textBadgeColor,
          onUse: () => _useTemplate(t),
        );
      },
    );
  }
}
