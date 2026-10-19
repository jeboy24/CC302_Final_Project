import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/media_item.dart';
import 'add_title_page.dart';
import 'home_page.dart';
import 'list_page.dart';
import 'profile_page.dart';

/// Holds the app state + bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _loading = true;
  bool _draftOpen = false;
  String _name = 'MediaLog User';
  String _listQuery = '';
  String _listFilter = 'All';
  String _draftTitle = '';
  String _draftType = 'Anime';
  String _draftStatus = defaultStatus('Anime');
  String? _draftEditingKey;
  Future<void> _draftPersistence = Future<void>.value();
  Future<void> _viewPersistence = Future<void>.value();
  List<MediaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('items');
    final name = prefs.getString('name');
    final savedIndex = prefs.getInt('selectedTab') ?? 0;
    final listView = prefs.getString('listView');
    final draft = prefs.getString('activeDraft');
    setState(() {
      if (raw != null) {
        _items = (jsonDecode(raw) as List)
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (name != null) _name = name;
      _index = savedIndex >= 0 && savedIndex < 3 ? savedIndex : 0;
      if (listView != null) {
        final view = jsonDecode(listView) as Map<String, dynamic>;
        _listQuery = view['query'] as String? ?? '';
        final savedFilter = view['filter'] as String? ?? 'All';
        _listFilter = savedFilter == 'All' || allStatuses.contains(savedFilter)
            ? savedFilter
            : 'All';
      }
      if (draft != null) {
        final savedDraft = jsonDecode(draft) as Map<String, dynamic>;
        _draftOpen = savedDraft['open'] as bool? ?? false;
        _draftTitle = savedDraft['title'] as String? ?? '';
        _draftType = savedDraft['type'] as String? ?? 'Anime';
        _draftStatus =
            savedDraft['status'] as String? ?? defaultStatus(_draftType);
        _draftEditingKey = savedDraft['editingKey'] as String?;
      }
      _loading = false;
    });
    if (_draftOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pushDraftRoute();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'items',
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
    await prefs.setString('name', _name);
  }

  bool _isAdded(MediaItem item, {MediaItem? replacing}) => _items.any(
    (e) =>
        e.key != replacing?.key &&
        (e.key == item.key ||
            (e.type == item.type &&
                e.title.toLowerCase() == item.title.toLowerCase())),
  );

  bool _addItem(MediaItem item) {
    if (_isAdded(item)) return false;
    setState(() => _items.add(item));
    _save();
    return true;
  }

  bool _saveItem(MediaItem item, {MediaItem? replacing}) {
    if (_isAdded(item, replacing: replacing)) return false;
    final index = replacing == null
        ? -1
        : _items.indexWhere((e) => e.key == replacing.key);
    if (replacing != null && index == -1) return false;
    setState(() {
      if (replacing == null) {
        _items.add(item);
      } else {
        _items[index] = item;
      }
    });
    _save();
    return true;
  }

  void _updateStatus(MediaItem item, String status) {
    setState(() {
      item.status = status;
      item.updatedAt = DateTime.now();
    });
    _save();
  }

  void _deleteItem(MediaItem item) {
    setState(() => _items.removeWhere((e) => e.key == item.key));
    _save();
  }

  void _clearAll() {
    setState(() => _items = []);
    _save();
  }

  void _setName(String name) {
    setState(() => _name = name);
    _save();
  }

  void _changeTab(int index) {
    setState(() => _index = index);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('selectedTab', index),
    );
  }

  Future<void> _openAdd() async {
    _draftTitle = '';
    _draftType = 'Anime';
    _draftStatus = defaultStatus(_draftType);
    _draftEditingKey = null;
    _draftOpen = true;
    await _persistDraft();
    if (mounted) _pushDraftRoute();
  }

  Future<void> _openEdit(MediaItem item) async {
    _draftTitle = item.title;
    _draftType = item.type;
    _draftStatus = item.status;
    _draftEditingKey = item.key;
    _draftOpen = true;
    await _persistDraft();
    if (mounted) _pushDraftRoute();
  }

  Future<void> _persistDraft() {
    final raw = jsonEncode({
      'open': _draftOpen,
      'title': _draftTitle,
      'type': _draftType,
      'status': _draftStatus,
      'editingKey': _draftEditingKey,
    });
    _draftPersistence = _draftPersistence.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeDraft', raw);
    });
    return _draftPersistence;
  }

  void _onDraftChanged(String title, String type, String status) {
    _draftTitle = title;
    _draftType = type;
    _draftStatus = status;
    _persistDraft();
  }

  void _pushDraftRoute() {
    MediaItem? original;
    for (final item in _items) {
      if (item.key == _draftEditingKey) {
        original = item;
        break;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTitlePage(
          initialItem: original,
          draftTitle: _draftTitle,
          draftType: _draftType,
          draftStatus: _draftStatus,
          onSave: _saveItem,
          onDraftChanged: _onDraftChanged,
        ),
      ),
    ).then((_) => _closeDraft());
  }

  Future<void> _closeDraft() async {
    _draftOpen = false;
    _draftPersistence = _draftPersistence.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeDraft');
    });
    await _draftPersistence;
  }

  void _onListViewStateChanged(String query, String filter) {
    _listQuery = query;
    _listFilter = filter;
    final raw = jsonEncode({'query': query, 'filter': filter});
    _viewPersistence = _viewPersistence.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('listView', raw);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        items: _items,
        onAdd: _addItem,
        onOpenAdd: _openAdd,
        onSeeAll: () => _changeTab(1),
      ),
      ListPage(
        items: _items,
        onAdd: _addItem,
        onOpenAdd: _openAdd,
        onUpdate: _updateStatus,
        onDelete: _deleteItem,
        onEdit: _openEdit,
        initialQuery: _listQuery,
        initialFilter: _listFilter,
        onViewStateChanged: _onListViewStateChanged,
      ),
      ProfilePage(
        items: _items,
        name: _name,
        onNameChanged: _setName,
        onClearAll: _clearAll,
      ),
    ];

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
