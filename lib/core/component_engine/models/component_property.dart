import 'package:flutter/material.dart';

class ComponentPropertyKeys {
  // General keys
  static const String label = 'label';
  static const String hint = 'hint';
  static const String fieldName = 'fieldName';
  static const String defaultValue = 'defaultValue';
  static const String enabled = 'enabled';
  static const String readOnly = 'readOnly';

  // Style keys
  static const String color = 'color';
  static const String backgroundColor = 'backgroundColor';
  static const String fontSize = 'fontSize';
  static const String fontWeight = 'fontWeight'; // normal, bold, w100-w900
  static const String padding = 'padding'; // double or map
  static const String margin = 'margin'; // double or map
  static const String borderRadius = 'borderRadius';
  static const String width = 'width';
  static const String height = 'height';
  static const String elevation = 'elevation';
  static const String icon = 'icon';
  static const String src = 'src'; // image source
  static const String fit = 'fit'; // image fit

  // Layout keys
  static const String alignment = 'alignment'; // center, start, end
  static const String mainAxisAlignment = 'mainAxisAlignment';
  static const String crossAxisAlignment = 'crossAxisAlignment';
  static const String spacing = 'spacing';
  static const String runSpacing = 'runSpacing';
  static const String flex = 'flex';

  // Validation keys
  static const String required = 'required';
  static const String regexPattern = 'regexPattern';
  static const String minLength = 'minLength';
  static const String maxLength = 'maxLength';
  static const String errorMessage = 'errorMessage';

  // API keys
  static const String apiUrl = 'apiUrl';
  static const String apiMethod = 'apiMethod';
  static const String apiHeaders = 'apiHeaders';
  static const String apiBody = 'apiBody';
  static const String labelKey = 'labelKey';
  static const String valueKey = 'valueKey';
  static const String responseListKey = 'responseListKey';
}

class PropertyParser {
  static double parseDouble(dynamic val, [double defaultValue = 0.0]) {
    if (val == null) return defaultValue;
    return double.tryParse(val.toString()) ?? defaultValue;
  }

  static EdgeInsetsGeometry parsePadding(dynamic val) {
    if (val == null) return EdgeInsets.zero;
    if (val is num) {
      final d = val.toDouble();
      return EdgeInsets.all(d < 0.0 ? 0.0 : d);
    }
    if (val is Map) {
      final left = double.tryParse(val['left']?.toString() ?? '0') ?? 0.0;
      final top = double.tryParse(val['top']?.toString() ?? '0') ?? 0.0;
      final right = double.tryParse(val['right']?.toString() ?? '0') ?? 0.0;
      final bottom = double.tryParse(val['bottom']?.toString() ?? '0') ?? 0.0;
      return EdgeInsets.fromLTRB(
        left < 0.0 ? 0.0 : left,
        top < 0.0 ? 0.0 : top,
        right < 0.0 ? 0.0 : right,
        bottom < 0.0 ? 0.0 : bottom,
      );
    }
    return EdgeInsets.zero;
  }

  static Color? parseColor(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim().replaceAll('#', '');
    if (str.isEmpty) return null;
    try {
      if (str.length == 6) {
        return Color(int.parse('FF$str', radix: 16));
      } else if (str.length == 8) {
        return Color(int.parse(str, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  static FontWeight parseFontWeight(dynamic val) {
    if (val == null) return FontWeight.normal;
    final str = val.toString().toLowerCase();
    switch (str) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  static MainAxisAlignment parseMainAxisAlignment(dynamic val) {
    if (val == null) return MainAxisAlignment.start;
    final str = val.toString().toLowerCase();
    switch (str) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spacebetween':
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment parseCrossAxisAlignment(dynamic val) {
    if (val == null) return CrossAxisAlignment.center;
    final str = val.toString().toLowerCase();
    switch (str) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  static BoxFit parseBoxFit(dynamic val) {
    if (val == null) return BoxFit.cover;
    final str = val.toString().toLowerCase();
    switch (str) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'fitwidth':
      case 'fit_width':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fit_height':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
      case 'scale_down':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }

  static TextAlign parseTextAlign(dynamic val) {
    switch (val?.toString().toLowerCase()) {
      case 'left': return TextAlign.left;
      case 'right': return TextAlign.right;
      case 'center': return TextAlign.center;
      case 'justify': return TextAlign.justify;
      default: return TextAlign.start;
    }
  }

  static TextOverflow parseTextOverflow(dynamic val) {
    switch (val?.toString().toLowerCase()) {
      case 'clip': return TextOverflow.clip;
      case 'fade': return TextOverflow.fade;
      case 'ellipsis': return TextOverflow.ellipsis;
      case 'visible': return TextOverflow.visible;
      default: return TextOverflow.clip;
    }
  }

  static FontStyle parseFontStyle(dynamic val) {
    return val?.toString().toLowerCase() == 'italic' ? FontStyle.italic : FontStyle.normal;
  }

  static AlignmentGeometry parseAlignment(dynamic val) {
    switch (val?.toString().toLowerCase()) {
      case 'center': return Alignment.center;
      case 'topleft': return Alignment.topLeft;
      case 'topcenter': return Alignment.topCenter;
      case 'topright': return Alignment.topRight;
      case 'bottomleft': return Alignment.bottomLeft;
      case 'bottomcenter': return Alignment.bottomCenter;
      case 'bottomright': return Alignment.bottomRight;
      default: return Alignment.center;
    }
  }

  static BoxShadow parseBoxShadow(dynamic val) {
    if (val is! Map) return const BoxShadow();
    return BoxShadow(
      color: parseColor(val['color']) ?? Colors.black.withValues(alpha: 0.1),
      offset: Offset(parseDouble(val['dx']), parseDouble(val['dy'])),
      blurRadius: parseDouble(val['blur']),
    );
  }

  static BoxBorder parseBorder(dynamic val) {
    if (val is! Map) return Border.all(width: 0, color: Colors.transparent);
    return Border.all(
      color: parseColor(val['color']) ?? Colors.black,
      width: parseDouble(val['width'], 1.0),
    );
  }

  static MainAxisSize parseMainAxisSize(dynamic val) {
    if (val == null) return MainAxisSize.max;
    final str = val.toString().toLowerCase();
    if (str == 'min') return MainAxisSize.min;
    return MainAxisSize.max;
  }

  static TextDecoration parseTextDecoration(dynamic val) {
    if (val == null) return TextDecoration.none;
    final str = val.toString().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (str) {
      case 'underline': return TextDecoration.underline;
      case 'overline': return TextDecoration.overline;
      case 'linethrough': return TextDecoration.lineThrough;
      default: return TextDecoration.none;
    }
  }
}
