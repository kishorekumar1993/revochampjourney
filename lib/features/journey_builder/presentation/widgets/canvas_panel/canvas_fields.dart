import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';


class CanvasDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final String fallback;
  final ValueChanged<String> onChanged;

  const CanvasDropdownField({super.key, 
    required this.label,
    required this.value,
    required this.items,
    required this.fallback,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final list = ["", ...items];
    final current = list.contains(value) ? value : "";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: RevoTheme.cardBg,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textPrimary),
              icon: Icon(Icons.arrow_drop_down, color: RevoTheme.textSecondary, size: 18),
              items: list.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item.isEmpty ? fallback : item),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}


class CanvasTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const CanvasTextField({super.key, 
    required this.label,
    required this.initialValue,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<CanvasTextField> createState() => CanvasTextFieldState();
}


class CanvasTextFieldState extends State<CanvasTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant CanvasTextField oldWidget) {
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
        Text(widget.label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary.withValues(alpha:0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: RevoTheme.cardBg,
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

