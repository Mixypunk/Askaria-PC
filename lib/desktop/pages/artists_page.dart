import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/album.dart';
import '../../core/models/song.dart';
import '../../core/providers/player_provider.dart';
import '../components/song_table.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  final _api = SwingApiService();
  List<Artist> _artists = [];
  bool _loading = true;
  Artist? _selected;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _api.getArtists(limit: 500);
      if (mounted) setState(() { _artists = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    if (_selected != null) {
      return _ArtistDetailView(
        artist: _selected!,
        api: _api,
        onBack: () => setState(() => _selected = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Artistes',
                  style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
              Text('${_artists.length} artistes', style: const TextStyle(color: Sp.t2, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
            child: Wrap(
              spacing: 13, runSpacing: 13,
              children: _artists.map((a) => _ArtistCard(
                artist: a,
                api: _api,
                onTap: () => setState(() => _selected = a),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistCard extends StatefulWidget {
  final Artist artist;
  final SwingApiService api;
  final VoidCallback onTap;
  const _ArtistCard({required this.artist, required this.api, required this.onTap});
  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final imgUrl = '${widget.api.baseUrl}/img/artist/small/${widget.artist.image}';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 155, padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg3 : Sp.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? Sp.bd2 : Colors.transparent),
            boxShadow: _hover
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 129, height: 129,
                    decoration: const BoxDecoration(color: Sp.bg4, shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedScale(
                      scale: _hover ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: CachedNetworkImage(
                        imageUrl: imgUrl,
                        httpHeaders: widget.api.authHeaders,
                        width: 129, height: 129,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Sp.t3, size: 48),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: AnimatedOpacity(
                      opacity: _hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 34, height: 34,
                        decoration: const BoxDecoration(color: Sp.ac, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(widget.artist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text('${widget.artist.albumCount} album${widget.artist.albumCount != 1 ? 's' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistDetailView extends StatefulWidget {
  final Artist artist;
  final SwingApiService api;
  final VoidCallback onBack;
  const _ArtistDetailView({required this.artist, required this.api, required this.onBack});
  @override
  State<_ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<_ArtistDetailView> {
  List<Album> _albums = [];
  List<Song> _tracks = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.api.getArtistAlbums(widget.artist.hash),
        widget.api.getArtistTracks(widget.artist.hash),
      ]);
      if (mounted) setState(() {
        _albums = results[0] as List<Album>;
        _tracks = results[1] as List<Song>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final imgUrl = '${widget.api.baseUrl}/img/artist/small/${widget.artist.image}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          _BackButton(onTap: widget.onBack),
          const SizedBox(height: 6),
          // Header artiste
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 180, height: 180,
                decoration: const BoxDecoration(color: Sp.bg4, shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  httpHeaders: widget.api.authHeaders,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Sp.t3, size: 60),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Artiste', style: TextStyle(color: Sp.t2, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1)),
                    const SizedBox(height: 5),
                    Text(widget.artist.name,
                        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 34, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.7),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 7),
                    Text('${widget.artist.albumCount} albums · ${_tracks.length} titres',
                        style: const TextStyle(color: Sp.t2, fontSize: 12.5)),
                    const SizedBox(height: 16),
                    if (_tracks.isNotEmpty)
                      _PlayButton(
                        onTap: () => player.playSong(_tracks.first, queue: _tracks),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Sp.ac))
          else ...[
            // Albums
            if (_albums.isNotEmpty) ...[
              const Text('Albums', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
              const SizedBox(height: 13),
              Wrap(
                spacing: 13, runSpacing: 13,
                children: _albums.map((album) => _SmallAlbumCard(album: album, api: widget.api)).toList(),
              ),
              const SizedBox(height: 28),
            ],
            // Titres
            if (_tracks.isNotEmpty) ...[
              const Text('Titres', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
              const SizedBox(height: 13),
              SongTable(songs: _tracks),
            ],
          ],
        ],
      ),
    );
  }
}

class _SmallAlbumCard extends StatefulWidget {
  final Album album;
  final SwingApiService api;
  const _SmallAlbumCard({required this.album, required this.api});
  @override
  State<_SmallAlbumCard> createState() => _SmallAlbumCardState();
}

class _SmallAlbumCardState extends State<_SmallAlbumCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.api.getArtworkUrl(widget.album.image.isNotEmpty ? widget.album.image : widget.album.hash);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 155, padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _hover ? Sp.bg3 : Sp.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hover ? Sp.bd : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 129, height: 129,
              decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: imgUrl, httpHeaders: widget.api.authHeaders,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.album_rounded, color: Sp.t3, size: 40),
              ),
            ),
            const SizedBox(height: 11),
            Text(widget.album.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(widget.album.year?.toString() ?? '', style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: Sp.t2, size: 14),
              SizedBox(width: 6),
              Text('Retour', style: TextStyle(color: Sp.t2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});
  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: _hover ? Sp.ac2 : Sp.ac,
            borderRadius: BorderRadius.circular(50),
            boxShadow: _hover
                ? [BoxShadow(color: Sp.ac.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 15),
              SizedBox(width: 8),
              Text('Lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
