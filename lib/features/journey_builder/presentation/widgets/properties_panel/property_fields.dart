import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';


class PropertyTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const PropertyTextField({super.key, 
    required this.label,
    required this.initialValue,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<PropertyTextField> createState() => PropertyTextFieldState();
}


class PropertyTextFieldState extends State<PropertyTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      final selection = _controller.selection;
      _controller.text = widget.initialValue;
      try {
        _controller.selection = selection;
      } catch (_) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: RevoTheme.background,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: RevoTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: RevoTheme.primaryLight, width: 1.5),
            ),
          ),
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textPrimary),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}


class PropertyDropdownField extends StatelessWidget {
  final String label;
  final String currentValue;
  final List<String> items;
  final ValueChanged<String>? onChanged;

  const PropertyDropdownField({super.key, 
    required this.label,
    required this.currentValue,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: RevoTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(currentValue) ? currentValue : items.first,
              isExpanded: true,
              dropdownColor: RevoTheme.cardBg,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: RevoTheme.textSecondary, size: 18),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && onChanged != null) {
                  onChanged!(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CollapsibleSection extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? accentColor.withValues(alpha: 0.2) : RevoTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: isExpanded ? accentColor : RevoTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? accentColor : RevoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    color: isExpanded ? accentColor : RevoTheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: RevoTheme.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CompactSwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CompactSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: 20,
            child: FittedBox(
              child: Switch(
                value: value,
                activeTrackColor: RevoTheme.primaryLight.withValues(alpha: 0.5),
                activeThumbColor: RevoTheme.primaryLight,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

