import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/models/song.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/player_provider.dart';
import 'toast_service.dart';
import 'add_to_playlist_dialog.dart';

/// Widget réutilisable — tableau de titres avec header + rows animés.
/// Utilisé dans : SongsPage, FavouritesPage, AlbumDetail, ArtistDetail, PlaylistDetail.
class SongTable extends StatelessWidget {
  final List<Song> songs;
  final bool showAlbumColumn;
  final bool showHeader;

  const SongTable({
    super.key,
    required this.songs,
    this.showAlbumColumn = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 36, child: Text('#', style: _headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Titre', style: _headerStyle)),
                if (showAlbumColumn) ...[
                  const SizedBox(width: 10),
                  const SizedBox(width: 160, child: Text('Album', style: _headerStyle)),
                ],
                const SizedBox(width: 10),
                const SizedBox(width: 60, child: Text('Durée', style: _headerStyle, textAlign: TextAlign.right)),
                const SizedBox(width: 10),
                const SizedBox(width: 36),
              ],
            ),
          ),
        if (showHeader)
          Divider(color: Sp.bd, height: 1),
        if (showHeader) const SizedBox(height: 2),
        ...songs.asMap().entries.map((e) => SongRow(
          song: e.value,
          index: e.key,
          queue: songs,
          showAlbumColumn: showAlbumColumn,
        )),
      ],
    );
  }

  static const _headerStyle = TextStyle(
    color: Sp.t4,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.07,
  );
}

class SongRow extends StatefulWidget {
  final Song song;
  final int index;
  final List<Song> queue;
  final bool showAlbumColumn;
  final VoidCallback? onAlbumTap;
  final VoidCallback? onArtistTap;

  const SongRow({
    super.key,
    required this.song,
    required this.index,
    required this.queue,
    this.showAlbumColumn = true,
    this.onAlbumTap,
    this.onArtistTap,
  });

  @override
  State<SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<SongRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final api = SwingApiService();
    final isPlaying = player.currentSong?.hash == widget.song.hash;
    final isFav = player.isFavourite(widget.song.hash);

    return GestureDetector(
      onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => player.playSong(widget.song, queue: widget.queue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isPlaying
                  ? Sp.ac4
                  : (_hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                // Numéro / icône equalizer
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: isPlaying
                        ? const _EqBars()
                        : (_hover
                            ? const Icon(Icons.play_arrow_rounded, color: Sp.t1, size: 16)
                            : Text('${widget.index + 1}',
                                style: const TextStyle(color: Sp.t3, fontSize: 12.5))),
                  ),
                ),
                const SizedBox(width: 10),
                // Artwork + Titre + Artiste
                Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: api.getArtworkUrl(widget.song.image ?? widget.song.hash),
                          httpHeaders: api.authHeaders,
                          width: 36, height: 36,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 36, height: 36, color: Sp.bg4,
                            child: const Icon(Icons.music_note_rounded, color: Sp.t3, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.song.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? Sp.ac : Sp.t1,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                )),
                            Text(widget.song.artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Album
                if (widget.showAlbumColumn) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 160,
                    child: Text(widget.song.album,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Sp.t2, fontSize: 12)),
                  ),
                ],
                const SizedBox(width: 10),
                // Durée
                SizedBox(
                  width: 60,
                  child: Text(widget.song.formattedDuration,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Sp.t2, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                // Favori
                SizedBox(
                  width: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 14,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Sp.ac : (_hover ? Sp.t3 : Colors.transparent),
                      size: 15,
                    ),
                    onPressed: () => player.toggleFavourite(widget.song.hash),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) {
    final player = context.read<PlayerProvider>();
    final api = SwingApiService();
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & MediaQuery.of(context).size,
      ),
      color: Sp.bg3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(color: Sp.bd2)),
      items: [
        _menuItem('next', Icons.queue_play_next_rounded, 'Écouter ensuite'),
        _menuItem('radio', Icons.radio_rounded, 'Lancer la radio'),
        _menuItem('playlist', Icons.playlist_add_rounded, 'Ajouter à une playlist'),
        const PopupMenuDivider(height: 1),
        _menuItem('fav', Icons.favorite_rounded, 'Ajouter aux favoris'),
      ],
    ).then((value) async {
      if (!context.mounted) return;
      switch (value) {
        case 'next':
          player.addNextInQueue(widget.song);
          ToastService.show(context, 'Écouter ensuite : ${widget.song.title}');
          break;
        case 'radio':
          _startRadio(context, player, api);
          break;
        case 'playlist':
          await showAddToPlaylistDialog(context, trackHashes: [widget.song.hash]);
          break;
        case 'fav':
          await player.toggleFavourite(widget.song.hash);
          if (context.mounted) {
            ToastService.show(context, player.isFavourite(widget.song.hash)
                ? 'Ajouté aux favoris'
                : 'Retiré des favoris');
          }
          break;
      }
    });
  }

  Future<void> _startRadio(BuildContext context, PlayerProvider player, SwingApiService api) async {
    ToastService.show(context, 'Chargement de la radio...');
    final tracks = await api.getRadio(widget.song.hash);
    if (tracks.isNotEmpty && context.mounted) {
      player.playSong(tracks.first, queue: tracks);
      ToastService.show(context, 'Radio lancée depuis "${widget.song.title}"');
    }
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool danger = false}) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 14, color: danger ? Colors.redAccent : Sp.t2),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: danger ? Colors.redAccent : Sp.t2, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _EqBars extends StatefulWidget {
  const _EqBars();
  @override
  State<_EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<_EqBars> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + i * 150),
      )..repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, __) {
            final h = 3 + (_ctrls[i].value * 10);
            return Container(
              width: 2.5,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Sp.ac,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        );
      }),
    );
  }
}
