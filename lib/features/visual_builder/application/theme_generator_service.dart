import 'dart:convert';
import '../application/studio_providers.dart';

class ThemeGeneratorService {
  static String generateAppColors(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF${tk.primaryColor.replaceAll('#', '')});
  static const secondary = Color(0xFF${tk.secondaryColor.replaceAll('#', '')});
  static const background = Color(0xFF${tk.backgroundColor.replaceAll('#', '')});
  static const card = Color(0xFF${tk.cardColor.replaceAll('#', '')});
  static const textPrimary = Color(0xFF${tk.textPrimaryColor.replaceAll('#', '')});
  static const textSecondary = Color(0xFF${tk.textSecondaryColor.replaceAll('#', '')});
  static const error = Color(0xFF${tk.errorColor.replaceAll('#', '')});
  static const success = Color(0xFF${tk.successColor.replaceAll('#', '')});
  static const warning = Color(0xFF${tk.warningColor.replaceAll('#', '')});

  static const hasGradient = ${tk.gradientStartColor.isNotEmpty && tk.gradientEndColor.isNotEmpty};
  static const gradientStart = Color(0xFF${(tk.gradientStartColor.isNotEmpty ? tk.gradientStartColor : tk.primaryColor).replaceAll('#', '')});
  static const gradientEnd = Color(0xFF${(tk.gradientEndColor.isNotEmpty ? tk.gradientEndColor : tk.secondaryColor).replaceAll('#', '')});

  static const gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}''';
  }

  static String generateAppTypography(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const fontFamily = '${tk.fontFamily}';

  static const fontSizeXs = ${tk.fontSizeXs};
  static const fontSizeSm = ${tk.fontSizeSm};
  static const fontSizeMd = ${tk.fontSizeMd};
  static const fontSizeLg = ${tk.fontSizeLg};
  static const fontSizeXl = ${tk.fontSizeXl};

  static TextStyle get bodyXs => GoogleFonts.getFont(fontFamily, fontSize: fontSizeXs, fontWeight: FontWeight.normal);
  static TextStyle get bodySm => GoogleFonts.getFont(fontFamily, fontSize: fontSizeSm, fontWeight: FontWeight.normal);
  static TextStyle get bodyMd => GoogleFonts.getFont(fontFamily, fontSize: fontSizeMd, fontWeight: FontWeight.normal);
  static TextStyle get bodyLg => GoogleFonts.getFont(fontFamily, fontSize: fontSizeLg, fontWeight: FontWeight.w600);
  static TextStyle get titleXl => GoogleFonts.getFont(fontFamily, fontSize: fontSizeXl, fontWeight: FontWeight.bold);
}''';
  }

  static String generateAppSpacing(ThemeTokens tk) {
    return '''class AppSpacing {
  static const xs = ${tk.spacingXs};
  static const sm = ${tk.spacingSm};
  static const md = ${tk.spacingUnit};
  static const lg = ${tk.spacingLg};
  static const xl = ${tk.spacingXl};

  static const radiusSm = ${tk.borderRadiusSm};
  static const radiusMd = ${tk.borderRadius};
  static const radiusLg = ${tk.borderRadiusLg};
}''';
  }

  static String generateAppDimensions(ThemeTokens tk) {
    return '''class AppDimensions {
  static const sidebarWidth = 280.0;
  static const appBarHeight = 64.0;
  static const cardMinHeight = 120.0;
}''';
  }

  static String generateAppElevation(ThemeTokens tk) {
    return '''class AppElevation {
  static const none = 0.0;
  static const low = 2.0;
  static const medium = 6.0;
  static const high = 12.0;
}''';
  }

  static String generateAppBreakpoints(ThemeTokens tk) {
    return '''class AppBreakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  static const desktop = 1440.0;
}''';
  }

  static String generateAppAnimations(ThemeTokens tk) {
    return '''class AppAnimations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 600);
}''';
  }

  static String generateAppIcons(ThemeTokens tk) {
    return '''class AppIcons {
  static const xs = 12.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
}''';
  }

  static String generateComponentThemes(ThemeTokens tk) {
    final borderStr = tk.inputStyle == 'outline'
        ? 'OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))'
        : tk.inputStyle == 'underline'
            ? 'const UnderlineInputBorder()'
            : 'OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(AppSpacing.radiusMd))';

    return '''import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'app_elevation.dart';

class ComponentThemes {
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        border: $borderStr,
        filled: ${tk.inputStyle == 'filled'},
        fillColor: AppColors.primary.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  static CardTheme get cardTheme => CardTheme(
        color: AppColors.card,
        elevation: ${tk.cardStyle == 'elevated'} ? AppElevation.low : AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: ${tk.cardStyle == 'outlined'}
              ? const BorderSide(color: AppColors.primary)
              : BorderSide.none,
        ),
      );

  static DialogTheme get dialogTheme => DialogTheme(
        backgroundColor: AppColors.card,
        elevation: ${tk.dialogStyle == 'elevated'} ? AppElevation.high : AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: ${tk.dialogStyle == 'outlined'}
              ? const BorderSide(color: AppColors.primary)
              : BorderSide.none,
        ),
      );

  static DrawerThemeData get drawerTheme => DrawerThemeData(
        backgroundColor: AppColors.card,
        elevation: ${tk.drawerStyle == 'floating'} ? AppElevation.low : AppElevation.none,
      );

  static BottomSheetThemeData get bottomSheetTheme => BottomSheetThemeData(
        backgroundColor: AppColors.card,
        elevation: ${tk.bottomSheetStyle == 'elevated'} ? AppElevation.medium : AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusLg),
            topRight: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      );

  static TabBarTheme get tabBarTheme => const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
      );

  static NavigationBarThemeData get navigationBarTheme => NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withOpacity(0.2),
      );

  static ListTileThemeData get listTileTheme => const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.primary,
      );
}''';
  }

  static String generateAppTheme(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'component_themes.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData get themeData {
    final brightness = ${tk.isDarkMode} ? Brightness.dark : Brightness.light;
    return ThemeData(
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        bodySmall: AppTypography.bodySm,
        bodyMedium: AppTypography.bodyMd,
        bodyLarge: AppTypography.bodyLg,
        titleLarge: AppTypography.titleXl,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ComponentThemes.elevatedButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: ComponentThemes.outlinedButtonStyle),
      inputDecorationTheme: ComponentThemes.inputDecorationTheme,
      dialogTheme: ComponentThemes.dialogTheme,
      drawerTheme: ComponentThemes.drawerTheme,
      bottomSheetTheme: ComponentThemes.bottomSheetTheme,
      tabBarTheme: ComponentThemes.tabBarTheme,
      navigationBarTheme: ComponentThemes.navigationBarTheme,
      listTileTheme: ComponentThemes.listTileTheme,
      cardTheme: ComponentThemes.cardTheme,
      extensions: [
        RevoThemeExtension(
          cardShadow: AppThemeShadows.cardShadow,
          gradient: AppColors.hasGradient ? AppColors.gradient : null,
          dataGridStyle: '${tk.dataGridStyle}',
          calendarStyle: '${tk.calendarStyle}',
          treeViewStyle: '${tk.treeViewStyle}',
          chartsStyle: '${tk.chartsStyle}',
          timelineStyle: '${tk.timelineStyle}',
          kanbanStyle: '${tk.kanbanStyle}',
        ),
      ],
    );
  }
}''';
  }

  static String generateThemeExtensions(ThemeTokens tk) {
    return '''import 'package:flutter/material.dart';

