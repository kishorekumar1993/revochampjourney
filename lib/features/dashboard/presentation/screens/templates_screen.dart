import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';

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
        // Safe JSON serialization/deserialization to ensure strongly typed structures on all platforms
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

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 32),

                // Dynamic templates grid
                Expanded(
                  child: _buildContent(),
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

  Widget _buildContent() {
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

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final t = _templates[index] as Map<String, dynamic>;
        final badgeColor = _parseHexColor(t['badgeColor'] as String?);
        final icon = _getIconData(t['icon'] as String?);

        return Container(
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RevoTheme.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with Icon & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      icon,
                      color: badgeColor,
                      size: 24,
                    ),
                  ),
                  if (t['badge'] != null && (t['badge'] as String).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        t['badge'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                t['title'] as String? ?? 'Untitled Journey',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  t['description'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: RevoTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions Row (Steps Count & Use Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers_outlined, size: 14, color: RevoTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        "${t['stepsCount'] ?? 0} Steps",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: RevoTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _useTemplate(t),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text("Use Template"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: RevoTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
