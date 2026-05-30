import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../application/studio_providers.dart';

class ThemePresetModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final ThemeTokens tokens;

  ThemePresetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.tokens,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'tokens': tokens.toJson(),
      };

  factory ThemePresetModel.fromJson(Map<String, dynamic> j) {
    return ThemePresetModel(
      id: j['id'] as String,
      name: j['name'] as String,
      category: j['category'] as String,
      description: j['description'] as String? ?? '',
      tokens: ThemeTokens.fromJson(j['tokens'] as Map<String, dynamic>),
    );
  }
}

class ThemeMarketplaceService {
  // Preloaded JSON representing database presets
  static const String _defaultPresetsJson = '''[
    {
      "id": "banking",
      "name": "Royal Trust",
      "category": "Banking",
      "description": "Corporate navy with emerald accents for secure financial portals.",
      "tokens": {
        "themeName": "Royal Trust",
        "primaryColor": "#0F172A",
        "secondaryColor": "#10B981",
        "backgroundColor": "#F8FAFC",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#0F172A",
        "textSecondaryColor": "#475569",
        "borderRadius": 4.0,
        "buttonStyle": "elevated",
        "inputStyle": "outline",
        "dialogStyle": "elevated",
        "drawerStyle": "standard",
        "bottomSheetStyle": "flat",
        "tabBarStyle": "pill",
        "navigationBarStyle": "standard",
        "listTileStyle": "card",
        "tableStyle": "bordered",
        "stepperStyle": "standard",
        "snackbarStyle": "floating",
        "dataGridStyle": "compact",
        "calendarStyle": "minimalist",
        "treeViewStyle": "tree-lines",
        "chartsStyle": "solid",
        "timelineStyle": "left-align",
        "kanbanStyle": "board-flat"
      }
    },
    {
      "id": "insurance",
      "name": "Secure Guard",
      "category": "Insurance",
      "description": "Trustworthy royal blue paired with cyan sky highlights.",
      "tokens": {
        "themeName": "Secure Guard",
        "primaryColor": "#1E40AF",
        "secondaryColor": "#0EA5E9",
        "backgroundColor": "#F3F4F6",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#111827",
        "textSecondaryColor": "#4B5563",
        "borderRadius": 8.0,
        "buttonStyle": "elevated",
        "inputStyle": "outline",
        "dialogStyle": "outlined",
        "drawerStyle": "modern",
        "bottomSheetStyle": "glass",
        "tabBarStyle": "underlined",
        "navigationBarStyle": "floating",
        "listTileStyle": "flat",
        "tableStyle": "striped",
        "stepperStyle": "timeline",
        "snackbarStyle": "left-accent",
        "dataGridStyle": "striped",
        "calendarStyle": "card",
        "treeViewStyle": "minimalist",
        "chartsStyle": "gradient-line",
        "timelineStyle": "alternate",
        "kanbanStyle": "column-outline"
      }
    },
    {
      "id": "crm",
      "name": "DealFlow CRM",
      "category": "CRM",
      "description": "Sleek dark slate workspace with energetic mint accents.",
      "tokens": {
        "themeName": "DealFlow CRM",
        "primaryColor": "#0F172A",
        "secondaryColor": "#10B981",
        "backgroundColor": "#F1F5F9",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#0F172A",
        "textSecondaryColor": "#64748B",
        "borderRadius": 10.0,
        "buttonStyle": "tonal",
        "inputStyle": "filled",
        "dialogStyle": "flat",
        "drawerStyle": "modern",
        "bottomSheetStyle": "elevated",
        "tabBarStyle": "pill",
        "navigationBarStyle": "minimal",
        "listTileStyle": "bordered",
        "tableStyle": "simple",
        "stepperStyle": "dots",
        "snackbarStyle": "toast",
        "dataGridStyle": "clean",
        "calendarStyle": "inline",
        "treeViewStyle": "indent-pill",
        "chartsStyle": "bar-flat",
        "timelineStyle": "dot-only",
        "kanbanStyle": "glass"
      }
    },
    {
      "id": "hrms",
      "name": "Pulse People",
      "category": "HRMS",
      "description": "Playful deep indigo and electric magenta for HR portals.",
      "tokens": {
        "themeName": "Pulse People",
        "primaryColor": "#4F46E5",
        "secondaryColor": "#EC4899",
        "backgroundColor": "#FAF5FF",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#1E1B4B",
        "textSecondaryColor": "#581C87",
        "borderRadius": 12.0,
        "buttonStyle": "elevated",
        "inputStyle": "outline",
        "dialogStyle": "elevated",
        "drawerStyle": "floating",
        "bottomSheetStyle": "flat",
        "tabBarStyle": "standard",
        "navigationBarStyle": "standard",
        "listTileStyle": "card",
        "tableStyle": "striped",
        "stepperStyle": "standard",
        "snackbarStyle": "floating",
        "dataGridStyle": "striped",
        "calendarStyle": "card",
        "treeViewStyle": "tree-lines",
        "chartsStyle": "gradient-line",
        "timelineStyle": "alternate",
        "kanbanStyle": "board-flat"
      }
    },
    {
      "id": "healthcare",
      "name": "Care Connect",
      "category": "Healthcare",
      "description": "Calming mint green and active cyan for clinical systems.",
      "tokens": {
        "themeName": "Care Connect",
        "primaryColor": "#0D9488",
        "secondaryColor": "#14B8A6",
        "backgroundColor": "#F0FDFA",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#115E59",
        "textSecondaryColor": "#0F766E",
        "borderRadius": 16.0,
        "buttonStyle": "flat",
        "inputStyle": "underline",
        "dialogStyle": "glass",
        "drawerStyle": "modern",
        "bottomSheetStyle": "glass",
        "tabBarStyle": "underlined",
        "navigationBarStyle": "minimal",
        "listTileStyle": "flat",
        "tableStyle": "simple",
        "stepperStyle": "timeline",
        "snackbarStyle": "top-float",
        "dataGridStyle": "clean",
        "calendarStyle": "minimalist",
        "treeViewStyle": "minimalist",
        "chartsStyle": "solid",
        "timelineStyle": "dot-only",
        "kanbanStyle": "glass"
      }
    },
    {
      "id": "business",
      "name": "Enterprise Hub",
      "category": "Business",
      "description": "Professional royal blue and modern steel grey.",
      "tokens": {
        "themeName": "Enterprise Hub",
        "primaryColor": "#2563EB",
        "secondaryColor": "#475569",
        "backgroundColor": "#F8FAFC",
        "cardColor": "#FFFFFF",
        "textPrimaryColor": "#0F172A",
        "textSecondaryColor": "#475569",
        "borderRadius": 6.0,
        "buttonStyle": "outlined",
        "inputStyle": "outline",
        "dialogStyle": "outlined",
        "drawerStyle": "standard",
        "bottomSheetStyle": "flat",
        "tabBarStyle": "standard",
        "navigationBarStyle": "standard",
        "listTileStyle": "bordered",
        "tableStyle": "bordered",
        "stepperStyle": "standard",
        "snackbarStyle": "standard",
        "dataGridStyle": "compact",
        "calendarStyle": "minimalist",
        "treeViewStyle": "tree-lines",
        "chartsStyle": "solid",
        "timelineStyle": "left-align",
        "kanbanStyle": "board-flat"
      }
    }
  ]''';

  static List<ThemePresetModel> getPresets() {
    try {
      final List<dynamic> decoded = jsonDecode(_defaultPresetsJson) as List<dynamic>;
      return decoded.map((item) => ThemePresetModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      debugPrint("Theme presets decoding error: $e\\n$stack");
      return [];
    }
  }
}
