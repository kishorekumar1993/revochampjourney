import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/core/component_engine/models/api_config.dart';
import 'package:revojourneytryone/features/visual_builder/application/studio_providers.dart';

class RevoCollectionFolders extends ConsumerStatefulWidget {
  final ApiConfig? selectedConfig;
  final ValueChanged<ApiConfig?> onSelectedConfigChanged;

  const RevoCollectionFolders({
    super.key,
    required this.selectedConfig,
    required this.onSelectedConfigChanged,
  });

  @override
  ConsumerState<RevoCollectionFolders> createState() => _RevoCollectionFoldersState();
}

class _RevoCollectionFoldersState extends ConsumerState<RevoCollectionFolders> {
  String _searchQuery = '';

  void _showCollectionSettingsDialog(BuildContext context, ApiCollection collection) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final notifier = ref.read(apiCollectionsProvider.notifier);
            return AlertDialog(
              backgroundColor: RevoTheme.sidebarBackground,
              title: Text(
                "Folder Properties: ${collection.name}",
                style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 450,
                height: 480,
                child: ListView(
                  children: [
                    _buildModalTextField(
                      label: "Folder/Collection Name",
                      initialValue: collection.name,
                      onChanged: (val) {
                        final upd = collection.copyWith(name: val);
                        notifier.updateCollection(collection.id, upd);
                      },
                    ),
                    _buildModalTextField(
                      label: "Description",
                      initialValue: collection.description,
                      onChanged: (val) {
                        final upd = collection.copyWith(description: val);
                        notifier.updateCollection(collection.id, upd);
                      },
                    ),
                    _buildModalTextField(
                      label: "Folder Base URL (Inherited by sub-calls)",
                      initialValue: collection.baseUrl,
                      onChanged: (val) {
                        final upd = collection.copyWith(baseUrl: val);
                        notifier.updateCollection(collection.id, upd);
                      },
                    ),
                    const Divider(),
                    _buildFolderAuthPanel(collection, notifier, setModalState),
                    const Divider(),
                    _buildFolderHeadersEditor(collection, notifier, setModalState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Done", style: TextStyle(fontSize: 11)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModalTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 11),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderAuthPanel(
    ApiCollection collection,
    ApiCollectionsNotifier notifier,
    StateSetter setModalState,
  ) {
    final authTypes = ['None', 'Bearer Token', 'Basic Auth', 'API Key', 'OAuth2'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Inherited Authentication", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: collection.authentication,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          onChanged: (val) {
            final upd = collection.copyWith(authentication: val ?? 'None');
            notifier.updateCollection(collection.id, upd);
            setModalState(() {});
          },
          items: authTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
        if (collection.authentication == 'Bearer Token') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: collection.authPassword,
            decoration: const InputDecoration(labelText: "Inherited Token", isDense: true),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final upd = collection.copyWith(authPassword: val);
              notifier.updateCollection(collection.id, upd);
            },
          ),
        ] else if (collection.authentication == 'Basic Auth') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: collection.authUsername,
            decoration: const InputDecoration(labelText: "Inherited Username", isDense: true),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final upd = collection.copyWith(authUsername: val);
              notifier.updateCollection(collection.id, upd);
            },
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: collection.authPassword,
            decoration: const InputDecoration(labelText: "Inherited Password", isDense: true),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final upd = collection.copyWith(authPassword: val);
              notifier.updateCollection(collection.id, upd);
            },
          ),
        ] else if (collection.authentication == 'API Key') ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: collection.apiKeyName,
            decoration: const InputDecoration(labelText: "Inherited API Key Header Name", isDense: true),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final upd = collection.copyWith(apiKeyName: val);
              notifier.updateCollection(collection.id, upd);
            },
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: collection.apiKeyValue,
            decoration: const InputDecoration(labelText: "Inherited API Key Value", isDense: true),
            style: const TextStyle(fontSize: 11),
            onChanged: (val) {
              final upd = collection.copyWith(apiKeyValue: val);
              notifier.updateCollection(collection.id, upd);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFolderHeadersEditor(
    ApiCollection collection,
    ApiCollectionsNotifier notifier,
    StateSetter setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Inherited Headers", style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF5B4FCF)),
              onPressed: () {
                final headers = Map<String, String>.from(collection.headers);
                int idx = 1;
                while (headers.containsKey('header_$idx')) {
                  idx++;
                }
                headers['header_$idx'] = 'value';
                final upd = collection.copyWith(headers: headers);
                notifier.updateCollection(collection.id, upd);
                setModalState(() {});
              },
            ),
          ],
        ),
        ...collection.headers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    onChanged: (newKey) {
                      if (newKey.trim().isEmpty || newKey == entry.key) return;
                      final headers = Map<String, String>.from(collection.headers);
                      final val = headers.remove(entry.key);
                      headers[newKey] = val ?? '';
                      final upd = collection.copyWith(headers: headers);
                      notifier.updateCollection(collection.id, upd);
                      setModalState(() {});
                    },
                    style: const TextStyle(fontSize: 10),
                    decoration: const InputDecoration(hintText: "Key", isDense: true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    onChanged: (newVal) {
                      final headers = Map<String, String>.from(collection.headers);
                      headers[entry.key] = newVal;
                      final upd = collection.copyWith(headers: headers);
                      notifier.updateCollection(collection.id, upd);
                    },
                    style: const TextStyle(fontSize: 10),
                    decoration: const InputDecoration(hintText: "Value", isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                  onPressed: () {
                    final headers = Map<String, String>.from(collection.headers);
                    headers.remove(entry.key);
                    final upd = collection.copyWith(headers: headers);
                    notifier.updateCollection(collection.id, upd);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showNewFolderDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: const Text("New Folder / Collection", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(hintText: "Enter folder name", isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final id = 'coll_${DateTime.now().millisecondsSinceEpoch}';
                ref.read(apiCollectionsProvider.notifier).addCollection(
                  ApiCollection(id: id, name: name, baseUrl: 'https://api.example.com'),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Create", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(apiCollectionsProvider);
    final apis = ref.watch(apiConfigsProvider);
    final apiNotifier = ref.read(apiConfigsProvider.notifier);

    // Grouping & Filtering
    final filteredApis = apis.where((api) {
      final query = _searchQuery.toLowerCase();
      return api.name.toLowerCase().contains(query) || api.endpoint.toLowerCase().contains(query);
    }).toList();

    final Map<String, List<ApiConfig>> groupedApis = {};
    for (final api in filteredApis) {
      final colId = api.collectionId.isEmpty ? 'General' : api.collectionId;
      groupedApis.putIfAbsent(colId, () => []).add(api);
    }

    return Column(
      children: [
        // Sidebar header with folder creator and search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "API Collections",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined, size: 16, color: Color(0xFF5B4FCF)),
                    tooltip: "New Folder",
                    onPressed: () => _showNewFolderDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                style: const TextStyle(fontSize: 11),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: "Search requests...",
                  prefixIcon: Icon(Icons.search_rounded, size: 14),
                  isDense: true,
                  contentPadding: EdgeInsets.all(6),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            children: [
              // 1. Defined Collections (Folders)
              ...collections.map((coll) {
                final subApis = groupedApis[coll.id] ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            coll.name,
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 13),
                          onPressed: () => _showCollectionSettingsDialog(context, coll),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.folder_open_rounded, size: 14, color: Colors.amber),
                    initiallyExpanded: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF5B4FCF)),
                          onPressed: () {
                            final id = 'api_${DateTime.now().millisecondsSinceEpoch}';
                            final newApi = ApiConfig(
                              id: id,
                              name: 'New Custom Endpoint',
                              baseUrl: '',
                              endpoint: '/v1/resource',
                              method: 'GET',
                              collectionId: coll.id,
                              inheritParentSettings: true,
                            );
                            apiNotifier.addConfig(newApi);
                            widget.onSelectedConfigChanged(newApi);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    children: subApis.map((api) {
                      final isSelected = widget.selectedConfig?.id == api.id;
                      return ListTile(
                        onTap: () => widget.onSelectedConfigChanged(api),
                        selected: isSelected,
                        selectedColor: RevoTheme.primary,
                        selectedTileColor: RevoTheme.primary.withValues(alpha: 0.05),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMethodColor(api.method).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            api.method,
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _getMethodColor(api.method),
                            ),
                          ),
                        ),
                        title: Text(
                          api.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                          onPressed: () {
                            if (widget.selectedConfig?.id == api.id) {
                              widget.onSelectedConfigChanged(null);
                            }
                            apiNotifier.deleteConfig(api.id);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
              // 2. Unassigned / General requests
              () {
                final generalApis = groupedApis['General'] ?? [];
                if (generalApis.isEmpty) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      "General Endpoints",
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                    ),
                    leading: const Icon(Icons.cloud_queue_rounded, size: 14, color: Colors.blueGrey),
                    initiallyExpanded: true,
                    children: generalApis.map((api) {
                      final isSelected = widget.selectedConfig?.id == api.id;
                      return ListTile(
                        onTap: () => widget.onSelectedConfigChanged(api),
                        selected: isSelected,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMethodColor(api.method).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            api.method,
                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: _getMethodColor(api.method)),
                          ),
                        ),
                        title: Text(api.name, style: GoogleFonts.inter(fontSize: 11), overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                          onPressed: () {
                            if (widget.selectedConfig?.id == api.id) {
                              widget.onSelectedConfigChanged(null);
                            }
                            apiNotifier.deleteConfig(api.id);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }(),
            ],
          ),
        ),
      ],
    );
  }
}
