import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import 'component_renderer.dart';

class ComponentRendererBasic {
  static Widget buildBasic(ComponentNode node, RenderContext ctx) {
    final properties = node.properties;
    final isDesignMode = ctx.isDesignMode;
    final themeTokens = ctx.themeTokens;

    switch (node.type) {
      case 'Button':
        final text = properties['label'] ?? 'Click Me';
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor', ctx)) ??
            PropertyParser.parseColor(themeTokens?.primaryColor) ??
            const Color(0xFF5B4FCF);
        final fg =
            PropertyParser.parseColor(
              ComponentRenderer.getStyle(node, 'textColor', ctx) ?? ComponentRenderer.getStyle(node, 'color', ctx),
            ) ??
            PropertyParser.parseColor(themeTokens?.secondaryColor) ??
            Colors.white;
        final radius = PropertyParser.parseDouble(
          ComponentRenderer.getStyle(node, 'borderRadius', ctx),
          themeTokens?.borderRadius ?? 8.0,
        );
        final btnWidth = PropertyParser.tryParseDouble(ComponentRenderer.getStyle(node, 'width', ctx));
        final btnHeight = PropertyParser.tryParseDouble(ComponentRenderer.getStyle(node, 'height', ctx));
        final btnFontSize = PropertyParser.parseDouble(
          ComponentRenderer.getStyle(node, 'fontSize', ctx),
          14.0,
        );
        final iconStr = properties['icon']?.toString();

        Widget btnChild = iconStr != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ComponentRenderer.getIconByName(iconStr), size: 16, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: btnFontSize,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: btnFontSize,
                ),
              );

        Widget btn = ElevatedButton(
          onPressed: isDesignMode ? () {} : () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            fixedSize: (btnWidth != null && btnHeight != null)
                ? Size(btnWidth, btnHeight)
                : btnWidth != null
                ? Size.fromWidth(btnWidth)
                : btnHeight != null
                ? Size.fromHeight(btnHeight)
                : null,
          ),
          child: btnChild,
        );
        return btn;

      case 'IconButton':
        final iconStr = properties['icon'] ?? 'star';
        final col =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'color', ctx)) ??
            const Color(0xFF5B4FCF);
        return IconButton(
          icon: Icon(ComponentRenderer.getIconByName(iconStr)),
          color: col,
          onPressed: () {},
        );

      case 'FloatingButton':
        final iconStr = properties['icon'] ?? 'add';
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor', ctx)) ??
            const Color(0xFF5B4FCF);
        final fg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'textColor', ctx)) ?? Colors.white;

        return FloatingActionButton(
          onPressed: () {},
          backgroundColor: bg,
          foregroundColor: fg,
          child: Icon(ComponentRenderer.getIconByName(iconStr)),
        );

      case 'Text':
        final text =
            properties['label'] ??
            properties['text'] ??
            node.bindings['label']?.toString() ??
            'Sample Text';
        final size = PropertyParser.parseDouble(ComponentRenderer.getStyle(node, 'fontSize', ctx), 14.0);
        final weight = PropertyParser.parseFontWeight(ComponentRenderer.getStyle(node, 'fontWeight', ctx));
        final fontStyle = PropertyParser.parseFontStyle(ComponentRenderer.getStyle(node, 'fontStyle', ctx));
        final col =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'color', ctx)) ??
            PropertyParser.parseColor(themeTokens?.textPrimaryColor) ??
            const Color(0xFF1A1A2E);
        final textAlign = PropertyParser.parseTextAlign(ComponentRenderer.getStyle(node, 'textAlign', ctx));
        final maxLines = int.tryParse(ComponentRenderer.getStyle(node, 'maxLines', ctx)?.toString() ?? '');
        final overflow = maxLines != null
            ? PropertyParser.parseTextOverflow(
                ComponentRenderer.getStyle(node, 'overflow', ctx) ?? 'ellipsis',
              )
            : null;
        final letterSpacing = PropertyParser.tryParseDouble(
          ComponentRenderer.getStyle(node, 'letterSpacing', ctx),
        );
        final lineHeight = PropertyParser.tryParseDouble(
          ComponentRenderer.getStyle(node, 'lineHeight', ctx),
        );
        final decoration = PropertyParser.parseTextDecoration(
          ComponentRenderer.getStyle(node, 'textDecoration', ctx),
        );

        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: GoogleFonts.getFont(
            themeTokens?.fontFamily ?? 'Outfit',
            textStyle: TextStyle(
              fontSize: size,
              fontWeight: weight,
              fontStyle: fontStyle,
              color: col,
              letterSpacing: letterSpacing,
              height: lineHeight,
              decoration: decoration,
            ),
          ),
        );

      case 'Image':
        final src =
            ComponentRenderer.getStyle(node, 'src', ctx) ??
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500';
        final width = PropertyParser.tryParseDouble(ComponentRenderer.getStyle(node, 'width', ctx));
        final height = PropertyParser.tryParseDouble(
          ComponentRenderer.getStyle(node, 'height', ctx) ?? '200.0',
        );
        final fit = PropertyParser.parseBoxFit(ComponentRenderer.getStyle(node, 'fit', ctx));
        final radius =
            PropertyParser.tryParseDouble(ComponentRenderer.getStyle(node, 'borderRadius', ctx)) ?? 8.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            src,
            width: width ?? double.infinity,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) {
              return Container(
                width: width ?? double.infinity,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );

      case 'Icon':
        final iconStr = properties['icon'] ?? 'info';
        final size =
            PropertyParser.tryParseDouble(
              ComponentRenderer.getStyle(node, 'size', ctx) ?? ComponentRenderer.getStyle(node, 'fontSize', ctx),
            ) ?? 24.0;
        final col =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'color', ctx)) ??
            const Color(0xFF1A1A2E);
        return Icon(ComponentRenderer.getIconByName(iconStr), size: size, color: col);

      case 'Divider':
        final height =
            PropertyParser.tryParseDouble(ComponentRenderer.getStyle(node, 'height', ctx)) ?? 1.0;
        final color = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'color', ctx));
        return Divider(height: height * 4, thickness: height, color: color);

      case 'Avatar':
        final src =
            properties['src'] ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
        final radius =
            PropertyParser.tryParseDouble(properties['radius']?.toString()) ?? 24.0;
        return CircleAvatar(radius: radius, backgroundImage: NetworkImage(src));

      case 'Chip':
        final label = properties['label'] ?? 'Tag';
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor', ctx)) ??
            const Color(0xFFE8E7FD);
        final fg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'textColor', ctx)) ??
            const Color(0xFF5B4FCF);
        return Chip(
          label: Text(label, style: TextStyle(color: fg, fontSize: 12)),
          backgroundColor: bg,
          padding: const EdgeInsets.all(4),
        );

      case 'Badge':
        final label = properties['label'] ?? 'New';
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor', ctx)) ??
            const Color(0xFFFF3B30);
        final fg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'textColor', ctx)) ?? Colors.white;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case 'Progress':
        final col =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'color', ctx)) ??
            const Color(0xFF5B4FCF);
        final isCircular = properties['isCircular'] != false;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: isCircular
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                )
              : LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
