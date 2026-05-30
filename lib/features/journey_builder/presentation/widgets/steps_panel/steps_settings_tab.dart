import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';

class StepsSettingsTab extends ConsumerStatefulWidget {
  final JourneyConfig config;

  const StepsSettingsTab({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<StepsSettingsTab> createState() => _StepsSettingsTabState();
}

class _StepsSettingsTabState extends ConsumerState<StepsSettingsTab> {
  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _descriptionController;

  late FocusNode _nameFocus;
  late FocusNode _versionFocus;
  late FocusNode _descriptionFocus;

  ProviderSubscription<JourneyConfig>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config.journeyName);
    _versionController = TextEditingController(text: widget.config.version);
    _descriptionController = TextEditingController(text: widget.config.description);

    _nameFocus = FocusNode();
    _versionFocus = FocusNode();
    _descriptionFocus = FocusNode();

    _configSubscription = ref.listenManual<JourneyConfig>(journeyConfigProvider, (prev, next) {
      if (!_nameFocus.hasFocus && _nameController.text != next.journeyName) {
        _nameController.text = next.journeyName;
      }
      if (!_versionFocus.hasFocus && _versionController.text != next.version) {
        _versionController.text = next.version;
      }
      if (!_descriptionFocus.hasFocus && _descriptionController.text != next.description) {
        _descriptionController.text = next.description;
      }
    });
  }

  @override
  void dispose() {
    _configSubscription?.close();
    _nameController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _versionFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Global Journey Settings",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Configure journey properties and settings globally.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Name field
          Text("Journey Title", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyName(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Description field
          Text("Journey Description", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            maxLines: 3,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyDescription(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Version field
          Text("Semantic Version", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _versionController,
            focusNode: _versionFocus,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            onChanged: (val) {
              ref.read(journeyConfigProvider.notifier).updateJourneyVersion(val.trim());
            },
          ),
          const SizedBox(height: 16),

          // Category Selector
          Text("Journey Category", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: config.category,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['Onboarding', 'KYC Verification', 'Fintech Form', 'General Claim'].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(journeyConfigProvider.notifier).updateJourneyCategory(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Locale Selector
          Text("Default System Language", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: config.locale,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['English (US)', 'Spanish (ES)', 'Hindi (IN)', 'German (DE)'].map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(journeyConfigProvider.notifier).updateJourneyLocale(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Platform selector
          Text("Target Run Environment", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: config.platform,
                isExpanded: true,
                dropdownColor: RevoTheme.cardBg,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: RevoTheme.textPrimary),
                items: ['All Devices', 'Mobile Web Only', 'Desktop Only'].map((plat) {
                  return DropdownMenuItem(value: plat, child: Text(plat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(journeyConfigProvider.notifier).updateJourneyPlatform(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RevoTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Journey Settings saved!"),
                  backgroundColor: RevoTheme.success,
                ),
              );
            },
            child: const Text("Save Global Settings", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
