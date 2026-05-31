import 'package:flutter/material.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import 'component_renderer.dart';

class ComponentRendererInputs {
  static Widget buildInput(ComponentNode node, RenderContext ctx) {
    final properties = node.properties;
    final isDesignMode = ctx.isDesignMode;
    final formValues = ctx.formValues;
    final onFormValueChanged = ctx.onFormValueChanged;
    final themeTokens = ctx.themeTokens;

    switch (node.type) {
      case 'TextField':
        final fieldName = properties['fieldName'] ?? 'text_field';
        final label = properties['label'] ?? 'Label';
        final hint = properties['hint'] ?? '';
        final isRequired = properties['required'] == true;
        final isPassword = properties['obscureText'] == true;
        final isEnabled = properties['enabled'] != false;
        final isReadOnly = properties['readOnly'] == true;

        final currentValue = formValues[fieldName]?.toString() ?? '';
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor')) ??
            (isEnabled ? Colors.white : Colors.grey[200]);
        final radius =
            double.tryParse(ComponentRenderer.getStyle(node, 'borderRadius')?.toString() ?? '') ??
            themeTokens?.borderRadius ?? 4.0;
        final inputStyle = themeTokens?.inputStyle ?? 'outline';

        return TextFormField(
          initialValue: isDesignMode ? null : currentValue,
          key: isDesignMode ? null : ValueKey('$fieldName-$currentValue'),
          enabled: isEnabled,
          readOnly: isReadOnly,
          obscureText: isPassword,
          onChanged: (val) {
            if (onFormValueChanged != null) onFormValueChanged(fieldName, val);
          },
          decoration: InputDecoration(
            labelText: label + (isRequired ? ' *' : ''),
            hintText: hint,
            border: inputStyle == 'underline'
                ? const UnderlineInputBorder()
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
            filled: inputStyle == 'filled' || bg != null,
            fillColor: bg,
          ),
        );

      case 'Dropdown':
        final fieldName = properties['fieldName'] ?? 'dropdown';
        final label = properties['label'] ?? 'Dropdown Option';
        final hint = properties['hint'] ?? 'Select option';
        final isRequired = properties['required'] == true;
        
        final rawOptions = properties['options'] ?? [];
        final List<String> options = [];
        if (rawOptions is List) {
          for (final opt in rawOptions) {
            if (opt is Map) {
              options.add(opt['label']?.toString() ?? opt['value']?.toString() ?? 'Option');
            } else if (opt != null) {
              options.add(opt.toString());
            }
          }
        }

        final currentValue = formValues[fieldName]?.toString();
        final selectedVal =
            (currentValue != null && options.contains(currentValue))
            ? currentValue
            : null;

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label + (isRequired ? ' *' : ''),
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          value: selectedVal,
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: isDesignMode
              ? null
              : (val) {
                  if (onFormValueChanged != null) {
                    onFormValueChanged(fieldName, val);
                  }
                },
        );

      case 'Radio':
        final fieldName = properties['fieldName'] ?? 'radio';
        final label = properties['label'] ?? 'Select Value';
        final rawOptions = properties['options'] ?? [];
        final List<String> options = [];
        if (rawOptions is List) {
          for (final opt in rawOptions) {
            if (opt is Map) {
              options.add(opt['label']?.toString() ?? opt['value']?.toString() ?? 'Option');
            } else if (opt != null) {
              options.add(opt.toString());
            }
          }
        }
        final currentValue = formValues[fieldName]?.toString() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            ...options.map((opt) {
              return RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: currentValue,
                onChanged: isDesignMode
                    ? null
                    : (val) {
                        if (onFormValueChanged != null) {
                          onFormValueChanged(fieldName, val);
                        }
                      },
              );
            }),
          ],
        );

      case 'Checkbox':
        final fieldName = properties['fieldName'] ?? 'checkbox';
        final label = properties['label'] ?? 'Check details';
        final isChecked =
            formValues[fieldName] == true ||
            formValues[fieldName]?.toString().toLowerCase() == 'true';

        return CheckboxListTile(
          title: Text(label),
          value: isChecked,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: isDesignMode
              ? null
              : (val) {
                  if (onFormValueChanged != null) {
                    onFormValueChanged(fieldName, val);
                  }
                },
        );

      case 'DatePicker':
        final fieldName = properties['fieldName'] ?? 'datepicker';
        final label = properties['label'] ?? 'Select Date';
        final hint = properties['hint'] ?? 'DD/MM/YYYY';
        final val = formValues[fieldName]?.toString() ?? '';

        return InkWell(
          onTap: isDesignMode
              ? null
              : () async {
                  if (onFormValueChanged != null) {
                    onFormValueChanged(fieldName, '29/05/2026');
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              val.isNotEmpty ? val : hint,
              style: TextStyle(
                color: val.isNotEmpty ? Colors.black : Colors.grey,
              ),
            ),
          ),
        );

      case 'Switch':
        final fieldName = properties['fieldName'] ?? 'switch';
        final label = properties['label'] ?? 'Enable Option';
        final isSwitched =
            formValues[fieldName] == true ||
            formValues[fieldName]?.toString().toLowerCase() == 'true';

        return SwitchListTile(
          title: Text(label),
          value: isSwitched,
          onChanged: isDesignMode
              ? null
              : (val) {
                  if (onFormValueChanged != null) {
                    onFormValueChanged(fieldName, val);
                  }
                },
        );

      case 'Slider':
        final fieldName = properties['fieldName'] ?? 'slider';
        final label = properties['label'] ?? 'Value Slider';
        final min =
            double.tryParse(properties['min']?.toString() ?? '0.0') ?? 0.0;
        final max =
            double.tryParse(properties['max']?.toString() ?? '100.0') ?? 100.0;
        final val =
            double.tryParse(formValues[fieldName]?.toString() ?? '0.0') ?? min;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${val.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Slider(
              min: min,
              max: max,
              value: val.clamp(min, max),
              onChanged: isDesignMode
                  ? null
                  : (newVal) {
                      if (onFormValueChanged != null) {
                        onFormValueChanged(fieldName, newVal);
                      }
                    },
            ),
          ],
        );

      case 'FilePicker':
        final fieldName = properties['fieldName'] ?? 'file';
        final label = properties['label'] ?? 'Select File';
        final val = formValues[fieldName]?.toString() ?? '';
        return InkWell(
          onTap: isDesignMode ? null : () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    val.isNotEmpty ? val : label,
                    style: TextStyle(
                      color: val.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDesignMode ? () {} : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FCF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Browse', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );

      case 'OTP':
        final label = properties['label'] ?? 'Enter OTP';
        final length =
            int.tryParse(properties['length']?.toString() ?? '6') ?? 6;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(length, (i) {
                return Container(
                  width: 40,
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF5B4FCF)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );

      case 'Search':
        final label = properties['label'] ?? 'Search';
        final hint = properties['hint'] ?? 'Type keywords...';
        return TextField(
          enabled: !isDesignMode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24.0)),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
