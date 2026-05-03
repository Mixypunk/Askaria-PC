import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/providers/player_provider.dart';
import '../../core/services/api_service.dart';

// â”€â”€ Inherited widget lÃ©ger pour passer le callback paroles sans rebuild â”€â”€â”€â”€â”€â”€
class _LyricsCallbackScope extends InheritedWidget {
  final VoidCallback? onLyricsPressed;
  const _LyricsCallbackScope({required this.onLyricsPressed, required super.child});

  static VoidCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LyricsCallbackScope>()?.onLyricsPressed;

  @override
  bool updateShouldNotify(_LyricsCallbackScope old) =>
      old.onLyricsPressed != onLyricsPressed;
}

/// Barre de lecture principale â€” 3 zones isolÃ©es par RepaintBoundary.
/// Le BackdropFilter ne se repaint plus lors des ticks de position.
class PlayerBar extends StatelessWidget {
  final VoidCallback? onLyricsPressed;
  const PlayerBar({super.key, this.onLyricsPressed});

  @override
  Widget build(BuildContext context) {
    return _LyricsCallbackScope(
      onLyricsPressed: onLyricsPressed,
      child: RepaintBoundary(
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF111111).withValues(alpha: 0.97),
                border: Border(top: BorderSide(color: Sp.bd)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const Row(
                children: [
                  SizedBox(width: 260, child: _PlayerLeft()),
                  Expanded(child: _PlayerCenter()),
                  SizedBox(width: 260, child: _PlayerRight()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Zone Gauche â€” Pochette + Titre + Artiste + Favoris
// Rebuild uniquement si currentSong ou isFavourite change
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PlayerLeft extends StatelessWidget {
  const _PlayerLeft();

  @override
  Widget build(BuildContext context) {
    final song = context.select<PlayerProvider, dynamic>((p) => p.currentSong);
    if (song == null) return const SizedBox.shrink();

    final isFav = context.select<PlayerProvider, bool>(
      (p) => p.isFavourite(song.hash),
    );
    final api = SwingApiService();
    final onLyrics = _LyricsCallbackScope.of(context);

    return RepaintBoundary(
      child: Row(
        children: [
          // Pochette â€” cliquable pour les paroles
          GestureDetector(
            onTap: onLyrics,
            child: MouseRegion(
              cursor: onLyrics != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Sp.bg4,
                  borderRadius: BorderRadius.circular(7),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl:
                      '${api.baseUrl}/img/thumbnail/${song.image ?? song.hash}',
                  httpHeaders: api.authHeaders,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.music_note_rounded, color: Sp.t3),
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
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Sp.t1,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Sp.t2, fontSize: 11),
                ),
              ],
            ),
          ),
          // Favoris
          IconButton(
            splashRadius: 20,
            padding: const EdgeInsets.all(4),
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Sp.ac : Sp.t3,
              size: 18,
            ),
            onPressed: () =>
                context.read<PlayerProvider>().toggleFavourite(song.hash),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Zone Centrale â€” ContrÃ´les + Slider de position + Paroles
// Rebuild Ã  chaque tick de position (200ms throttlÃ©)
// mais isolÃ©e des zones gauche et droite.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PlayerCenter extends StatelessWidget {
  const _PlayerCenter();

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inMinutes}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        context.select<PlayerProvider, bool>((p) => p.isPlaying);
    final shuffle =
        context.select<PlayerProvider, bool>((p) => p.shuffle);
    final repeatMode =
        context.select<PlayerProvider, PlayerRepeatMode>((p) => p.repeatMode);
    final position =
        context.select<PlayerProvider, Duration>((p) => p.position);
    final duration =
        context.select<PlayerProvider, Duration>((p) => p.duration);
    final hasSong =
        context.select<PlayerProvider, bool>((p) => p.currentSong != null);

    final player = context.read<PlayerProvider>();
    final onLyrics = _LyricsCallbackScope.of(context);

    final posMs = duration.inMilliseconds > 0
        ? position.inMilliseconds
            .toDouble()
            .clamp(0.0, duration.inMilliseconds.toDouble())
        : 0.0;
    final durMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // â”€â”€ ContrÃ´les â”€â”€
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                splashRadius: 24,
                iconSize: 20,
                icon: const Icon(Icons.shuffle_rounded),
                color: shuffle ? Sp.ac : Sp.t3,
                onPressed: player.toggleShuffle,
              ),
              IconButton(
                splashRadius: 24,
                iconSize: 24,
                icon: const Icon(Icons.skip_previous_rounded),
                color: Sp.t1,
                onPressed: player.previous,
              ),
              const SizedBox(width: 10),
              // Bouton Play/Pause
              Container(
                width: 36,
                height: 36,
                decoration:
                    const BoxDecoration(color: Sp.t1, shape: BoxShape.circle),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Sp.bg0,
                    size: 22,
                  ),
                  onPressed: player.playPause,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                splashRadius: 24,
                iconSize: 24,
                icon: const Icon(Icons.skip_next_rounded),
                color: Sp.t1,
                onPressed: player.next,
              ),
              IconButton(
                splashRadius: 24,
                iconSize: 20,
                icon: Icon(
                  repeatMode == PlayerRepeatMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                ),
                color: repeatMode != PlayerRepeatMode.off ? Sp.ac : Sp.t3,
                onPressed: player.toggleRepeat,
              ),
              // Paroles
              IconButton(
                splashRadius: 20,
                padding: const EdgeInsets.all(4),
                icon: Icon(
                  Icons.lyrics_outlined,
                  color: hasSong ? Sp.t3 : Sp.t4,
                  size: 18,
                ),
                onPressed: onLyrics,
              ),
            ],
          ),
          const SizedBox(height: 7),
          // â”€â”€ Slider de progression â”€â”€
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    _fmt(position),
                    style: const TextStyle(color: Sp.t3, fontSize: 10.5),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SliderTheme(
                    data: const SliderThemeData(
                      trackHeight: 4,
                      thumbShape:
                          RoundSliderThumbShape(enabledThumbRadius: 5),
                      activeTrackColor: Sp.t2,
                      inactiveTrackColor: Sp.bg5,
                      thumbColor: Colors.white,
                      trackShape: RectangularSliderTrackShape(),
                      overlayShape:
                          RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: posMs,
                      min: 0.0,
                      max: durMs,
                      onChanged: (val) =>
                          player.seek(Duration(milliseconds: val.toInt())),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 35,
                  child: Text(
                    _fmt(duration),
                    style: const TextStyle(color: Sp.t3, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Zone Droite â€” Volume
// Rebuild uniquement si volume change
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PlayerRight extends StatelessWidget {
  const _PlayerRight();

  @override
  Widget build(BuildContext context) {
    final volume =
        context.select<PlayerProvider, double>((p) => p.volume);
    final player = context.read<PlayerProvider>();

    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            splashRadius: 20,
            iconSize: 18,
            icon: Icon(
              volume == 0
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: Sp.t3,
            ),
            onPressed: () => player.setVolume(volume == 0 ? 1.0 : 0.0),
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
                value: volume,
                min: 0.0,
                max: 1.0,
                onChanged: player.setVolume,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
