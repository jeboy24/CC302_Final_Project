import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/media_item.dart';
import '../services/media_api.dart';
import '../widgets/common_widgets.dart';

class HomePage extends StatefulWidget {
  final List<MediaItem> items;
  final bool Function(MediaItem) onAdd;
  final VoidCallback onOpenAdd;
  final VoidCallback onSeeAll;

  const HomePage({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onOpenAdd,
    required this.onSeeAll,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<MediaItem>> _top;

  @override
  void initState() {
    super.initState();
    _top = MediaApi.topAnime();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final watching =
        items.where((e) => e.status == 'Currently Watching').length;
    final recent = ([...items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.card, Color(0xFF211B32)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR MEDIA SPACE',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              )),
                          SizedBox(height: 7),
                          Text('MediaLog',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Your personal media tracker',
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.iconBg.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.movie_creation_outlined,
                          color: AppColors.accent, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                        child:
                            StatCard(label: 'Total titles', value: items.length)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: StatCard(
                            label: 'Currently watching', value: watching)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text('My Watchlist',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    if (items.isNotEmpty)
                      TextButton(
                          onPressed: widget.onSeeAll,
                          child: const Text('See all')),
                  ],
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: StateMessage(
                      icon: Icons.inbox_outlined,
                      message: 'No titles yet. Add your first one!',
                      buttonLabel: 'Add title',
                      onPressed: widget.onOpenAdd,
                    ),
                  )
                else
                  Material(
                    color: AppColors.tile,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < recent.length; i++) ...[
                          MediaTile(item: recent[i], onTap: widget.onSeeAll),
                          if (i != recent.length - 1)
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Discover (API)
          const Text('Discover: Top Anime',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Tap a poster to add it to your list',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: FutureBuilder<List<MediaItem>>(
              future: _top,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return StateMessage(
                    icon: Icons.wifi_off,
                    message: 'Could not load data.\nCheck your connection.',
                    buttonLabel: 'Retry',
                    onPressed: () =>
                        setState(() => _top = MediaApi.topAnime()),
                  );
                }
                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const StateMessage(
                      icon: Icons.search_off, message: 'No data available.');
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final item = data[i];
                    return GestureDetector(
                      onTap: () => promptAdd(context, item, widget.onAdd),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PosterThumb(
                                url: item.imageUrl,
                                type: item.type,
                                width: 120,
                                height: 160),
                            const SizedBox(height: 6),
                            Text(item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}