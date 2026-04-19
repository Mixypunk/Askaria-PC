import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/api_service.dart';
import '../../core/models/album.dart';
import '../../core/models/song.dart';
import '../../core/providers/player_provider.dart';
import '../../../main.dart'; // Sp Palette

class AlbumDetailPage extends StatefulWidget {
  final Album album;
  const AlbumDetailPage({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final _api = SwingApiService();
  List<Song> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await _api.getAlbumTracks(widget.album.hash);
      if (mounted) setState(() { _tracks = tracks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final artUrl = _api.getArtworkUrl(widget.album.image.isNotEmpty ? widget.album.image : widget.album.hash);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        children: [
          // Header façon Web (.dh)
          Container(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 22),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Sp.ac.withOpacity(0.13), Colors.transparent],
                stops: const [0, 0.4],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    color: Sp.bg4,
                    borderRadius: BorderRadius.circular(10), // --r: 10px
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 40, offset: const Offset(0, 8))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: artUrl,
                    httpHeaders: _api.authHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.album_rounded, color: Sp.t3, size: 80),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ALBUM', style: TextStyle(color: Sp.t2, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                      const SizedBox(height: 5),
                      Text(
                        widget.album.title,
                        style: const TextStyle(fontFamily: 'Segoe UI', color: Sp.t1, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.7, height: 1.1),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${widget.album.artist}${widget.album.year != null ? ' • ${widget.album.year}' : ''}',
                        style: const TextStyle(color: Sp.t2, fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      // Actions (.di-acts)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _tracks.isEmpty ? null : () => player.playSong(_tracks.first, queue: _tracks),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                              decoration: BoxDecoration(color: Sp.ac, borderRadius: BorderRadius.circular(50)),
                              child: Row(
                                children: const [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 7),
                                  Text('Lecture', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // En-tête de Table (.tblh)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: Border(bottom: BorderSide(color: Sp.bd)),
            margin: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: const [
                SizedBox(width: 36, child: Text('#', style: TextStyle(color: Sp.t4, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.7))),
                Expanded(child: Text('TITRE', style: TextStyle(color: Sp.t4, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.7))),
                SizedBox(width: 70, child: Text('DURÉE', style: TextStyle(color: Sp.t4, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.7), textAlign: TextAlign.right)),
                SizedBox(width: 42),
              ],
            ),
          ),

          // Liste des titres
          _loading
            ? Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: Sp.ac)))
            : ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  final isPlaying = player.currentSong?.hash == track.hash;

                  return _TrackRow(
                    track: track, index: index, isPlaying: isPlaying,
                    onTap: () => player.playSong(track, queue: _tracks, index: index),
                    formatDuration: _formatDuration,
                    isFavourite: player.isFavourite(track.hash),
                    onFavTap: () => player.toggleFavourite(track.hash),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatefulWidget {
  final Song track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final String Function(int?) formatDuration;
  final bool isFavourite;
  final VoidCallback onFavTap;

  const _TrackRow({
    required this.track, required this.index, required this.isPlaying, required this.onTap, required this.formatDuration, required this.isFavourite, required this.onFavTap,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isPlaying ? Sp.ac4 : (_hover ? Colors.white.withOpacity(0.04) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              // Colonne # (36px)
              SizedBox(
                width: 36,
                child: widget.isPlaying
                  ? const Icon(Icons.equalizer_rounded, color: Sp.ac, size: 16)
                  : (_hover
                      ? const Icon(Icons.play_arrow_rounded, color: Sp.t1, size: 18)
                      : Text('${widget.index + 1}', style: const TextStyle(color: Sp.t3, fontSize: 12.5))),
              ),
              
              // Colonne Titre (1fr)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: widget.isPlaying ? Sp.ac : Sp.t1, fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                    if (widget.track.artist != null)
                      Text(
                        widget.track.artist!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Sp.t2, fontSize: 11.5),
                      ),
                  ],
                ),
              ),

              // Colonne Durée (70px)
              SizedBox(
                width: 70,
                child: Text(widget.formatDuration(widget.track.duration), style: const TextStyle(color: Sp.t2, fontSize: 12), textAlign: TextAlign.right),
              ),

              // Actions (42px)
              SizedBox(
                width: 42,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    splashRadius: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    icon: Icon(widget.isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                    color: widget.isFavourite ? Sp.ac : Sp.t4,
                    iconSize: 16,
                    onPressed: widget.onFavTap,
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
