import 'package:flutter/material.dart';
import '../models/component_node.dart';
import '../models/component_property.dart';
import 'component_renderer.dart';

class ComponentRendererLayouts {
  static Widget? _renderSlot(
    ComponentNode parentNode,
    String slotName,
    RenderContext ctx,
  ) {
    final slotNode = parentNode.slots[slotName];
    if (slotNode != null) {
      return ComponentRenderer.render(
        slotNode,
        isDesignMode: ctx.isDesignMode,
        parentNode: parentNode,
        selectedNode: ctx.selectedNode,
        hoveredNode: ctx.hoveredNode,
        onSelect: ctx.onSelect,
        onHover: ctx.onHover,
        onDelete: ctx.onDelete,
        onDuplicate: ctx.onDuplicate,
        onMoveChild: ctx.onMoveChild,
        onAddChild: ctx.onAddChild,
        formValues: ctx.formValues,
        onFormValueChanged: ctx.onFormValueChanged,
        insideScrollable: ctx.insideScrollable,
      );
    }
    if (ctx.isDesignMode) {
      if (slotName == 'body' || slotName == 'appBar' || slotName == 'drawer' || slotName == 'endDrawer' || slotName == 'bottomNavigationBar' || slotName == 'floatingActionButton' || slotName == 'bottomSheet' || slotName == 'child' || slotName == 'title' || slotName == 'leading' || slotName == 'actions') {
        return SlotDragTarget(
          parentNode: parentNode,
          slotName: slotName,
          child: ComponentRenderer.buildSlotPlaceholder(parentNode, slotName),
        );
      }
    }
    return null;
  }

