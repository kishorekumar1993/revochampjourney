import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_controller.dart';

class JsonConfigSection extends ConsumerStatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const JsonConfigSection({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  ConsumerState<JsonConfigSection> createState() => _JsonConfigSectionState();
}

class _JsonConfigSectionState extends ConsumerState<JsonConfigSection> {
  String _activeTab = 'Editor';
  final _jsonController = TextEditingController();
  bool _isValidJson = true;
  String _jsonError = '';
  final FocusNode _jsonFocus = FocusNode();
  Timer? _jsonDebounce;

  ProviderSubscription<JourneyConfig>? _configSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize text editor with current config state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(journeyConfigProvider);
      _jsonController.text = _beautifyJson(config.toJson());
    });

    // Sync JSON text field if updated visually
    _configSubscription = ref.listenManual<JourneyConfig>(journeyConfigProvider, (prev, next) {
      if (!mounted) return;
      if (_jsonFocus.hasFocus) return; // Prevent overwriting while actively typing
      try {
        final currentTextDecoded = json.encode(json.decode(_jsonController.text));
        final nextDecoded = json.encode(next.toJson());
        if (currentTextDecoded != nextDecoded) {
          _jsonController.text = _beautifyJson(next.toJson());
        }
      } catch (_) {
        _jsonController.text = _beautifyJson(next.toJson());
      }
    });
  }

  @override
  void dispose() {
    _configSubscription?.close();
    _jsonDebounce?.cancel();
    _jsonFocus.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  String _beautifyJson(Map<String, dynamic> jsonMap) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonMap);
  }

  void _onJsonTextChanged(String val, WidgetRef ref) {
    if (val.trim().isEmpty) return;
    _jsonDebounce?.cancel();
    _jsonDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      try {
        json.decode(val);
        final success = ref.read(journeyConfigProvider.notifier).updateFromJson(val);
        setState(() {
          _isValidJson = success;
          _jsonError = success ? '' : 'Schema mismatch or invalid keys';
        });
      } catch (e) {
        setState(() {
          _isValidJson = false;
          _jsonError = e.toString();
        });
      }
    });
  }

  void _beautifyText() {
    try {
      final decoded = json.decode(_jsonController.text);
      setState(() {
        _jsonController.text = _beautifyJson(decoded);
        _isValidJson = true;
        _jsonError = '';
      });
    } catch (e) {
      setState(() {
        _isValidJson = false;
        _jsonError = e.toString();
      });
    }
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _activeTab = text),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? RevoTheme.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: RevoTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "JSON Config Code",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.isExpanded ? RevoTheme.primaryLight : RevoTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (widget.isExpanded)
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: RevoTheme.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        _buildTabButton("Editor", _activeTab == 'Editor'),
                        _buildTabButton("Preview", _activeTab == 'Preview'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.isExpanded)
          Container(
            height: 300, // Fixed height for JSON Config panel to prevent visual distortion
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _activeTab == 'Editor'
                ? Container(
                    decoration: BoxDecoration(
                      color: RevoTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isValidJson ? RevoTheme.cardBorder : Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Format: JSON", style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.copy_all_rounded, size: 14, color: RevoTheme.textSecondary),
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: _jsonController.text));
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("JSON Copied!")),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: _jsonController,
                              focusNode: _jsonFocus,
                              maxLines: null,
                              style: const TextStyle(fontFamily: 'Source Code Pro', fontSize: 11, color: Colors.greenAccent),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => _onJsonTextChanged(val, ref),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isValidJson
                                    ? RevoTheme.secondary.withValues(alpha: 0.15)
                                    : Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isValidJson ? "Valid JSON" : "Invalid JSON",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  color: _isValidJson ? RevoTheme.secondary : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _beautifyText,
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                              child: Text("Beautify", style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.primaryLight)),
                            ),
                          ],
                        ),
                        if (!_isValidJson && _jsonError.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _jsonError,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.redAccent),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: RevoTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Text(
                        _jsonController.text,
                        style: TextStyle(fontFamily: 'Source Code Pro', fontSize: 11, color: RevoTheme.textSecondary),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
