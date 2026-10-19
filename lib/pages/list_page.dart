import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/media_item.dart';
import '../widgets/common_widgets.dart';

class ListPage extends StatefulWidget {
  final List<MediaItem> items;
  final bool Function(MediaItem) onAdd;
  final VoidCallback onOpenAdd;
  final void Function(MediaItem, String) onUpdate;
  final void Function(MediaItem) onDelete;
  final void Function(MediaItem) onEdit;
  final String initialQuery;
  final String initialFilter;
  final void Function(String query, String filter) onViewStateChanged;

  const ListPage({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onOpenAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onEdit,
    this.initialQuery = '',
    this.initialFilter = 'All',
    required this.onViewStateChanged,
  });

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late final TextEditingController _searchController;
  late String _query = widget.initialQuery;
  late String _filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateViewState({String? query, String? filter}) {
    setState(() {
      if (query != null) _query = query;
      if (filter != null) _filter = filter;
    });
    widget.onViewStateChanged(_query, _filter);
  }

  Future<void> _confirmDelete(MediaItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete title?'),
        content: Text('Remove "${item.title}" from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    widget.onDelete(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${item.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => widget.onAdd(item),
        ),
      ),
    );
  }

  Future<void> _changeStatus(MediaItem item) async {
    final s = await showStatusSheet(
      context,
      item.type,
      current: item.status,
      title: item.title,
    );
    if (s != null) widget.onUpdate(item, s);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((e) {
      final matchesQuery = e.title.toLowerCase().contains(
        _query.toLowerCase().trim(),
      );
      final matchesFilter = _filter == 'All' || e.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('My List')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onOpenAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add title'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your collection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tile,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.items.length} ${widget.items.length == 1 ? 'title' : 'titles'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _updateViewState(query: v),
              decoration: InputDecoration(
                hintText: 'Search your list',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['All', ...allStatuses]
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: _filter == s,
                        onSelected: (_) => _updateViewState(filter: s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? StateMessage(
                    icon: Icons.inbox_outlined,
                    message: widget.items.isEmpty
                        ? 'Your list is empty.\nTap "Add title" to start.'
                        : 'No titles match your search or filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: MediaTile(
                            item: item,
                            onTap: () => _changeStatus(item),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Title options',
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (action) {
                                if (action == 'edit') widget.onEdit(item);
                                if (action == 'delete') _confirmDelete(item);
                                if (action == 'status') {
                                  _changeStatus(item);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit title'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'status',
                                  child: ListTile(
                                    leading: Icon(Icons.sync_alt),
                                    title: Text('Change status'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFFF8A8A),
                                    ),
                                    title: Text('Delete title'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
