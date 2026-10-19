import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/media_item.dart';

/// Creates or edits a title in the local collection.
class AddTitlePage extends StatefulWidget {
  final MediaItem? initialItem;
  final bool Function(MediaItem, {MediaItem? replacing}) onSave;
  final String? draftTitle;
  final String? draftType;
  final String? draftStatus;
  final void Function(String title, String type, String status) onDraftChanged;

  const AddTitlePage({
    super.key,
    this.initialItem,
    this.draftTitle,
    this.draftType,
    this.draftStatus,
    required this.onSave,
    required this.onDraftChanged,
  });

  @override
  State<AddTitlePage> createState() => _AddTitlePageState();
}

class _AddTitlePageState extends State<AddTitlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late String _type = widget.draftType ?? widget.initialItem?.type ?? 'Anime';
  late String _status =
      widget.draftStatus ?? widget.initialItem?.status ?? defaultStatus(_type);

  @override
  void initState() {
    super.initState();
    _titleController.text =
        widget.draftTitle ?? widget.initialItem?.title ?? '';
    _titleController.addListener(_saveDraft);
  }

  void _saveDraft() =>
      widget.onDraftChanged(_titleController.text, _type, _status);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.initialItem;
    final item = MediaItem(
      malId: original?.malId ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      imageUrl: original?.imageUrl,
      type: _type,
      status: _status,
      updatedAt: DateTime.now(),
    );

    if (!widget.onSave(item, replacing: original)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A title with this name and type is already listed'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          original == null
              ? 'Added "${item.title}"'
              : 'Updated "${item.title}"',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final statuses = statusesFor(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem == null ? 'Add title' : 'Edit title'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.tile, AppColors.card],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(typeIcon(_type), color: AppColors.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialItem == null
                                ? 'Save something to enjoy'
                                : 'Update your title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Keep your watchlist in one place',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _label('Title name'),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: InputDecoration(
                  prefixIcon: Icon(typeIcon(_type)),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title name';
                  }
                  if (v.trim().length < 2) return 'Title is too short';
                  return null;
                },
              ),
              _label('Type'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Anime', label: Text('Anime')),
                    ButtonSegment(value: 'Movie', label: Text('Movie')),
                    ButtonSegment(value: 'Manga', label: Text('Manga')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    setState(() {
                      _type = s.first;
                      if (!statusesFor(_type).contains(_status)) {
                        _status = defaultStatus(_type);
                      }
                    });
                    _saveDraft();
                  },
                ),
              ),
              _label('Status'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s),
                        selected: _status == s,
                        onSelected: (_) {
                          setState(() => _status = s);
                          _saveDraft();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    widget.initialItem == null ? Icons.add : Icons.check,
                  ),
                  label: Text(
                    widget.initialItem == null ? 'Add to list' : 'Save changes',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