class RevoThemeExtension extends ThemeExtension<RevoThemeExtension> {
  final List<BoxShadow>? cardShadow;
  final LinearGradient? gradient;
  final String dataGridStyle;
  final String calendarStyle;
  final String treeViewStyle;
  final String chartsStyle;
  final String timelineStyle;
  final String kanbanStyle;

  RevoThemeExtension({
    this.cardShadow,
    this.gradient,
    this.dataGridStyle = 'compact',
    this.calendarStyle = 'minimalist',
    this.treeViewStyle = 'tree-lines',
    this.chartsStyle = 'solid',
    this.timelineStyle = 'left-align',
    this.kanbanStyle = 'board-flat',
  });

  @override
  RevoThemeExtension copyWith({
    List<BoxShadow>? cardShadow,
    LinearGradient? gradient,
    String? dataGridStyle,
    String? calendarStyle,
    String? treeViewStyle,
    String? chartsStyle,
    String? timelineStyle,
    String? kanbanStyle,
  }) {
    return RevoThemeExtension(
      cardShadow: cardShadow ?? this.cardShadow,
      gradient: gradient ?? this.gradient,
      dataGridStyle: dataGridStyle ?? this.dataGridStyle,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      treeViewStyle: treeViewStyle ?? this.treeViewStyle,
      chartsStyle: chartsStyle ?? this.chartsStyle,
      timelineStyle: timelineStyle ?? this.timelineStyle,
      kanbanStyle: kanbanStyle ?? this.kanbanStyle,
    );
  }

