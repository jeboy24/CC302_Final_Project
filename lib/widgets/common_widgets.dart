import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/media_item.dart';

// ---------- Helpers ----------
Future<String?> showStatusSheet(
  BuildContext context,
  String type, {
  String? current,
  String? title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title ?? 'Set status',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ...statusesFor(type).map(
            (s) => ListTile(
              leading: Icon(
                s == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: statusColor(s),
              ),
              title: Text(s),
              onTap: () => Navigator.pop(context, s),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Asks for a status, then adds the item. Shows feedback.
Future<void> promptAdd(
  BuildContext context,
  MediaItem item,
  bool Function(MediaItem) onAdd,
) async {
  final status = await showStatusSheet(context, item.type, title: item.title);
  if (status == null || !context.mounted) return;
  item.status = status;
  item.updatedAt = DateTime.now();
  final ok = onAdd(item);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? 'Added "${item.title}"' : 'Already in your list'),
  ));
}

// ---------- Custom widgets ----------
class PosterThumb extends StatelessWidget {
  final String? url;
  final String type;
  final double width;
  final double height;

  const PosterThumb({
    super.key,
    required this.url,
    required this.type,
    this.width = 48,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.iconBg,
      child: Icon(typeIcon(type), color: Colors.white),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url == null
          ? fallback
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}

class MediaTile extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MediaTile({super.key, required this.item, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: PosterThumb(url: item.imageUrl, type: item.type),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(TextSpan(children: [
        TextSpan(
          text: item.status,
          style: TextStyle(color: statusColor(item.status)),
        ),
        TextSpan(
          text: '  •  ${item.type}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ])),
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final int value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.accent, fontSize: 15)),
          const SizedBox(height: 6),
          Text('$value',
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const StateMessage({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}