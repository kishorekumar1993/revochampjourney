import 'package:flutter/material.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import '../registry/component_registry.dart';

class ComponentRenderer {
  static Widget render(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode)? onSelect,
    void Function(ComponentNode)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild, // (parent, child, index)
    void Function(ComponentNode, String)? onAddChild, // (parent, type)
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
  }) {
    if (node.type == 'Expanded') {
      Widget childWidget;
      if (node.children.isEmpty) {
        childWidget = isDesignMode
            ? GestureDetector(
                onTap: () {
                  if (onSelect != null) onSelect(node);
                },
                child: _buildEmptyPlaceholder(node, onAddChild: onAddChild),
              )
            : const SizedBox.shrink();
      } else {
        childWidget = render(
          node.children.first,
          isDesignMode: isDesignMode,
          selectedNode: selectedNode,
          hoveredNode: hoveredNode,
          onSelect: onSelect,
          onHover: onHover,
          onDelete: onDelete,
          onDuplicate: onDuplicate,
          onMoveChild: onMoveChild,
          onAddChild: onAddChild,
          formValues: formValues,
          onFormValueChanged: onFormValueChanged,
        );
      }
      return Expanded(child: childWidget);
    }

    if (node.type == 'Flexible') {
      Widget childWidget;
      if (node.children.isEmpty) {
        childWidget = isDesignMode
            ? GestureDetector(
                onTap: () {
                  if (onSelect != null) onSelect(node);
                },
                child: _buildEmptyPlaceholder(node, onAddChild: onAddChild),
              )
            : const SizedBox.shrink();
      } else {
        childWidget = render(
          node.children.first,
          isDesignMode: isDesignMode,
          selectedNode: selectedNode,
          hoveredNode: hoveredNode,
          onSelect: onSelect,
          onHover: onHover,
          onDelete: onDelete,
          onDuplicate: onDuplicate,
          onMoveChild: onMoveChild,
          onAddChild: onAddChild,
          formValues: formValues,
          onFormValueChanged: onFormValueChanged,
        );
      }
      return Flexible(child: childWidget);
    }

    // 1. Render the actual core widget
    Widget coreWidget = _buildWidget(
      node,
      isDesignMode: isDesignMode,
      selectedNode: selectedNode,
      hoveredNode: hoveredNode,
      onSelect: onSelect,
      onHover: onHover,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onMoveChild: onMoveChild,
      onAddChild: onAddChild,
      formValues: formValues,
      onFormValueChanged: onFormValueChanged,
    );

    // 2. If Design Mode, wrap with interaction overlays (selection border, hover border, drag/drop wrappers)
    if (isDesignMode) {
      final isSelected = selectedNode?.id == node.id;
      final isHovered = hoveredNode?.id == node.id;

      // Handle drop targeting for container types
      final canAcceptChildren = _canAcceptChildren(node.type);

      Widget interactiveWrapper = MouseRegion(
        onEnter: (_) {
          if (onHover != null) onHover(node);
        },
        onExit: (_) {
          if (onHover != null && hoveredNode?.id == node.id) {
            onHover(null as dynamic); // clear hover
          }
        },
        child: GestureDetector(
          onTap: () {
            if (onSelect != null) {
              onSelect(node);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5B4FCF)
                        : isHovered
                            ? const Color(0xFF9E95F5)
                            : Colors.transparent,
                    width: isSelected ? 2.0 : 1.5,
                  ),
                ),
                child: coreWidget,
              ),
              // Render labels and actions on top of selected node
              if (isSelected)
                Positioned(
                  top: -24,
                  left: 0,
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B4FCF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          node.type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (onDuplicate != null) onDuplicate(node);
                          },
                          child: const Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            if (onDelete != null) onDelete(node);
                          },
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      // Drag source
      Widget dragSource = Draggable<ComponentNode>(
        data: node,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B4FCF).withValues(alpha:0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              node.type,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: interactiveWrapper,
        ),
        child: interactiveWrapper,
      );

      // If it is a container, wrap it with DragTarget to support dropping items into it
      if (canAcceptChildren) {
        return DragTarget<Object>(
          onWillAcceptWithDetails: (details) {
            // details.data can be a String (from palette) or a ComponentNode (moving inside canvas)
            return true;
          },
          onAcceptWithDetails: (details) {
            final data = details.data;
            if (data is String) {
              // dropped from palette
              if (onAddChild != null) onAddChild(node, data);
            } else if (data is ComponentNode) {
              // moved inside canvas
              if (onMoveChild != null && data.id != node.id) {
                onMoveChild(node, data, node.children.length);
              }
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isOver = candidateData.isNotEmpty;
            return Container(
              color: isOver ? const Color(0x155B4FCF) : Colors.transparent,
              child: dragSource,
            );
          },
        );
      }

      return dragSource;
    }

    return coreWidget;
  }

  static Widget _buildWidget(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode)? onSelect,
    void Function(ComponentNode)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild,
    void Function(ComponentNode, String)? onAddChild,
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
  }) {
    final properties = node.properties;
    final styles = node.styles;

    dynamic getStyle(String key) {
      if (node.styles.containsKey(key)) return node.styles[key];
      return node.properties[key];
    }

    // Helper to render children
    List<Widget> renderChildren() {
      if (node.children.isEmpty && isDesignMode) {
        return [
          _buildEmptyPlaceholder(node, onAddChild: onAddChild),
        ];
      }
      return node.children
          .map((child) => render(
                child,
                isDesignMode: isDesignMode,
                selectedNode: selectedNode,
                hoveredNode: hoveredNode,
                onSelect: onSelect,
                onHover: onHover,
                onDelete: onDelete,
                onDuplicate: onDuplicate,
                onMoveChild: onMoveChild,
                onAddChild: onAddChild,
                formValues: formValues,
                onFormValueChanged: onFormValueChanged,
              ))
          .toList();
    }

    switch (node.type) {
      // ================== LAYOUTS ==================
      case 'Container':
        final width = double.tryParse(getStyle('width')?.toString() ?? '');
        final height = double.tryParse(getStyle('height')?.toString() ?? '');
        final bg = PropertyParser.parseColor(getStyle('backgroundColor'));
        final pad = PropertyParser.parsePadding(getStyle('padding'));
        final marg = PropertyParser.parsePadding(getStyle('margin'));
        final radius = double.tryParse(getStyle('borderRadius')?.toString() ?? '') ?? 0.0;
        final gradientStart = PropertyParser.parseColor(getStyle('gradientStart'));
        final gradientEnd = PropertyParser.parseColor(getStyle('gradientEnd'));
        final borderColor = PropertyParser.parseColor(getStyle('borderColor'));
        final borderWidth = double.tryParse(getStyle('borderWidth')?.toString() ?? '') ?? 1.0;
        final elevation = double.tryParse(getStyle('elevation')?.toString() ?? '') ?? 0.0;

        Gradient? gradient;
        if (gradientStart != null && gradientEnd != null) {
          gradient = LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }

        BoxBorder? border;
        if (borderColor != null) {
          border = Border.all(color: borderColor, width: borderWidth);
        }

        List<BoxShadow>? boxShadows;
        if (elevation > 0) {
          boxShadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: elevation * 2,
              spreadRadius: -elevation * 0.5,
              offset: Offset(0, elevation),
            )
          ];
        }

        return Container(
          width: width,
          height: height,
          padding: pad,
          margin: marg,
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            border: border,
            boxShadow: boxShadows,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : render(
                  node.children.first,
                  isDesignMode: isDesignMode,
                  selectedNode: selectedNode,
                  hoveredNode: hoveredNode,
                  onSelect: onSelect,
                  onHover: onHover,
                  onDelete: onDelete,
                  onDuplicate: onDuplicate,
                  onMoveChild: onMoveChild,
                  onAddChild: onAddChild,
                  formValues: formValues,
                  onFormValueChanged: onFormValueChanged,
                ),
        );

      case 'Row':
        final mainAlign = PropertyParser.parseMainAxisAlignment(properties['mainAxisAlignment']);
        var crossAlign = PropertyParser.parseCrossAxisAlignment(properties['crossAxisAlignment']);
        if (crossAlign == CrossAxisAlignment.stretch) {
          crossAlign = CrossAxisAlignment.start; // Safety fallback to avoid infinite height crashes inside scroll view
        }
        if (node.children.isEmpty && isDesignMode) {
          return Row(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: crossAlign,
            children: [
              _buildEmptyPlaceholder(node, onAddChild: onAddChild),
            ],
          );
        }
        return Row(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: crossAlign,
          children: node.children.map((childNode) {
            final childWidget = render(
              childNode,
              isDesignMode: isDesignMode,
              selectedNode: selectedNode,
              hoveredNode: hoveredNode,
              onSelect: onSelect,
              onHover: onHover,
              onDelete: onDelete,
              onDuplicate: onDuplicate,
              onMoveChild: onMoveChild,
              onAddChild: onAddChild,
              formValues: formValues,
              onFormValueChanged: onFormValueChanged,
            );
            if (childNode.type == 'Expanded' || childNode.type == 'Flexible') {
              return childWidget;
            }
            return Flexible(fit: FlexFit.loose, child: childWidget);
          }).toList(),
        );

      case 'Column':
        final mainAlign = PropertyParser.parseMainAxisAlignment(properties['mainAxisAlignment']);
        final crossAlign = PropertyParser.parseCrossAxisAlignment(properties['crossAxisAlignment']);
        return Column(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: crossAlign,
          mainAxisSize: MainAxisSize.min,
          children: renderChildren(),
        );

      case 'Stack':
        return Stack(
          alignment: Alignment.topLeft,
          children: renderChildren(),
        );

      case 'Wrap':
        final spacing = double.tryParse(getStyle('spacing')?.toString() ?? '') ?? 8.0;
        final runSpacing = double.tryParse(getStyle('runSpacing')?.toString() ?? '') ?? 8.0;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: renderChildren(),
        );

      case 'GridView':
        final spacing = double.tryParse(getStyle('spacing')?.toString() ?? '') ?? 8.0;
        final runSpacing = double.tryParse(getStyle('runSpacing')?.toString() ?? '') ?? 8.0;
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: renderChildren(),
        );

      case 'ListView':
        final spacing = double.tryParse(getStyle('spacing')?.toString() ?? '') ?? 8.0;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: node.children.isEmpty ? 1 : node.children.length,
          separatorBuilder: (_, __) => SizedBox(height: spacing),
          itemBuilder: (context, index) {
            if (node.children.isEmpty) {
              return isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink();
            }
            return render(
              node.children[index],
              isDesignMode: isDesignMode,
              selectedNode: selectedNode,
              hoveredNode: hoveredNode,
              onSelect: onSelect,
              onHover: onHover,
              onDelete: onDelete,
              onDuplicate: onDuplicate,
              onMoveChild: onMoveChild,
              onAddChild: onAddChild,
              formValues: formValues,
              onFormValueChanged: onFormValueChanged,
            );
          },
        );

      case 'Card':
        final elevation = double.tryParse(getStyle('elevation')?.toString() ?? '') ?? 2.0;
        final bg = PropertyParser.parseColor(getStyle('backgroundColor'));
        final pad = PropertyParser.parsePadding(getStyle('padding'));
        final marg = PropertyParser.parsePadding(getStyle('margin'));
        final radius = double.tryParse(getStyle('borderRadius')?.toString() ?? '') ?? 12.0;
        return Card(
          elevation: elevation,
          color: bg,
          margin: marg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          child: Padding(
            padding: pad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: renderChildren(),
            ),
          ),
        );

      case 'Spacer':
        if (isDesignMode) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x0C5B4FCF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x335B4FCF)),
            ),
            child: const Center(
              child: Icon(
                Icons.space_bar_rounded,
                size: 16,
                color: Color(0xFF5B4FCF),
              ),
            ),
          );
        }
        return const Spacer();

      case 'Divider':
        final height = double.tryParse(getStyle('height')?.toString() ?? '') ?? 1.0;
        final color = PropertyParser.parseColor(getStyle('color'));
        return Divider(
          height: height * 4,
          thickness: height,
          color: color,
        );

      // ================== FORMS ==================
      case 'TextField':
        final fieldName = properties['fieldName'] ?? 'text_field';
        final label = properties['label'] ?? 'Label';
        final hint = properties['hint'] ?? '';
        final isRequired = properties['required'] == true;
        final isPassword = properties['obscureText'] == true;
        final isEnabled = properties['enabled'] != false;
        final isReadOnly = properties['readOnly'] == true;

        final currentValue = formValues[fieldName]?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
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
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: isEnabled ? Colors.white : Colors.grey[200],
            ),
          ),
        );

      case 'Dropdown':
        final fieldName = properties['fieldName'] ?? 'dropdown';
        final label = properties['label'] ?? 'Dropdown Option';
        final hint = properties['hint'] ?? 'Select option';
        final isRequired = properties['required'] == true;
        final List<String> options = List<String>.from(properties['options'] ?? []);

        final currentValue = formValues[fieldName]?.toString();
        final selectedVal = (currentValue != null && options.contains(currentValue)) ? currentValue : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: label + (isRequired ? ' *' : ''),
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            value: selectedVal,
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: isDesignMode
                ? null
                : (val) {
                    if (onFormValueChanged != null) onFormValueChanged(fieldName, val);
                  },
          ),
        );

      case 'Radio':
        final fieldName = properties['fieldName'] ?? 'radio';
        final label = properties['label'] ?? 'Select Value';
        final List<String> options = List<String>.from(properties['options'] ?? []);
        final currentValue = formValues[fieldName]?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ...options.map((opt) {
                return RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: currentValue,
                  onChanged: isDesignMode
                      ? null
                      : (val) {
                          if (onFormValueChanged != null) onFormValueChanged(fieldName, val);
                        },
                );
              }),
            ],
          ),
        );

      case 'Checkbox':
        final fieldName = properties['fieldName'] ?? 'checkbox';
        final label = properties['label'] ?? 'Check details';
        final isChecked = formValues[fieldName] == true || formValues[fieldName]?.toString().toLowerCase() == 'true';

        return CheckboxListTile(
          title: Text(label),
          value: isChecked,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: isDesignMode
              ? null
              : (val) {
                  if (onFormValueChanged != null) onFormValueChanged(fieldName, val);
                },
        );

      case 'DatePicker':
        final fieldName = properties['fieldName'] ?? 'datepicker';
        final label = properties['label'] ?? 'Select Date';
        final hint = properties['hint'] ?? 'DD/MM/YYYY';
        final val = formValues[fieldName]?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: isDesignMode
                ? null
                : () async {
                    // simulate date picker interaction
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
              child: Text(val.isNotEmpty ? val : hint, style: TextStyle(color: val.isNotEmpty ? Colors.black : Colors.grey)),
            ),
          ),
        );

      case 'Switch':
        final fieldName = properties['fieldName'] ?? 'switch';
        final label = properties['label'] ?? 'Enable Option';
        final isSwitched = formValues[fieldName] == true || formValues[fieldName]?.toString().toLowerCase() == 'true';

        return SwitchListTile(
          title: Text(label),
          value: isSwitched,
          onChanged: isDesignMode
              ? null
              : (val) {
                  if (onFormValueChanged != null) onFormValueChanged(fieldName, val);
                },
        );

      case 'Slider':
        final fieldName = properties['fieldName'] ?? 'slider';
        final label = properties['label'] ?? 'Value Slider';
        final min = double.tryParse(properties['min']?.toString() ?? '0.0') ?? 0.0;
        final max = double.tryParse(properties['max']?.toString() ?? '100.0') ?? 100.0;
        final val = double.tryParse(formValues[fieldName]?.toString() ?? '0.0') ?? min;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ${val.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Slider(
              min: min,
              max: max,
              value: val.clamp(min, max),
              onChanged: isDesignMode
                  ? null
                  : (newVal) {
                      if (onFormValueChanged != null) onFormValueChanged(fieldName, newVal);
                    },
            ),
          ],
        );

      // ================== BUTTONS ==================
      case 'Button':
        final text = properties['label'] ?? 'Click Me';
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? const Color(0xFF5B4FCF);
        final fg = PropertyParser.parseColor(getStyle('textColor')) ?? Colors.white;
        final radius = double.tryParse(getStyle('borderRadius')?.toString() ?? '') ?? 8.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
            onPressed: isDesignMode ? () {} : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Center(
              child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        );

      case 'IconButton':
        final iconStr = properties['icon'] ?? 'star';
        final col = PropertyParser.parseColor(getStyle('color')) ?? const Color(0xFF5B4FCF);
        return IconButton(
          icon: Icon(_getIconByName(iconStr)),
          color: col,
          onPressed: () {},
        );

      case 'FloatingButton':
        final iconStr = properties['icon'] ?? 'add';
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? const Color(0xFF5B4FCF);
        final fg = PropertyParser.parseColor(getStyle('textColor')) ?? Colors.white;

        return FloatingActionButton(
          onPressed: () {},
          backgroundColor: bg,
          foregroundColor: fg,
          child: Icon(_getIconByName(iconStr)),
        );

      // ================== DISPLAY ==================
      case 'Text':
        final text = properties['label'] ?? 'Sample Text';
        final size = double.tryParse(getStyle('fontSize')?.toString() ?? '') ?? 14.0;
        final weight = PropertyParser.parseFontWeight(getStyle('fontWeight'));
        final col = PropertyParser.parseColor(getStyle('color')) ?? const Color(0xFF1A1A2E);

        return Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: col,
          ),
        );

      case 'Image':
        final src = getStyle('src') ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500';
        final width = double.tryParse(getStyle('width')?.toString() ?? '');
        final height = double.tryParse(getStyle('height')?.toString() ?? '200.0');
        final fit = PropertyParser.parseBoxFit(getStyle('fit'));
        final radius = double.tryParse(getStyle('borderRadius')?.toString() ?? '') ?? 8.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            src,
            width: width ?? double.infinity,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) {
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
        final size = double.tryParse(getStyle('fontSize')?.toString() ?? '') ?? 24.0;
        final col = PropertyParser.parseColor(getStyle('color')) ?? const Color(0xFF1A1A2E);
        return Icon(
          _getIconByName(iconStr),
          size: size,
          color: col,
        );

      // ================== ADVANCED ==================
      case 'Chart':
        final title = properties['title'] ?? 'Usage Statistics';
        final chartType = properties['chartType'] ?? 'bar';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0A5B4FCF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x205B4FCF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) {
                    final heights = [40.0, 70.0, 50.0, 85.0, 60.0, 95.0];
                    return Container(
                      width: 20,
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4FCF).withValues(alpha: chartType == 'bar' ? 0.7 : 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );

      case 'Table':
        final List<String> columns = List<String>.from(properties['columns'] ?? ['Col 1', 'Col 2']);
        return Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: columns.map((col) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              )).toList(),
            ),
            TableRow(
              children: columns.map((col) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Data Value', style: TextStyle(fontSize: 11)),
              )).toList(),
            ),
          ],
        );

      case 'Stepper':
        final List<String> steps = List<String>.from(properties['steps'] ?? ['Step A', 'Step B']);
        return Row(
          children: List.generate(steps.length, (i) {
            return Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF5B4FCF),
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(height: 1, color: Colors.grey[350], margin: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                ],
              ),
            );
          }),
        );

      case 'Timeline':
        final List<String> items = List<String>.from(properties['items'] ?? ['Registered', 'Active']);
        return Column(
          children: List.generate(items.length, (i) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF5B4FCF), size: 16),
                    if (i < items.length - 1)
                      Container(width: 2, height: 24, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text(items[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            );
          }),
        );

      case 'Expanded':
        return Expanded(
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : render(
                  node.children.first,
                  isDesignMode: isDesignMode,
                  selectedNode: selectedNode,
                  hoveredNode: hoveredNode,
                  onSelect: onSelect,
                  onHover: onHover,
                  onDelete: onDelete,
                  onDuplicate: onDuplicate,
                  onMoveChild: onMoveChild,
                  onAddChild: onAddChild,
                  formValues: formValues,
                  onFormValueChanged: onFormValueChanged,
                ),
        );

      case 'Flexible':
        return Flexible(
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : render(
                  node.children.first,
                  isDesignMode: isDesignMode,
                  selectedNode: selectedNode,
                  hoveredNode: hoveredNode,
                  onSelect: onSelect,
                  onHover: onHover,
                  onDelete: onDelete,
                  onDuplicate: onDuplicate,
                  onMoveChild: onMoveChild,
                  onAddChild: onAddChild,
                  formValues: formValues,
                  onFormValueChanged: onFormValueChanged,
                ),
        );

      case 'SafeArea':
        return SafeArea(
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : render(
                  node.children.first,
                  isDesignMode: isDesignMode,
                  selectedNode: selectedNode,
                  hoveredNode: hoveredNode,
                  onSelect: onSelect,
                  onHover: onHover,
                  onDelete: onDelete,
                  onDuplicate: onDuplicate,
                  onMoveChild: onMoveChild,
                  onAddChild: onAddChild,
                  formValues: formValues,
                  onFormValueChanged: onFormValueChanged,
                ),
        );

      case 'FilePicker':
        final fieldName = properties['fieldName'] ?? 'file';
        final label = properties['label'] ?? 'Select File';
        final val = formValues[fieldName]?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
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
                      style: TextStyle(color: val.isNotEmpty ? Colors.black : Colors.grey[600]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isDesignMode ? () {} : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4FCF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Browse', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'OTP':
        final label = properties['label'] ?? 'Enter OTP';
        final length = int.tryParse(properties['length']?.toString() ?? '6') ?? 6;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );

      case 'Search':
        final fieldName = properties['fieldName'] ?? 'search';
        final label = properties['label'] ?? 'Search';
        final hint = properties['hint'] ?? 'Type keywords...';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            enabled: !isDesignMode,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0)),
              ),
            ),
          ),
        );

      case 'Avatar':
        final src = properties['src'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
        final radius = double.tryParse(properties['radius']?.toString() ?? '24.0') ?? 24.0;
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(src),
        );

      case 'Chip':
        final label = properties['label'] ?? 'Tag';
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? const Color(0xFFE8E7FD);
        final fg = PropertyParser.parseColor(getStyle('textColor')) ?? const Color(0xFF5B4FCF);
        return Chip(
          label: Text(label, style: TextStyle(color: fg, fontSize: 12)),
          backgroundColor: bg,
          padding: const EdgeInsets.all(4),
        );

      case 'Badge':
        final label = properties['label'] ?? 'New';
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? const Color(0xFFFF3B30);
        final fg = PropertyParser.parseColor(getStyle('textColor')) ?? Colors.white;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );

      case 'Progress':
        final col = PropertyParser.parseColor(getStyle('color')) ?? const Color(0xFF5B4FCF);
        final isCircular = properties['isCircular'] != false;
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: isCircular
              ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(col))
              : LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(col)),
        );

      case 'Tabs':
        final List<String> tabs = List<String>.from(properties['tabs'] ?? ['Tab One', 'Tab Two']);
        return DefaultTabController(
          length: tabs.length,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                labelColor: const Color(0xFF5B4FCF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF5B4FCF),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
              SizedBox(
                height: 150,
                child: TabBarView(
                  children: tabs.map((t) {
                    return Center(
                      child: Text('$t Content Area', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );

      case 'Drawer':
        final title = properties['title'] ?? 'App Drawer';
        return Container(
          width: 240,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF5B4FCF)),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
              ),
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ],
          ),
        );

      case 'NavigationBar':
        final List<String> items = List<String>.from(properties['items'] ?? ['Home', 'Search', 'Profile']);
        return BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: const Color(0xFF5B4FCF),
          unselectedItemColor: Colors.grey,
          items: items.map((item) {
            IconData iconData = Icons.home;
            if (item.toLowerCase() == 'search') iconData = Icons.search;
            if (item.toLowerCase() == 'profile') iconData = Icons.person;
            return BottomNavigationBarItem(
              icon: Icon(iconData),
              label: item,
            );
          }).toList(),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red[50],
          child: Text('Unsupported Component Type: ${node.type}'),
        );
    }
  }

  static Widget _buildEmptyPlaceholder(ComponentNode node, {void Function(ComponentNode, String)? onAddChild}) {
    final isWrapOrRow = node.type == 'Wrap' || node.type == 'Row';
    return Container(
      width: isWrapOrRow ? 150 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF).withValues(alpha:0.04),
        border: Border.all(
          color: const Color(0xFF5B4FCF).withValues(alpha:0.2),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_to_photos_rounded, color: const Color(0xFF5B4FCF).withValues(alpha:0.5), size: 24),
          const SizedBox(height: 8),
          Text(
            'Empty ${node.type} Container',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5B4FCF).withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Drag components here to add children',
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF5B4FCF).withValues(alpha:0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static bool _canAcceptChildren(String type) {
    final meta = ComponentRegistry.getByType(type);
    return meta?.canHaveChildren ?? false;
  }

  static IconData _getIconByName(String name) {
    switch (name.toLowerCase()) {
      case 'add':
        return Icons.add;
      case 'star':
        return Icons.star;
      case 'info':
        return Icons.info_outline;
      case 'home':
        return Icons.home_outlined;
      case 'settings':
        return Icons.settings;
      case 'person':
        return Icons.person_outline;
      case 'email':
        return Icons.mail_outline;
      case 'phone':
        return Icons.phone_android;
      case 'lock':
        return Icons.lock_outline;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'arrow_back':
        return Icons.arrow_back;
      default:
        return Icons.category_outlined;
    }
  }
}