  static Widget buildLayout(ComponentNode node, RenderContext ctx) {
    final properties = node.properties;
    final isDesignMode = ctx.isDesignMode;
    final parentNode = ctx.parentNode;
    final selectedNode = ctx.selectedNode;
    final hoveredNode = ctx.hoveredNode;
    final onSelect = ctx.onSelect;
    final onHover = ctx.onHover;
    final onDelete = ctx.onDelete;
    final onDuplicate = ctx.onDuplicate;
    final onMoveChild = ctx.onMoveChild;
    final onAddChild = ctx.onAddChild;
    final formValues = ctx.formValues;
    final onFormValueChanged = ctx.onFormValueChanged;
    final insideScrollable = ctx.insideScrollable;
    final themeTokens = ctx.themeTokens;

    switch (node.type) {
      // ================== LAYOUTS ==================
      case 'Container':
        final width = double.tryParse(ComponentRenderer.getStyle(node, 'width')?.toString() ?? '');
        final height = double.tryParse(ComponentRenderer.getStyle(node, 'height')?.toString() ?? '');
        final bg = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor'));
        final pad = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'padding'));
        final marg = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'margin'));
        final radius =
            double.tryParse(ComponentRenderer.getStyle(node, 'borderRadius')?.toString() ?? '') ?? 0.0;
        final gradientStart = PropertyParser.parseColor(
          ComponentRenderer.getStyle(node, 'gradientStart'),
        );
        final gradientEnd = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'gradientEnd'));
        final borderColor = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'borderColor'));
        final borderWidth =
            double.tryParse(ComponentRenderer.getStyle(node, 'borderWidth')?.toString() ?? '') ?? 1.0;
        final elevation =
            double.tryParse(ComponentRenderer.getStyle(node, 'elevation')?.toString() ?? '') ?? 0.0;

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
            ),
          ];
        }

        return Container(
          width: width,
          height: height,
          padding: pad,
          margin: marg,
          alignment: PropertyParser.parseAlignment(ComponentRenderer.getStyle(node, 'alignment')),
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            border: border,
            boxShadow: boxShadows,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: _renderSlot(node, 'child', ctx),
        );

      case 'Row':
        final mainAlign = PropertyParser.parseMainAxisAlignment(
          properties['mainAxisAlignment'],
        );
        final crossAlign = PropertyParser.parseCrossAxisAlignment(
          properties['crossAxisAlignment'],
        );
        final rowSpacing = double.tryParse(
          ComponentRenderer.getStyle(node, 'spacing')?.toString() ??
          properties['spacing']?.toString() ??
          '',
        );

        Widget buildRow(CrossAxisAlignment effectiveCrossAlign, bool hasBoundedWidth) {
          if (node.children.isEmpty && isDesignMode) {
            return Row(
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: effectiveCrossAlign,
              children: [ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)],
            );
          }
          final renderedChildren = node.children.map((childNode) {
            final childWidget = ComponentRenderer.render(
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
              insideScrollable: insideScrollable,
            );
            final flexVal = int.tryParse(
              childNode.styles['flex']?.toString() ??
                  childNode.properties['flex']?.toString() ??
                  '',
            );
            if (flexVal != null && flexVal > 0 && hasBoundedWidth &&
                parentNode?.type != "SingleChildScrollView") {
              return Expanded(flex: flexVal, child: childWidget);
            }
            if (isDesignMode && hasBoundedWidth) {
              return Flexible(fit: FlexFit.loose, child: childWidget);
            }
            return childWidget;
          }).toList();

          final List<Widget> spacedChildren = [];
          for (int i = 0; i < renderedChildren.length; i++) {
            spacedChildren.add(renderedChildren[i]);
            if (rowSpacing != null && rowSpacing > 0 && i < renderedChildren.length - 1) {
              spacedChildren.add(SizedBox(width: rowSpacing));
            }
          }

          return Row(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: effectiveCrossAlign,
            children: spacedChildren,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCrossAlign = (crossAlign == CrossAxisAlignment.stretch && !constraints.hasBoundedHeight)
                ? CrossAxisAlignment.start
                : crossAlign;
            return buildRow(effectiveCrossAlign, constraints.hasBoundedWidth);
          },
        );

      case 'Column':
        final mainAlign = PropertyParser.parseMainAxisAlignment(
          properties['mainAxisAlignment'],
        );
        final crossAlign = PropertyParser.parseCrossAxisAlignment(
          properties['crossAxisAlignment'],
        );
        final mainSize = PropertyParser.parseMainAxisSize(
          ComponentRenderer.getStyle(node, 'mainAxisSize') ?? properties['mainAxisSize'],
        );
        final columnSpacing = double.tryParse(
          ComponentRenderer.getStyle(node, 'spacing')?.toString() ??
          properties['spacing']?.toString() ??
          '',
        );

        Widget buildColumn(CrossAxisAlignment effectiveCrossAlign, bool hasBoundedHeight) {
          if (node.children.isEmpty && isDesignMode) {
            return Column(
              mainAxisAlignment: mainAlign,
              crossAxisAlignment: effectiveCrossAlign,
              mainAxisSize: mainSize,
              children: [ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)],
            );
          }
          final renderedChildren = node.children.map((childNode) {
            final childWidget = ComponentRenderer.render(
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
              insideScrollable: insideScrollable,
            );
            // Support flex on direct Column children (same as Row)
            final flexVal = int.tryParse(
              childNode.styles['flex']?.toString() ??
                  childNode.properties['flex']?.toString() ??
                  '',
            );
            if (flexVal != null && flexVal > 0 && hasBoundedHeight &&
                parentNode?.type != "SingleChildScrollView") {
              return Expanded(flex: flexVal, child: childWidget);
            }
            if (isDesignMode && hasBoundedHeight) {
              return Flexible(fit: FlexFit.loose, child: childWidget);
            }
            return childWidget;
          }).toList();

          final List<Widget> spacedChildren = [];
          for (int i = 0; i < renderedChildren.length; i++) {
            spacedChildren.add(renderedChildren[i]);
            if (columnSpacing != null && columnSpacing > 0 && i < renderedChildren.length - 1) {
              spacedChildren.add(SizedBox(height: columnSpacing));
            }
          }

          return Column(
            mainAxisAlignment: mainAlign,
            crossAxisAlignment: effectiveCrossAlign,
            mainAxisSize: mainSize,
            children: spacedChildren,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCrossAlign = (crossAlign == CrossAxisAlignment.stretch && !constraints.hasBoundedWidth)
                ? CrossAxisAlignment.start
                : crossAlign;
            return buildColumn(effectiveCrossAlign, constraints.hasBoundedHeight);
          },
        );

      case 'Stack':
        final stackFit = () {
          final fitStr = (ComponentRenderer.getStyle(node, 'fit') ?? properties['fit'])
              ?.toString()
              .toLowerCase();
          if (fitStr == 'expand') return StackFit.expand;
          if (fitStr == 'passthrough') return StackFit.passthrough;
          return StackFit.loose;
        }();
        // Check if any child has positioning properties — render them as Positioned.
        if (node.children.isEmpty && isDesignMode) {
          return Stack(
            fit: stackFit,
            children: [ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)],
          );
        }
        return Stack(
          fit: stackFit,
          children: node.children.map((childNode) {
            final childWidget = ComponentRenderer.render(
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
              insideScrollable: insideScrollable,
            );
            double? posTop = double.tryParse(
              childNode.styles['top']?.toString() ??
                  childNode.properties['top']?.toString() ??
                  '',
            );
            double? posLeft = double.tryParse(
              childNode.styles['left']?.toString() ??
                  childNode.properties['left']?.toString() ??
                  '',
            );
            double? posRight = double.tryParse(
              childNode.styles['right']?.toString() ??
                  childNode.properties['right']?.toString() ??
                  '',
            );
            double? posBottom = double.tryParse(
              childNode.styles['bottom']?.toString() ??
                  childNode.properties['bottom']?.toString() ??
                  '',
            );
            // Support string shorthand: "topRight", "topLeft", "bottomRight", "bottomLeft", "topCenter", etc.
            final posStr =
                (childNode.styles['position'] ??
                        childNode.properties['position'])
                    ?.toString()
                    .toLowerCase()
                    .replaceAll('_', '')
                    .replaceAll(' ', '');
            if (posStr != null && posStr.isNotEmpty) {
              if (posStr.contains('top')) posTop ??= 0;
              if (posStr.contains('bottom')) posBottom ??= 0;
              if (posStr.contains('left')) posLeft ??= 0;
              if (posStr.contains('right')) posRight ??= 0;
            }
            if (posTop != null ||
                posLeft != null ||
                posRight != null ||
                posBottom != null) {
              return Positioned(
                top: posTop,
                left: posLeft,
                right: posRight,
                bottom: posBottom,
                child: childWidget,
              );
            }
            return childWidget;
          }).toList(),
        );

      case 'Wrap':
        final spacing =
            double.tryParse(ComponentRenderer.getStyle(node, 'spacing')?.toString() ?? '') ?? 8.0;
        final runSpacing =
            double.tryParse(ComponentRenderer.getStyle(node, 'runSpacing')?.toString() ?? '') ?? 8.0;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: ctx.renderChildren(node),
        );

      case 'GridView':
        final spacing =
            double.tryParse(ComponentRenderer.getStyle(node, 'spacing')?.toString() ?? '') ?? 8.0;
        final runSpacing =
            double.tryParse(ComponentRenderer.getStyle(node, 'runSpacing')?.toString() ?? '') ?? 8.0;
        final crossAxisCount =
            int.tryParse(properties['crossAxisCount']?.toString() ?? '') ?? 2;
        final childAspectRatio =
            double.tryParse(properties['childAspectRatio']?.toString() ?? '') ??
            1.0;
        final crossAxisSpacing =
            double.tryParse(properties['crossAxisSpacing']?.toString() ?? '') ??
            spacing;
        final mainAxisSpacing =
            double.tryParse(properties['mainAxisSpacing']?.toString() ?? '') ??
            runSpacing;
        final pad = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'padding'));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          padding: pad,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: ctx.renderChildren(node, propagateScrollable: true),
        );

      case 'ListView':
        final spacing =
            double.tryParse(ComponentRenderer.getStyle(node, 'spacing')?.toString() ?? '') ?? 8.0;
        final pad = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'padding'));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: pad,
          itemCount: node.children.isEmpty ? 1 : node.children.length,
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: (context, index) {
            if (node.children.isEmpty) {
              return isDesignMode
                  ? ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)
                  : const SizedBox.shrink();
            }
            return ComponentRenderer.render(
              node.children[index],
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
              insideScrollable: true,
            );
          },
        );

      case 'Card':
        final elevation =
            double.tryParse(ComponentRenderer.getStyle(node, 'elevation')?.toString() ?? '') ?? 2.0;
        final bg = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor')) ??
            PropertyParser.parseColor(themeTokens?.cardColor);
        final pad = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'padding'));
        final marg = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'margin'));
        final radius =
            double.tryParse(ComponentRenderer.getStyle(node, 'borderRadius')?.toString() ?? '') ??
            themeTokens?.borderRadius ?? 12.0;
        return Card(
          elevation: elevation,
          color: bg,
          margin: marg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: pad,
            child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
          ),
        );

      case 'SizedBox':
        final width = double.tryParse(ComponentRenderer.getStyle(node, 'width')?.toString() ?? '');
        final height = double.tryParse(ComponentRenderer.getStyle(node, 'height')?.toString() ?? '');
        return SizedBox(
          width: width,
          height: height,
          child: _renderSlot(node, 'child', ctx),
        );

      case 'Center':
        return Center(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Padding':
        final pad = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'padding') ?? properties['padding']);
        return Padding(
          padding: pad,
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Align':
        return Align(
          alignment: PropertyParser.parseAlignment(ComponentRenderer.getStyle(node, 'alignment') ?? properties['alignment']),
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Opacity':
        final opacity = double.tryParse((ComponentRenderer.getStyle(node, 'opacity') ?? properties['opacity'])?.toString() ?? '') ?? 1.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Transform':
        return Transform(
          transform: Matrix4.identity(),
          alignment: Alignment.center,
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Positioned':
        return _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink();

      case 'AspectRatio':
        final ratio = double.tryParse((properties['aspectRatio'] ?? ComponentRenderer.getStyle(node, 'aspectRatio'))?.toString() ?? '') ?? 1.0;
        return AspectRatio(
          aspectRatio: ratio <= 0 ? 1.0 : ratio,
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'GestureDetector':
        return GestureDetector(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'InkWell':
        return InkWell(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
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

      case 'Expanded':
        return Expanded(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );
      case 'Flexible':
        return Flexible(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'SafeArea':
        return SafeArea(
          child: _renderSlot(node, 'child', ctx) ?? const SizedBox.shrink(),
        );

      case 'Tabs':
        final List<String> tabs = List<String>.from(
          properties['tabs'] ?? ['Tab One', 'Tab Two'],
        );
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
                      child: Text(
                        '$t Content Area',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const ListTile(leading: Icon(Icons.home), title: Text('Home')),
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ],
          ),
        );

      case 'NavigationBar':
        final List<String> items = List<String>.from(
          properties['items'] ?? ['Home', 'Search', 'Profile'],
        );
        return BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: const Color(0xFF5B4FCF),
          unselectedItemColor: Colors.grey,
          items: items.map((item) {
            IconData iconData = Icons.home;
            if (item.toLowerCase() == 'search') iconData = Icons.search;
            if (item.toLowerCase() == 'profile') iconData = Icons.person;
            return BottomNavigationBarItem(icon: Icon(iconData), label: item);
          }).toList(),
        );

      case 'Scaffold':
        final bg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor')) ??
            PropertyParser.parseColor(themeTokens?.backgroundColor) ??
            Colors.white;

        final appBarWidget = _renderSlot(node, 'appBar', ctx);
        final bodyWidget = _renderSlot(node, 'body', ctx);
        final bottomNavWidget = _renderSlot(node, 'bottomNavigationBar', ctx);
        final drawerWidget = _renderSlot(node, 'drawer', ctx);
        final endDrawerWidget = _renderSlot(node, 'endDrawer', ctx);
        final fabWidget = _renderSlot(node, 'floatingActionButton', ctx);
        final bottomSheetWidget = _renderSlot(node, 'bottomSheet', ctx);

        return Scaffold(
          backgroundColor: bg,
          appBar: appBarWidget != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(56.0),
                  child: appBarWidget,
                )
              : null,
          bottomNavigationBar: bottomNavWidget,
          drawer: drawerWidget,
          endDrawer: endDrawerWidget,
          floatingActionButton: fabWidget,
          bottomSheet: bottomSheetWidget,
          body: SingleChildScrollView(
            child: bodyWidget ?? const SizedBox.shrink(),
          ),
        );

      case 'AppBar':
        final bg = PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor'));
        final titleText = properties['title']?.toString() ?? 'App Title';
        final titleWidget = _renderSlot(node, 'title', ctx) ?? Text(titleText);
        final leadingWidget = _renderSlot(node, 'leading', ctx);
        final actionWidget = _renderSlot(node, 'actions', ctx);
        return AppBar(
          backgroundColor: bg,
          title: titleWidget,
          leading: leadingWidget,
          actions: actionWidget != null ? [actionWidget] : null,
        );

      case 'SingleChildScrollView':
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

        if (node.children.isEmpty) {
          return SingleChildScrollView(
            scrollDirection: direction,
            physics: scrollPhysics,
            child: isDesignMode
                ? ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild)
                : const SizedBox.shrink(),
          );
        }

        final scvChildren = node.children
            .map(
              (childNode) => ComponentRenderer.render(
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
                insideScrollable: true,
              ),
            )
            .toList();

        if (direction == Axis.horizontal) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: scrollPhysics,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: scvChildren,
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: scrollPhysics,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: scvChildren,
          ),
        );

      case 'Carousel':
        final height =
            double.tryParse(properties['height']?.toString() ?? '') ?? 180.0;
        final viewportFraction =
            double.tryParse(properties['viewportFraction']?.toString() ?? '') ??
            0.9;
        final autoPlay = properties['autoPlay'] == true;
        final marg = PropertyParser.parsePadding(ComponentRenderer.getStyle(node, 'margin'));

        if (node.children.isEmpty && isDesignMode) {
          return Container(
            margin: marg,
            height: height,
            child: ComponentRenderer.buildEmptyPlaceholder(node, onAddChild: onAddChild),
          );
        }

        final childrenWidgets = node.children.map((childNode) {
          return ComponentRenderer.render(
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
        final currentIndex =
            int.tryParse(properties['currentIndex']?.toString() ?? '') ?? 0;
        final bnbBg =
            PropertyParser.parseColor(ComponentRenderer.getStyle(node, 'backgroundColor')) ??
            Colors.white;
        final bnbElevation =
            double.tryParse(ComponentRenderer.getStyle(node, 'elevation')?.toString() ?? '') ?? 8.0;

        final bnbItems = node.children.map((childNode) {
          final iconStr = childNode.properties['icon'] ?? 'home';
          final activeIconStr = childNode.properties['activeIcon'] ?? iconStr;
          final itemLabel = childNode.properties['label']?.toString() ?? 'Item';
          return BottomNavigationBarItem(
            icon: Icon(ComponentRenderer.getIconByName(iconStr)),
            activeIcon: Icon(ComponentRenderer.getIconByName(activeIconStr)),
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
          selectedItemColor:
              PropertyParser.parseColor(
                node.children.isNotEmpty
                    ? node
                          .children[currentIndex.clamp(
                            0,
                            node.children.length - 1,
                          )]
                          .styles['activeColor']
                    : null,
              ) ??
              const Color(0xFF5B4FCF),
          unselectedItemColor: Colors.grey,
          items: bnbItems,
          onTap: (_) {},
        );

      case 'BottomNavigationBarItem':
        return const SizedBox.shrink();

      case 'Table':
        final rawCols = properties['columns'] ?? ['Col 1', 'Col 2'];
        final List<Map<String, dynamic>> parsedCols = [];
        final List<String> colLabels = [];
        
        if (rawCols is List) {
          for (final col in rawCols) {
            if (col is Map) {
              final colMap = Map<String, dynamic>.from(col);
              parsedCols.add(colMap);
              colLabels.add(colMap['label']?.toString() ?? colMap['id']?.toString() ?? 'Column');
            } else if (col != null) {
              colLabels.add(col.toString());
              parsedCols.add({'id': col.toString(), 'label': col.toString()});
            }
          }
        } else {
          colLabels.addAll(['Col 1', 'Col 2']);
          parsedCols.addAll([{'id': 'Col 1', 'label': 'Col 1'}, {'id': 'Col 2', 'label': 'Col 2'}]);
        }

        final List<Map<String, dynamic>> parsedRows = [];
        if (properties['rows'] is List) {
          for (final r in properties['rows']) {
            if (r is Map) {
              parsedRows.add(Map<String, dynamic>.from(r));
            }
          }
        }

        final List<TableRow> tableRows = [];
        tableRows.add(
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[100]),
            children: colLabels.map((col) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                col,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            )).toList(),
          ),
        );

        if (parsedRows.isEmpty) {
          tableRows.add(
            TableRow(
              children: colLabels.map((col) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Data Value', style: TextStyle(fontSize: 11)),
              )).toList(),
            ),
          );
        } else {
          for (final row in parsedRows) {
            final List<Widget> cells = [];
            for (final col in parsedCols) {
              final colId = col['id']?.toString() ?? col['fieldId']?.toString() ?? col['label']?.toString() ?? '';
              final cellVal = row[colId]?.toString() ?? row[colId.toLowerCase()]?.toString() ?? '';
              cells.add(Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cellVal,
                  style: const TextStyle(fontSize: 11),
                ),
              ));
            }
            tableRows.add(TableRow(children: cells));
          }
        }

        return Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: tableRows,
        );

      case 'Stepper':
        final rawSteps = properties['steps'] ?? ['Step A', 'Step B'];
        final List<String> steps = [];
        if (rawSteps is List) {
          for (final step in rawSteps) {
            if (step is Map) {
              steps.add(step['label']?.toString() ?? step['title']?.toString() ?? 'Step');
            } else if (step != null) {
              steps.add(step.toString());
            }
          }
        } else {
          steps.addAll(['Step A', 'Step B']);
        }
        return Row(
          children: List.generate(steps.length, (i) {
            return Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF5B4FCF),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.grey[350],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            );
          }),
        );

      case 'Timeline':
        final rawItems = properties['items'] ?? ['Registered', 'Active'];
        final List<String> items = [];
        if (rawItems is List) {
          for (final item in rawItems) {
            if (item is Map) {
              items.add(item['label']?.toString() ?? item['title']?.toString() ?? 'Event');
            } else if (item != null) {
              items.add(item.toString());
            }
          }
        } else {
          items.addAll(['Registered', 'Active']);
        }
        return Column(
          children: List.generate(items.length, (i) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF5B4FCF),
                      size: 16,
                    ),
                    if (i < items.length - 1)
                      Container(width: 2, height: 24, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );

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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
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
                        color: const Color(
                          0xFF5B4FCF,
                        ).withValues(alpha: chartType == 'bar' ? 0.7 : 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );

      case 'ListTile':
        final titleText = properties['title']?.toString() ?? 'List Title';
        final subtitleText = properties['subtitle']?.toString() ?? 'List Subtitle';
        return ListTile(
          leading: _renderSlot(node, 'leading', ctx),
          title: _renderSlot(node, 'title', ctx) ?? Text(titleText),
          subtitle: _renderSlot(node, 'subtitle', ctx) ?? Text(subtitleText),
          trailing: _renderSlot(node, 'trailing', ctx),
        );

      case 'AlertDialog':
        final titleText = properties['title']?.toString() ?? 'Alert Title';
        final contentWidget = _renderSlot(node, 'content', ctx);
        final actionWidget = _renderSlot(node, 'actions', ctx);
        return AlertDialog(
          title: _renderSlot(node, 'title', ctx) ?? Text(titleText),
          content: contentWidget,
          actions: actionWidget != null ? [actionWidget] : null,
        );

      case 'TabBarView':
        return DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Color(0xFF5B4FCF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF5B4FCF),
                tabs: [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                  Tab(text: 'Tab 3'),
                ],
              ),
              SizedBox(
                height: 180,
                child: TabBarView(
                  children: [
                    _renderSlot(node, 'tab1', ctx) ?? const Center(child: Text('Tab 1 Content')),
                    _renderSlot(node, 'tab2', ctx) ?? const Center(child: Text('Tab 2 Content')),
                    _renderSlot(node, 'tab3', ctx) ?? const Center(child: Text('Tab 3 Content')),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