  @override
  RevoThemeExtension lerp(ThemeExtension<RevoThemeExtension>? other, double t) {
    if (other is! RevoThemeExtension) return this;
    return RevoThemeExtension(
      cardShadow: cardShadow,
      gradient: gradient,
      dataGridStyle: other.dataGridStyle,
      calendarStyle: other.calendarStyle,
      treeViewStyle: other.treeViewStyle,
      chartsStyle: other.chartsStyle,
      timelineStyle: other.timelineStyle,
      kanbanStyle: other.kanbanStyle,
    );
  }
}

class AppThemeShadows {
  static final cardShadow = [
    BoxShadow(
      color: const Color(0xFF${tk.shadowColor.replaceAll('#', '')}).withOpacity(0.15),
      blurRadius: ${tk.shadowBlurRadius},
      spreadRadius: ${tk.shadowSpreadRadius},
      offset: const Offset(${tk.shadowOffsetX}, ${tk.shadowOffsetY}),
    ),
  ];
}''';
  }

  static String generateAppTokens(ThemeTokens tk) {
    return '''export 'app_colors.dart';
export 'app_typography.dart';
export 'app_spacing.dart';
export 'app_dimensions.dart';
export 'app_elevation.dart';
export 'app_breakpoints.dart';
export 'app_animations.dart';
export 'app_icons.dart';
export 'component_themes.dart';
export 'theme_extensions.dart';
export 'app_theme.dart';
export 'theme_metadata.dart';
''';
  }

  static String generateThemeMetadata(ThemeTokens tk) {
    return '''class ThemeMetadata {
  static const name = "${tk.themeName}";
  static const version = "${tk.themeVersion}";
  static const author = "${tk.themeAuthor}";
  static const isDarkMode = ${tk.isDarkMode};
}''';
  }

  static String generateThemeJson(ThemeTokens tk) {
    return const JsonEncoder.withIndent('  ').convert(tk.toJson());
  }

  static String generateReadme(ThemeTokens tk) {
    return '''# Revochamp Theme Package - ${tk.themeName}

Generated by Revochamp Enterprise Edition Theme Studio.

## Package Contents
This theme package contains the following design tokens and theme classes:
* `app_tokens.dart` - Single export entry point to import all design assets.
* `app_colors.dart` - Brand color specifications (Primary, Secondary, Custom Gradients).
* `app_typography.dart` - Type styles maps powered by Google Fonts.
* `app_spacing.dart` - Radius, margins, and padding spacing scales.
* `app_dimensions.dart` - Structural interface layout sizes.
* `app_elevation.dart` - Global shadow offsets and elevation tokens.
* `app_breakpoints.dart` - Device responsive thresholds.
* `app_animations.dart` - Easing duration values.
* `app_icons.dart` - Standardized icon dimension metrics.
* `component_themes.dart` - Reusable styling rules for 20 customized widget components.
* `theme_extensions.dart` - Shadow details and custom decorators.
* `app_theme.dart` - Unified ThemeData wrapper combining all tokens.
* `theme_metadata.dart` - Versioning meta credentials.
* `theme.json` - Serialized configuration file.

## Integration Guide

1. Drop the generated directory under your Flutter project (e.g. `lib/theme/`).
2. Verify package dependencies in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     google_fonts: ^6.2.1
   ```
3. Import the unified tokens file:
   ```dart
   import 'package:your_app/theme/app_tokens.dart';
   ```
4. Attach `AppTheme.themeData` to your root application widget:
   ```dart
   MaterialApp(
     theme: AppTheme.themeData,
     ...
   )
   ```
''';
  }

  static Map<String, String> generateThemePackage(ThemeTokens tk) {
    return {
      'app_colors.dart': generateAppColors(tk),
      'app_typography.dart': generateAppTypography(tk),
      'app_spacing.dart': generateAppSpacing(tk),
      'app_dimensions.dart': generateAppDimensions(tk),
      'app_elevation.dart': generateAppElevation(tk),
      'app_breakpoints.dart': generateAppBreakpoints(tk),
      'app_animations.dart': generateAppAnimations(tk),
      'app_icons.dart': generateAppIcons(tk),
      'component_themes.dart': generateComponentThemes(tk),
      'theme_extensions.dart': generateThemeExtensions(tk),
      'app_theme.dart': generateAppTheme(tk),
      'app_tokens.dart': generateAppTokens(tk),
      'theme_metadata.dart': generateThemeMetadata(tk),
      'theme.json': generateThemeJson(tk),
      'README.md': generateReadme(tk),
    };
  }
}
