import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/providers/player_provider.dart';
import '../../core/services/api_service.dart';

class PlayerBar extends StatelessWidget {
  final VoidCallback? onLyricsPressed;
  const PlayerBar({super.key, this.onLyricsPressed});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${d.inMinutes}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final currentSong = player.currentSong;
    final api = SwingApiService();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withValues(alpha: 0.97),
            border: Border(top: BorderSide(color: Sp.bd)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              // 1. Zone Gauche — Info + favorites + lyrics
              SizedBox(
                width: 260,
                child: currentSong != null
                    ? Row(
                        children: [
                          // Pochette — cliquable pour paroles
                          GestureDetector(
                            onTap: onLyricsPressed,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(7)),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: '${api.baseUrl}/img/thumbnail/${currentSong.image ?? currentSong.hash}',
                                  httpHeaders: api.authHeaders,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Sp.t3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentSong.title,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Sp.t1, fontWeight: FontWeight.w500, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(currentSong.artist,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Sp.t2, fontSize: 11)),
                              ],
                            ),
                          ),
                          // Favoris
                          IconButton(
                            splashRadius: 20, padding: const EdgeInsets.all(4),
                            icon: Icon(
                              player.isFavourite(currentSong.hash)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: player.isFavourite(currentSong.hash) ? Sp.ac : Sp.t3,
                              size: 18,
                            ),
                            onPressed: () => player.toggleFavourite(currentSong.hash),
                          ),
                          // Paroles
                          IconButton(
                            splashRadius: 20, padding: const EdgeInsets.all(4),
                            icon: Icon(
                              Icons.lyrics_outlined,
                              color: (onLyricsPressed != null) ? Sp.t3 : Sp.t4,
                              size: 18,
                            ),
                            onPressed: onLyricsPressed,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // 2. Zone Centrale
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            splashRadius: 24, iconSize: 20,
                            icon: const Icon(Icons.shuffle_rounded),
                            color: player.shuffle ? Sp.ac : Sp.t3,
                            onPressed: player.toggleShuffle,
                          ),
                          IconButton(
                            splashRadius: 24, iconSize: 24,
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: Sp.t1, onPressed: player.previous,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: Sp.t1, shape: BoxShape.circle),
                            child: IconButton(
                              padding: EdgeInsets.zero, splashRadius: 18,
                              icon: Icon(
                                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Sp.bg0, size: 22,
                              ),
                              onPressed: player.playPause,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            splashRadius: 24, iconSize: 24,
                            icon: const Icon(Icons.skip_next_rounded),
                            color: Sp.t1, onPressed: player.next,
                          ),
                          IconButton(
                            splashRadius: 24, iconSize: 20,
                            icon: Icon(player.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded),
                            color: player.repeatMode != RepeatMode.off ? Sp.ac : Sp.t3,
                            onPressed: player.toggleRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 35,
                              child: Text(_formatDuration(player.position),
                                  style: const TextStyle(color: Sp.t3, fontSize: 10.5),
                                  textAlign: TextAlign.right),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SliderTheme(
                                data: const SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                                  activeTrackColor: Sp.t2,
                                  inactiveTrackColor: Sp.bg5,
                                  thumbColor: Colors.white,
                                  trackShape: RectangularSliderTrackShape(),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                                ),
                                child: Slider(
                                  value: player.duration.inMilliseconds > 0
                                      ? player.position.inMilliseconds.toDouble()
                                      : 0.0,
                                  min: 0.0,
                                  max: player.duration.inMilliseconds > 0
                                      ? player.duration.inMilliseconds.toDouble()
                                      : 1.0,
                                  onChanged: (val) => player.seek(Duration(milliseconds: val.toInt())),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 35,
                              child: Text(_formatDuration(player.duration),
                                  style: const TextStyle(color: Sp.t3, fontSize: 10.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Zone Droite — Volume
              SizedBox(
                width: 260,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      splashRadius: 20, iconSize: 18,
                      icon: Icon(
                        player.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Sp.t3,
                      ),
                      onPressed: () => player.setVolume(player.volume == 0 ? 1.0 : 0.0),
                    ),
                    SizedBox(
                      width: 76,
                      child: SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                          activeTrackColor: Sp.t2,
                          inactiveTrackColor: Sp.bg5,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: player.volume,
                          min: 0.0, max: 1.0,
                          onChanged: player.setVolume,
                        ),
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
