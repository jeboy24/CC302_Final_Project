import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/media_item.dart';
import '../widgets/common_widgets.dart';

class ProfilePage extends StatelessWidget {
  final List<MediaItem> items;
  final String name;
  final void Function(String) onNameChanged;
  final VoidCallback onClearAll;

  const ProfilePage({
    super.key,
    required this.items,
    required this.name,
    required this.onNameChanged,
    required this.onClearAll,
  });

  int _count(List<String> statuses) =>
      items.where((e) => statuses.contains(e.status)).length;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: name);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name cannot be empty'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(c, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) onNameChanged(result);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear all titles?'),
        content: const Text('This will permanently delete your whole list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Clear all')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      onClearAll();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('List cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.iconBg,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: 'Edit name',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editName(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              StatCard(label: 'Total titles', value: items.length),
              StatCard(
                  label: 'Completed',
                  value: _count(['Completed', 'Completed Reading'])),
              StatCard(
                  label: 'Currently watching/reading',
                  value: _count(['Currently Watching', 'Currently Reading'])),
              StatCard(label: 'Dropped', value: _count(['Dropped'])),
              
              StatCard(
                  label: 'Planned',
                  value: _count(['Plan to Watch', 'Plan to Read'])),
            ],
          ),
          const SizedBox(height: 20),
          const Text('By type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final t in ['Anime', 'Movie', 'Manga'])
            ListTile(
              leading: Icon(typeIcon(t), color: AppColors.accent),
              title: Text(t),
              trailing: Text('${items.where((e) => e.type == t).length}',
                  style: const TextStyle(fontSize: 18)),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: items.isEmpty ? null : () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear all titles'),
          ),
        ],
      ),
    );
  }
}