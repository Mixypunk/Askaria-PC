import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../../main.dart';
import 'artwork_widget.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? queue;
  final int? index;
  final bool showNumber;
  final VoidCallback? onTap;

  const SongTile({
    super.key, required this.song,
    this.queue, this.index, this.showNumber = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong == song;

    return InkWell(
      onTap: onTap ?? () => context.read<PlayerProvider>().playSong(
        song, queue: queue ?? [song], index: index ?? 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          // Artwork / number
          if (showNumber)
            SizedBox(width: 40, child: Center(
              child: isCurrent
                  ? const Icon(Icons.equalizer_rounded, size: 18, color: Sp.ac)
                  : Text('${(index ?? 0) + 1}',
                      style: const TextStyle(color: Sp.t2, fontSize: 13)),
            ))
          else
            ArtworkWidget(
              key: ValueKey(song.hash),
              hash: song.image ?? song.hash,
              size: 46,
              borderRadius: BorderRadius.circular(8),
            ),
          const SizedBox(width: 12),
          // Text
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title,
                style: TextStyle(
                  color: isCurrent ? Sp.ac : Sp.t1,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(song.artist,
                style: const TextStyle(color: Sp.t2, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          // Duration + menu
          Text(song.formattedDuration,
            style: const TextStyle(color: Sp.t3, fontSize: 12)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Sp.t3),
            color: Sp.bg3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'next',  child: Text('Lire ensuite')),
              PopupMenuItem(value: 'queue', child: Text('Ajouter à la file')),
            ],
            onSelected: (v) {
              final p = context.read<PlayerProvider>();
              if (v == 'next') {
                p.addNextInQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${song.title} → lire ensuite', style: const TextStyle(color: Sp.t1)),
                  backgroundColor: Sp.bg2,
                  duration: const Duration(seconds: 2),
                ));
              } else {
                p.addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${song.title} ajouté', style: const TextStyle(color: Sp.t1)),
                  backgroundColor: Sp.bg2,
                  duration: const Duration(seconds: 2),
                ));
              }
            },
          ),
        ]),
      ),
    );
  }
}
