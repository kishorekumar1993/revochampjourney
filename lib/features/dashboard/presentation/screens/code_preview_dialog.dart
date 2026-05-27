import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// VS Code Dark Theme Colors
const Color vsTitleBar = Color(0xFF323233);
const Color vsActivityBar = Color(0xFF333333);
const Color vsSideBar = Color(0xFF252526);
const Color vsEditor = Color(0xFF1E1E1E);
const Color vsBorder = Color(0xFF3C3C3C);
const Color vsTextLight = Color(0xFFCCCCCC);
const Color vsTextDim = Color(0xFF858585);
const Color vsAccent = Color(0xFF007ACC);

/// Data structure for building a hierarchical file tree
class TreeNode {
  final String name;
  final bool isFolder;
  final String? fullPath;
  final Map<String, TreeNode> children = {};
  
  bool isExpanded = true; // Optimization: UI State moved to node
  int level = 0; // Optimization: Pre-computed depth level

  TreeNode({required this.name, required this.isFolder, this.fullPath});

  List<TreeNode> get sortedChildren {
    final list = children.values.toList();
    list.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }
}

/// Optimized isolated row widget to prevent tree-wide rebuilds on hover
class _HoverableTreeRow extends StatefulWidget {
  final TreeNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableTreeRow({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HoverableTreeRow> createState() => _HoverableTreeRowState();
}

class _HoverableTreeRowState extends State<_HoverableTreeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: widget.isSelected && !widget.node.isFolder
              ? const Color(0xFF37373D)
              : (_isHovered ? const Color(0xFF2A2D2E) : Colors.transparent),
          padding: EdgeInsets.only(left: 16.0 + (widget.node.level * 14.0), right: 16, top: 4, bottom: 4),
          child: Row(
            children: [
              if (widget.node.isFolder)
                Icon(widget.node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: vsTextLight)
              else
                const SizedBox(width: 16), // Spacer for caret alignment
              Icon(
                widget.node.isFolder ? Icons.folder_open : Icons.insert_drive_file_outlined,
                size: 14,
                color: widget.node.isFolder ? vsTextDim : (widget.node.name.endsWith('.dart') ? Colors.lightBlue : vsTextDim),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.node.name,
                  style: widget.node.isFolder 
                    ? _CodePreviewDialogState._fontInter13Bold 
                    : (widget.isSelected ? _CodePreviewDialogState._fontInter13White : _CodePreviewDialogState._fontInter13Light),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CodePreviewDialog extends StatefulWidget {
  final List<Map<String, String>> files;
  
  const CodePreviewDialog({super.key, required this.files});

  @override
  State<CodePreviewDialog> createState() => _CodePreviewDialogState();
}

class _CodePreviewDialogState extends State<CodePreviewDialog> {
  // Typographic Caching (Eliminates repetitive GoogleFonts re-evaluations)
  static final _fontInter11Bold = GoogleFonts.inter(fontSize: 11, color: vsTextLight, fontWeight: FontWeight.bold, letterSpacing: 0.5);
  static final _fontInter12Dim = GoogleFonts.inter(fontSize: 12, color: vsTextDim);
  static final _fontInter13Light = GoogleFonts.inter(fontSize: 13, color: vsTextLight);
  static final _fontInter13White = GoogleFonts.inter(fontSize: 13, color: Colors.white);
  static final _fontInter13Bold = GoogleFonts.inter(fontSize: 13, color: vsTextLight, fontWeight: FontWeight.w600);
  static final _fontCode13 = GoogleFonts.sourceCodePro(fontSize: 13, height: 1.5, color: const Color(0xFFD4D4D4));
  static final _fontCode13Dim = GoogleFonts.sourceCodePro(fontSize: 13, height: 1.5, color: const Color(0xFF858585));

  // State Segregation (Prevents full tree rebuilds)
  final ValueNotifier<String?> _selectedFileNotifier = ValueNotifier(null);
  final ValueNotifier<List<TreeNode>> _flatTreeNotifier = ValueNotifier([]);
  final ValueNotifier<int> _activityNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _sidebarOpenNotifier = ValueNotifier(true);

  late final TreeNode _treeRoot; // Cached structure base

  @override
  void initState() {
    super.initState();
    _treeRoot = _buildFileTree();
    _updateFlatTree();
    if (widget.files.isNotEmpty) {
      _selectedFileNotifier.value = '${widget.files.first['folderPath']}/${widget.files.first['fileName']}';
    }
  }
  
  @override
  void dispose() {
    _selectedFileNotifier.dispose();
    _flatTreeNotifier.dispose();
    _activityNotifier.dispose();
    _sidebarOpenNotifier.dispose();
    super.dispose();
  }

  TreeNode _buildFileTree() {
    final root = TreeNode(name: 'root', isFolder: true);
    for (var file in widget.files) {
      final folder = file['folderPath'] ?? 'lib';
      final fileName = file['fileName'] ?? 'untitled.dart';
      
      final parts = folder.split(RegExp(r'[/\\]'));
      TreeNode current = root;
      for (var part in parts) {
        if (part.isEmpty) continue;
        if (!current.children.containsKey(part)) {
          current.children[part] = TreeNode(name: part, isFolder: true);
        }
        current = current.children[part]!;
      }
      
      final fullPath = '$folder/$fileName';
      current.children[fileName] = TreeNode(name: fileName, isFolder: false, fullPath: fullPath);
    }
    return root;
  }

  // Flattens the recursive tree into a 1D list for ListView.builder Virtualization
  void _updateFlatTree() {
    final List<TreeNode> flat = [];
    void traverse(TreeNode node, int level) {
      if (node.name != 'root') {
        node.level = level;
        flat.add(node);
      }
      if (node.isExpanded || node.name == 'root') {
        for (var child in node.sortedChildren) {
          traverse(child, level + (node.name == 'root' ? 0 : 1));
        }
      }
    }
    traverse(_treeRoot, 0);
    _flatTreeNotifier.value = flat;
  }

  void _onActivityTapped(int index) {
    if (_activityNotifier.value == index) {
      _sidebarOpenNotifier.value = !_sidebarOpenNotifier.value;
    } else {
      _activityNotifier.value = index;
      _sidebarOpenNotifier.value = true;
    }
  }

  Widget _buildActivityIcon(IconData icon, int index, int selectedIndex, bool isSidebarOpen) {
    final isSelected = selectedIndex == index && isSidebarOpen;
    return RepaintBoundary(
      child: InkWell(
        onTap: () => _onActivityTapped(index),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(border: Border(left: BorderSide(color: isSelected ? vsAccent : Colors.transparent, width: 2))),
          child: Icon(icon, color: isSelected ? Colors.white : vsTextDim, size: 24),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(int activityIndex) {
    if (activityIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text("EXPLORER", style: _fontInter11Bold),
          ),
          Expanded(
            child: ValueListenableBuilder<List<TreeNode>>(
              valueListenable: _flatTreeNotifier,
              builder: (context, flatTree, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _selectedFileNotifier,
                  builder: (context, selectedFile, _) {
                    return ListView.builder( // Virtualized Explorer Rendering
                      padding: EdgeInsets.zero,
                      itemCount: flatTree.length,
                      itemBuilder: (context, index) {
                        final node = flatTree[index];
                        return _HoverableTreeRow(
                          node: node,
                          isSelected: selectedFile == node.fullPath,
                          onTap: () {
                            if (node.isFolder) {
                              node.isExpanded = !node.isExpanded;
                              _updateFlatTree();
                            } else {
                              _selectedFileNotifier.value = node.fullPath;
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else if (activityIndex == 1) {
      return _buildPlaceholderSidebar("SEARCH", "Search functionality coming soon...");
    } else {
      return _buildPlaceholderSidebar("SOURCE CONTROL", "Git integration coming soon...");
    }
  }

  Widget _buildPlaceholderSidebar(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(title, style: _fontInter11Bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(message, style: _fontInter12Dim),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: vsEditor,
            border: Border.all(color: vsBorder),
          ),
          child: Column(
            children: [
              // VS Code Title Bar
              Container(
                height: 35,
                color: vsTitleBar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer to balance title centering
                    Expanded(
                      child: Text(
                        "RevoChamp - Code Preview (${widget.files.length} Files)",
                        textAlign: TextAlign.center,
                        style: _fontInter12Dim.copyWith(color: vsTextLight),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 48,
                        height: 35,
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, size: 16, color: vsTextLight),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dual Pane Body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Activity Bar (Far Left)
                    RepaintBoundary(
                      child: Container(
                        width: 48,
                        color: vsActivityBar,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _sidebarOpenNotifier,
                          builder: (context, isOpen, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable: _activityNotifier,
                              builder: (context, activeIndex, _) {
                                return Column(
                                  children: [
                                    _buildActivityIcon(Icons.file_copy_outlined, 0, activeIndex, isOpen),
                                    _buildActivityIcon(Icons.search, 1, activeIndex, isOpen),
                                    _buildActivityIcon(Icons.account_tree_outlined, 2, activeIndex, isOpen),
                                  ],
                                );
                              },
                            );
                          }
                        ),
                      ),
                    ),
                    
                    // 2. Sidebar / File Explorer
                    RepaintBoundary(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _sidebarOpenNotifier,
                        builder: (context, isOpen, _) {
                          if (!isOpen) return const SizedBox.shrink();
                          return Container(
                            width: 400,
                            decoration: const BoxDecoration(
                              color: vsSideBar,
                              border: Border(right: BorderSide(color: vsBorder)),
                            ),
                            child: ValueListenableBuilder<int>(
                              valueListenable: _activityNotifier,
                              builder: (context, activeIndex, _) => _buildSidebarContent(activeIndex),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // 3. Right Pane: Code Viewer
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _selectedFileNotifier,
                        builder: (context, selectedFile, _) {
                          final selectedFileData = widget.files.firstWhere(
                            (f) => '${f['folderPath']}/${f['fileName']}' == selectedFile,
                            orElse: () => widget.files.first,
                          );
                          final lines = (selectedFileData['textContent'] ?? '').split('\n');

                          final breadcrumbParts = ['project'];
                          if (selectedFileData['folderPath'] != null && selectedFileData['folderPath']!.isNotEmpty) {
                            breadcrumbParts.addAll(selectedFileData['folderPath']!.split(RegExp(r'[/\\]')));
                          }
                          breadcrumbParts.add(selectedFileData['fileName'] ?? 'untitled');

                          return RepaintBoundary(
                            child: Container(
                              color: vsEditor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Editor Tabs
                                  Container(
                                    height: 35,
                                    color: vsSideBar,
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 35,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: const BoxDecoration(
                                            color: vsEditor,
                                            border: Border(top: BorderSide(color: vsAccent, width: 1)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.insert_drive_file_outlined,
                                                size: 14,
                                                color: selectedFileData['fileName']?.endsWith('.dart') == true ? Colors.lightBlue : vsTextDim,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(selectedFileData['fileName'] ?? 'untitled', style: _fontInter13Light),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.close, size: 14, color: vsTextDim),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        // Added: Copy Entire File Button
                                        Tooltip(
                                          message: 'Copy entire file',
                                          child: InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: selectedFileData['textContent'] ?? ''));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('File copied to clipboard', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF333333)),
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              child: Icon(Icons.copy, size: 16, color: vsTextDim),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Breadcrumbs
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: vsBorder))),
                                    child: Row(
                                      children: breadcrumbParts.asMap().entries.map((entry) {
                                        final isLast = entry.key == breadcrumbParts.length - 1;
                                        return Row(
                                          children: [
                                            Text(entry.value, style: _fontInter12Dim),
                                            if (!isLast)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Icon(Icons.chevron_right, size: 14, color: vsTextDim),
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  // Highly Performant Virtualized Editor View
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: lines.length,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 48,
                                                padding: const EdgeInsets.only(right: 16),
                                                alignment: Alignment.topRight,
                                                child: Text('${index + 1}', style: _fontCode13Dim),
                                              ),
                                              Expanded(child: SelectableText(lines[index], style: _fontCode13)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
