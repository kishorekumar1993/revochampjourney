import 'dart:async';
import 'package:flutter/material.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import '../registry/component_registry.dart';

class ComponentRenderer {
  static Widget render(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? parentNode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode?)? onSelect,
    void Function(ComponentNode?)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild,
    void Function(ComponentNode, String)? onAddChild,
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
  }) {
    if (node.type == 'Expanded') {
      Widget childWidget;
      if (node.children.isEmpty) {
        childWidget = isDesignMode
            ? GestureDetector(
                onTap: () { if (onSelect != null) onSelect(node); },
                child: _buildEmptyPlaceholder(node, onAddChild: onAddChild),
              )
            : const SizedBox.shrink();
      } else {
        childWidget = render(
          node.children.first,
          isDesignMode: isDesignMode,
          parentNode: node,
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
      final bool isValidParent = parentNode != null && (parentNode.type == 'Row' || parentNode.type == 'Column' || parentNode.type == 'Flex');
      return isValidParent ? Expanded(child: childWidget) : childWidget;
    }

    if (node.type == 'Flexible') {
      Widget childWidget;
      if (node.children.isEmpty) {
        childWidget = isDesignMode
            ? GestureDetector(
                onTap: () { if (onSelect != null) onSelect(node); },
                child: _buildEmptyPlaceholder(node, onAddChild: onAddChild),
              )
            : const SizedBox.shrink();
      } else {
        childWidget = render(
          node.children.first,
          isDesignMode: isDesignMode,
          parentNode: node,
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
      final bool isValidParent = parentNode != null && (parentNode.type == 'Row' || parentNode.type == 'Column' || parentNode.type == 'Flex');
      return isValidParent ? Flexible(child: childWidget) : childWidget;
    }

    // 1. Render the actual core widget
    Widget coreWidget = _buildWidget(
      node,
      isDesignMode: isDesignMode,
      parentNode: parentNode,
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

    // Apply global padding and sizing
    coreWidget = _applyPaddingAndSizing(coreWidget, node);
    // Apply global decoration (background color, border radius)
    coreWidget = _applyDecoration(coreWidget, node);

    // 2. If Design Mode, wrap with interaction overlays (selection border, hover border, drag/drop wrappers)
    if (isDesignMode) {
      final isSelected = selectedNode?.id == node.id;
      final isHovered = hoveredNode?.id == node.id;

      // ── Types that MUST NOT be wrapped in Draggable or DragTarget ──────────
      // These widgets depend on clean BuildContext ancestry (Scaffold uses
      // Navigator/MediaQuery InheritedWidgets; Scrollables use ScrollController;
      // form fields use Form). Wrapping in Draggable duplicates the subtree and
      // breaks the ancestor check at framework.dart:6417.
      const nonDraggableTypes = {
        'Scaffold',
        'SingleChildScrollView',
        'ListView',
        'GridView',
        'Carousel',
        'TextField',
        'Dropdown',
        'DatePicker',
        'Search',
        'FilePicker',
        'Checkbox',
        'RadioGroup',
        'Switch',
        'Slider',
        'Tabs',
      };

      if (nonDraggableTypes.contains(node.type)) {
        // Lightweight overlay: just a thin selection/hover border + tap-to-select.
        // No Draggable, no DragTarget, no MouseRegion — keeps BuildContext ancestry clean.
        final decorated = Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B4FCF)
                  : isHovered
                      ? const Color(0xFF9E95F5)
                      : Colors.transparent,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: coreWidget,
        );
        return _applyMargin(
          GestureDetector(
            onTap: () { if (onSelect != null) onSelect(node); },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                decorated,
                if (isSelected)
                  Positioned(
                    top: -24, left: 0,
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
                          Text(node.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () { if (onDelete != null) onDelete(node); },
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          node,
        );
      }

      // ── Full draggable overlay for regular widgets ─────────────────────────
      final canAcceptChildren = _canAcceptChildren(node.type);

      Widget interactiveWrapper = MouseRegion(
        onEnter: (_) {
          if (onHover != null) onHover(node);
        },
        onExit: (_) {
          if (onHover != null && hoveredNode?.id == node.id) {
            onHover(null);
          }
        },
        child: GestureDetector(
          onTap: () {
            if (onSelect != null) onSelect(node);
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
                          onTap: () { if (onDuplicate != null) onDuplicate(node); },
                          child: const Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () { if (onDelete != null) onDelete(node); },
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
              color: const Color(0xFF5B4FCF).withValues(alpha: 0.8),
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
        return _applyMargin(
          DragTarget<Object>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final data = details.data;
              if (data is String) {
                if (onAddChild != null) onAddChild(node, data);
              } else if (data is ComponentNode) {
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
          ),
          node,
        );
      }

      return _applyMargin(dragSource, node);
    }

    return _applyMargin(coreWidget, node);
  }

  static Widget _buildWidget(
    ComponentNode node, {
    required bool isDesignMode,
    ComponentNode? parentNode,
    ComponentNode? selectedNode,
    ComponentNode? hoveredNode,
    void Function(ComponentNode?)? onSelect,
    void Function(ComponentNode?)? onHover,
    void Function(ComponentNode)? onDelete,
    void Function(ComponentNode)? onDuplicate,
    void Function(ComponentNode, ComponentNode, int)? onMoveChild,
    void Function(ComponentNode, String)? onAddChild,
    Map<String, dynamic> formValues = const {},
    void Function(String, dynamic)? onFormValueChanged,
  }) {
    final properties = node.properties;
    // Note: node.styles is accessed via getStyle() helper below.

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
                parentNode: node,
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
          alignment: PropertyParser.parseAlignment(getStyle('alignment')),
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            border: border,
            boxShadow: boxShadows,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : null)
              : node.children.length == 1
                  ? render(
                      node.children.first,
                      isDesignMode: isDesignMode,
                      parentNode: node,
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
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: renderChildren(),
                    ),
        );

      case 'Row':
        final mainAlign = PropertyParser.parseMainAxisAlignment(properties['mainAxisAlignment']);
        final crossAlign = PropertyParser.parseCrossAxisAlignment(properties['crossAxisAlignment']);

        Widget buildRow(CrossAxisAlignment effectiveCrossAlign) {
          if (node.children.isEmpty && isDesignMode) {
            return Row(
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: effectiveCrossAlign,
              children: [
                _buildEmptyPlaceholder(node, onAddChild: onAddChild),
              ],
            );
          }
          return Row(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: effectiveCrossAlign,
            children: node.children.map((childNode) {
              final childWidget = render(
                childNode,
                isDesignMode: isDesignMode,
                parentNode: node,
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
              final flexVal = int.tryParse(
                childNode.styles['flex']?.toString() ?? childNode.properties['flex']?.toString() ?? '',
              );
              if (flexVal != null) {
                return Expanded(flex: flexVal, child: childWidget);
              }
              return childWidget;
            }).toList(),
          );
        }

        if (crossAlign == CrossAxisAlignment.stretch) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return buildRow(constraints.hasBoundedHeight ? crossAlign : CrossAxisAlignment.start);
            },
          );
        }
        return buildRow(crossAlign);

      case 'Column':
        final mainAlign = PropertyParser.parseMainAxisAlignment(properties['mainAxisAlignment']);
        final crossAlign = PropertyParser.parseCrossAxisAlignment(properties['crossAxisAlignment']);
        final mainSize = PropertyParser.parseMainAxisSize(getStyle('mainAxisSize') ?? properties['mainAxisSize']);

        Widget buildColumn(CrossAxisAlignment effectiveCrossAlign) {
          if (node.children.isEmpty && isDesignMode) {
            return Column(
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: effectiveCrossAlign,
              mainAxisSize: mainSize,
              children: [_buildEmptyPlaceholder(node, onAddChild: onAddChild)],
            );
          }
          return Column(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: effectiveCrossAlign,
            mainAxisSize: mainSize,
            children: node.children.map((childNode) {
              final childWidget = render(
                childNode,
                isDesignMode: isDesignMode,
                parentNode: node,
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
              // Support flex on direct Column children (same as Row)
              final flexVal = int.tryParse(
                childNode.styles['flex']?.toString() ?? childNode.properties['flex']?.toString() ?? '',
              );
              if (flexVal != null && flexVal > 0) {
                return Expanded(flex: flexVal, child: childWidget);
              }
              return childWidget;
            }).toList(),
          );
        }

        if (crossAlign == CrossAxisAlignment.stretch) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return buildColumn(constraints.hasBoundedWidth ? crossAlign : CrossAxisAlignment.start);
            },
          );
        }
        return buildColumn(crossAlign);

      case 'Stack':
        final stackFit = () {
          final fitStr = (getStyle('fit') ?? properties['fit'])?.toString().toLowerCase();
          if (fitStr == 'expand') return StackFit.expand;
          if (fitStr == 'passthrough') return StackFit.passthrough;
          return StackFit.loose;
        }();
        // Check if any child has positioning properties — render them as Positioned.
        if (node.children.isEmpty && isDesignMode) {
          return Stack(
            fit: stackFit,
            children: [_buildEmptyPlaceholder(node, onAddChild: onAddChild)],
          );
        }
        return Stack(
          fit: stackFit,
          children: node.children.map((childNode) {
            final childWidget = render(
              childNode,
              isDesignMode: isDesignMode,
              parentNode: node,
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
            final top = double.tryParse(childNode.styles['top']?.toString() ?? childNode.properties['top']?.toString() ?? '');
            final left = double.tryParse(childNode.styles['left']?.toString() ?? childNode.properties['left']?.toString() ?? '');
            final right = double.tryParse(childNode.styles['right']?.toString() ?? childNode.properties['right']?.toString() ?? '');
            final bottom = double.tryParse(childNode.styles['bottom']?.toString() ?? childNode.properties['bottom']?.toString() ?? '');
            if (top != null || left != null || right != null || bottom != null) {
              return Positioned(
                top: top,
                left: left,
                right: right,
                bottom: bottom,
                child: childWidget,
              );
            }
            return childWidget;
          }).toList(),
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
        final crossAxisCount = int.tryParse(properties['crossAxisCount']?.toString() ?? '') ?? 2;
        final childAspectRatio = double.tryParse(properties['childAspectRatio']?.toString() ?? '') ?? 1.0;
        final crossAxisSpacing = double.tryParse(properties['crossAxisSpacing']?.toString() ?? '') ?? spacing;
        final mainAxisSpacing = double.tryParse(properties['mainAxisSpacing']?.toString() ?? '') ?? runSpacing;
        final pad = PropertyParser.parsePadding(getStyle('padding'));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          padding: pad,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: renderChildren(),
        );

      case 'ListView':
        final spacing = double.tryParse(getStyle('spacing')?.toString() ?? '') ?? 8.0;
        final pad = PropertyParser.parsePadding(getStyle('padding'));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: pad,
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

      case 'SizedBox':
        final width = double.tryParse(getStyle('width')?.toString() ?? '');
        final height = double.tryParse(getStyle('height')?.toString() ?? '');
        return SizedBox(
          width: width,
          height: height,
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : render(
                  node.children.first,
                  isDesignMode: isDesignMode,
                  parentNode: node,
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
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? (isEnabled ? Colors.white : Colors.grey[200]);
        final radius = double.tryParse(getStyle('borderRadius')?.toString() ?? '') ?? 4.0;

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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
            filled: true,
            fillColor: bg,
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

        return DropdownButtonFormField<String>(
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
        );

      case 'Radio':
        final fieldName = properties['fieldName'] ?? 'radio';
        final label = properties['label'] ?? 'Select Value';
        final List<String> options = List<String>.from(properties['options'] ?? []);
        final currentValue = formValues[fieldName]?.toString() ?? '';

        return Column(
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

        return InkWell(
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
        final fg = PropertyParser.parseColor(getStyle('textColor') ?? getStyle('color')) ?? Colors.white;
        final radius = PropertyParser.parseDouble(getStyle('borderRadius'), 8.0);
        final btnWidth = double.tryParse(getStyle('width')?.toString() ?? '');
        final btnHeight = double.tryParse(getStyle('height')?.toString() ?? '');
        final btnFontSize = PropertyParser.parseDouble(getStyle('fontSize'), 14.0);
        final iconStr = properties['icon']?.toString();

        Widget btnChild = iconStr != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getIconByName(iconStr), size: 16, color: fg),
                  const SizedBox(width: 8),
                  Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: btnFontSize)),
                ],
              )
            : Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: btnFontSize));

        Widget btn = ElevatedButton(
          onPressed: isDesignMode ? () {} : () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
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
        final text = properties['label'] ?? properties['text'] ?? 'Sample Text';
        final size = PropertyParser.parseDouble(getStyle('fontSize'), 14.0);
        final weight = PropertyParser.parseFontWeight(getStyle('fontWeight'));
        final fontStyle = PropertyParser.parseFontStyle(getStyle('fontStyle'));
        final col = PropertyParser.parseColor(getStyle('color')) ?? const Color(0xFF1A1A2E);
        final textAlign = PropertyParser.parseTextAlign(getStyle('textAlign'));
        final maxLines = int.tryParse(getStyle('maxLines')?.toString() ?? '');
        final overflow = maxLines != null
            ? PropertyParser.parseTextOverflow(getStyle('overflow') ?? 'ellipsis')
            : null;
        final letterSpacing = double.tryParse(getStyle('letterSpacing')?.toString() ?? '');
        final lineHeight = double.tryParse(getStyle('lineHeight')?.toString() ?? '');
        final decoration = PropertyParser.parseTextDecoration(getStyle('textDecoration'));

        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            fontStyle: fontStyle,
            color: col,
            letterSpacing: letterSpacing,
            height: lineHeight,
            decoration: decoration,
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
                  parentNode: node,
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
        );

      case 'OTP':
        final label = properties['label'] ?? 'Enter OTP';
        final length = int.tryParse(properties['length']?.toString() ?? '6') ?? 6;
        return Column(
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

      case 'Scaffold':
        final bg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? Colors.white;
        final bottomNavNode = node.children.where((c) => c.type == 'BottomNavigationBar').firstOrNull;
        final bodyChildren = node.children.where((c) => c.type != 'BottomNavigationBar').toList();

        Widget? bottomNavWidget;
        if (bottomNavNode != null) {
          bottomNavWidget = render(
            bottomNavNode,
            isDesignMode: isDesignMode,
            parentNode: node,
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

        return Scaffold(
          backgroundColor: bg,
          bottomNavigationBar: bottomNavWidget,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: bodyChildren.map((childNode) {
              final childWidget = render(
                childNode,
                isDesignMode: isDesignMode,
                parentNode: node,
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
              // Wrap scrollable children in Expanded so they scroll within the Scaffold height
              final isScrollable = childNode.type == 'ListView' ||
                  childNode.type == 'SingleChildScrollView' ||
                  childNode.type == 'GridView';
              if (isScrollable) {
                return Expanded(child: childWidget);
              }
              return childWidget;
            }).toList(),
          ),
        );


      case 'SingleChildScrollView':
        // Use physics based on 'physics' property

        ScrollPhysics? scrollPhysics;
        final physicsStr = properties['physics']?.toString().toLowerCase();
        if (physicsStr == 'never') {
          scrollPhysics = const NeverScrollableScrollPhysics();
        } else if (physicsStr == 'bouncing') {
          scrollPhysics = const BouncingScrollPhysics();
        } else {
          scrollPhysics = const ClampingScrollPhysics();
        }

        final direction = properties['scrollDirection'] == 'horizontal'
            ? Axis.horizontal
            : Axis.vertical;
        return SingleChildScrollView(
          scrollDirection: direction,
          physics: scrollPhysics,
          child: node.children.isEmpty
              ? (isDesignMode ? _buildEmptyPlaceholder(node, onAddChild: onAddChild) : const SizedBox.shrink())
              : Column(
                  mainAxisSize: direction == Axis.vertical ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: node.children.map((childNode) => render(
                    childNode,
                    isDesignMode: isDesignMode,
                    parentNode: node,
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
                  )).toList(),
                ),
        );

      case 'Carousel':
        final height = double.tryParse(properties['height']?.toString() ?? '') ?? 180.0;
        final viewportFraction = double.tryParse(properties['viewportFraction']?.toString() ?? '') ?? 0.9;
        final autoPlay = properties['autoPlay'] == true;
        final marg = PropertyParser.parsePadding(getStyle('margin'));

        if (node.children.isEmpty && isDesignMode) {
          return Container(
            margin: marg,
            height: height,
            child: _buildEmptyPlaceholder(node, onAddChild: onAddChild),
          );
        }

        final childrenWidgets = node.children.map((childNode) {
          return render(
            childNode,
            isDesignMode: isDesignMode,
            parentNode: node,
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
        }).toList();

        return Container(
          margin: marg,
          child: RevoCarouselWidget(
            height: height,
            viewportFraction: viewportFraction,
            autoPlay: autoPlay,
            children: childrenWidgets,
          ),
        );

      case 'BottomNavigationBar':
        final currentIndex = int.tryParse(properties['currentIndex']?.toString() ?? '') ?? 0;
        final bnbBg = PropertyParser.parseColor(getStyle('backgroundColor')) ?? Colors.white;
        final bnbElevation = double.tryParse(getStyle('elevation')?.toString() ?? '') ?? 8.0;

        final bnbItems = node.children.map((childNode) {
          final iconStr = childNode.properties['icon'] ?? 'home';
          final activeIconStr = childNode.properties['activeIcon'] ?? iconStr;
          final itemLabel = childNode.properties['label']?.toString() ?? 'Item';
          return BottomNavigationBarItem(
            icon: Icon(_getIconByName(iconStr)),
            activeIcon: Icon(_getIconByName(activeIconStr)),
            label: itemLabel,
          );
        }).toList();

        if (bnbItems.length < 2) {
          return const SizedBox.shrink();
        }

        return BottomNavigationBar(
          currentIndex: currentIndex.clamp(0, bnbItems.length - 1),
          backgroundColor: bnbBg,
          elevation: bnbElevation,
          selectedItemColor: PropertyParser.parseColor(
                node.children.isNotEmpty ? node.children[currentIndex.clamp(0, node.children.length - 1)].styles['activeColor'] : null,
              ) ??
              const Color(0xFF5B4FCF),
          unselectedItemColor: Colors.grey,
          items: bnbItems,
          onTap: (_) {},
        );

      case 'BottomNavigationBarItem':
        // Rendered inline by BottomNavigationBar case; standalone fallback
        return const SizedBox.shrink();

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
      case 'spa': return Icons.spa;
      case 'child_care': return Icons.child_care;
      case 'children': return Icons.child_care;
      case 'accessibility_new': return Icons.accessibility_new;
      case 'accessibility': return Icons.accessibility;
      case 'sentiment_satisfied': return Icons.sentiment_satisfied;
      case 'medical_services': return Icons.medical_services;
      case 'psychology': return Icons.psychology;
      case 'local_hospital': return Icons.local_hospital;
      case 'healing': return Icons.healing;
      case 'medication': return Icons.medication;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'monitor_heart': return Icons.monitor_heart;
      case 'biotech': return Icons.biotech;
      case 'science': return Icons.science;
      case 'add': return Icons.add;
      case 'add_circle': return Icons.add_circle_outline;
      case 'star': return Icons.star;
      case 'star_outline': return Icons.star_outline;
      case 'info': return Icons.info_outline;
      case 'home': return Icons.home_outlined;
      case 'home_filled': return Icons.home;
      case 'settings': return Icons.settings;
      case 'settings_outline': return Icons.settings_outlined;
      case 'person': return Icons.person_outline;
      case 'person_filled': return Icons.person;
      case 'email': return Icons.mail_outline;
      case 'phone': return Icons.phone_android;
      case 'lock': return Icons.lock_outline;
      case 'lock_open': return Icons.lock_open_outlined;
      case 'check': return Icons.check;
      case 'check_circle': return Icons.check_circle_outline;
      case 'close': return Icons.close;
      case 'arrow_forward': return Icons.arrow_forward;
      case 'arrow_back': return Icons.arrow_back;
      case 'arrow_drop_down': return Icons.arrow_drop_down;
      case 'arrow_drop_up': return Icons.arrow_drop_up;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'shopping_bag': return Icons.shopping_bag_outlined;
      case 'laptop': return Icons.laptop;
      case 'checkroom': return Icons.checkroom;
      case 'smartphone': return Icons.smartphone;
      case 'kitchen': return Icons.kitchen;
      case 'microwave': return Icons.microwave;
      case 'bolt': return Icons.bolt;
      case 'search': return Icons.search;
      case 'menu': return Icons.menu;
      case 'favorite': return Icons.favorite;
      case 'favorite_outline': return Icons.favorite_border;
      case 'notifications': return Icons.notifications;
      case 'notifications_outline': return Icons.notifications_none;
      case 'edit': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'share': return Icons.share_outlined;
      case 'camera': return Icons.camera_alt_outlined;
      case 'image': return Icons.image_outlined;
      case 'filter': return Icons.filter_list;
      case 'sort': return Icons.sort;
      case 'dashboard': return Icons.dashboard_outlined;
      case 'chart': return Icons.bar_chart;
      case 'pie_chart': return Icons.pie_chart_outline;
      case 'logout': return Icons.logout;
      case 'login': return Icons.login;
      case 'account': return Icons.account_circle_outlined;
      case 'calendar': return Icons.calendar_today;
      case 'location': return Icons.location_on_outlined;
      case 'payment': return Icons.payment;
      case 'credit_card': return Icons.credit_card;
      case 'download': return Icons.download_outlined;
      case 'upload': return Icons.upload_outlined;
      case 'refresh': return Icons.refresh;
      case 'more_horiz': return Icons.more_horiz;
      case 'more_vert': return Icons.more_vert;
      case 'visibility': return Icons.visibility_outlined;
      case 'visibility_off': return Icons.visibility_off_outlined;
      case 'send': return Icons.send;
      case 'attach': return Icons.attach_file;
      case 'copy': return Icons.copy_outlined;
      case 'paste': return Icons.paste_outlined;
      case 'done': return Icons.done;
      case 'done_all': return Icons.done_all;
      case 'help': return Icons.help_outline;
      case 'warning': return Icons.warning_amber_outlined;
      case 'error': return Icons.error_outline;
      case 'wifi': return Icons.wifi;
      case 'bluetooth': return Icons.bluetooth;
      case 'battery': return Icons.battery_full;
      case 'speed': return Icons.speed;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      default: return Icons.category_outlined;
    }
  }

  static Widget _applyPaddingAndSizing(Widget widget, ComponentNode node) {
    // Types that handle their own sizing and padding internally — skip the wrapper.
    const selfSizedTypes = {
      'Container', 'Card', 'Scaffold', 'SizedBox',
      // Form fields with InputDecorator require unconstrained width from parent
      // (or a finite constraint from an ancestor). Adding a SizedBox(width: null)
      // here does NOT help and can cause the "infinite width" assertion.
      'TextField', 'Dropdown', 'DatePicker', 'Search', 'FilePicker',
      // Flex wrappers own their sizing.
      'Expanded', 'Flexible', 'Spacer',
    };
    if (selfSizedTypes.contains(node.type)) return widget;

    Widget result = widget;

    final width = double.tryParse(node.styles['width']?.toString() ?? node.properties['width']?.toString() ?? '');
    final height = double.tryParse(node.styles['height']?.toString() ?? node.properties['height']?.toString() ?? '');

    // Guard: don't emit SizedBox(width: infinity) — that propagates unbounded constraints.
    final safeWidth = (width != null && width.isFinite && width > 0) ? width : null;
    final safeHeight = (height != null && height.isFinite && height > 0) ? height : null;

    if (safeWidth != null || safeHeight != null) {
      result = SizedBox(
        width: safeWidth,
        height: safeHeight,
        child: result,
      );
    }

    final pad = PropertyParser.parsePadding(node.styles['padding'] ?? node.properties['padding']);
    if (pad != EdgeInsets.zero) {
      result = Padding(
        padding: pad,
        child: result,
      );
    }

    return result;
  }

  static Widget _applyDecoration(Widget widget, ComponentNode node) {
    if (node.type == 'Scaffold' || node.type == 'Container' || node.type == 'Card' || node.type == 'SizedBox') {
      return widget;
    }

    final bg = PropertyParser.parseColor(node.styles['backgroundColor'] ?? node.properties['backgroundColor']);
    final radius = double.tryParse(node.styles['borderRadius']?.toString() ?? node.properties['borderRadius']?.toString() ?? '');

    if (bg != null || radius != null) {
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius != null ? BorderRadius.circular(radius) : null,
        ),
        child: widget,
      );
    }

    return widget;
  }

  static Widget _applyMargin(Widget widget, ComponentNode node) {
    if (node.type == 'Container' || node.type == 'Card' || node.type == 'Scaffold') {
      return widget;
    }

    final marg = PropertyParser.parsePadding(node.styles['margin'] ?? node.properties['margin']);
    if (marg != EdgeInsets.zero) {
      return Padding(
        padding: marg,
        child: widget,
      );
    }

    // Default vertical margin for form elements and buttons to maintain nice spacing
    final isFormElement = node.type == 'TextField' ||
        node.type == 'Dropdown' ||
        node.type == 'Radio' ||
        node.type == 'Checkbox' ||
        node.type == 'DatePicker' ||
        node.type == 'Switch' ||
        node.type == 'Slider' ||
        node.type == 'FilePicker' ||
        node.type == 'OTP' ||
        node.type == 'Search' ||
        node.type == 'Button';
    if (isFormElement) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: widget,
      );
    }

    return widget;
  }
}

class RevoCarouselWidget extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double viewportFraction;
  final bool autoPlay;

  const RevoCarouselWidget({
    super.key,
    required this.children,
    this.height = 180,
    this.viewportFraction = 0.9,
    this.autoPlay = true,
  });

  @override
  State<RevoCarouselWidget> createState() => _RevoCarouselWidgetState();
}

class _RevoCarouselWidgetState extends State<RevoCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: widget.viewportFraction,
    );
    if (widget.autoPlay && widget.children.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) return;
        final nextPage = (_currentPage + 1) % widget.children.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: widget.children[index],
          );
        },
      ),
    );
  }
}
