import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // Palette Sp
import '../../core/services/api_service.dart';
import '../../core/models/song.dart';
import '../../core/models/album.dart';
import '../../core/providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'album_detail_page.dart';
import 'home_page.dart'; // Pour WebCard

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _api = SwingApiService();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _loading = false;
  String _query = '';
  Album? _selectedAlbum;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _songs = []; _albums = []; _query = ''; });
      return;
    }
    setState(() { _loading = true; _query = q; });
    try {
      final results = await Future.wait([
        _api.searchSongs(q),
        _api.searchTop(q),
      ]);
      final songs = results[0] as List<Song>;
      final topResult = results[1] as Map<String, dynamic>;
      final albumsRaw = topResult['albums'] ?? [];
      final albums = (albumsRaw as List).map((e) => Album.fromJson(e as Map<String,dynamic>)).toList();
      if (mounted) setState(() { _songs = songs; _albums = albums; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedAlbum != null) {
      return Stack(children: [
        AlbumDetailPage(album: _selectedAlbum!),
        Positioned(
          top: 16, left: 16,
          child: Container(
            decoration: BoxDecoration(color: Sp.bg0.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Sp.t1),
              onPressed: () => setState(() => _selectedAlbum = null),
            ),
          ),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Sp.bg2,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Sp.bd),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Sp.t1, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Rechercher un album, artiste...',
                hintStyle: const TextStyle(color: Sp.t3),
                prefixIcon: const Icon(Icons.search_rounded, color: Sp.t3, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Sp.t3, size: 20),
                      onPressed: () { _controller.clear(); _onSearchChanged(''); },
                    )
                  : null,
              ),
            ),
          ),
        ),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: Sp.ac)))
        else if (_query.isEmpty)
          const Expanded(child: _EmptySearchState())
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Albums
                  if (_albums.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 13),
                      child: Text('Albums', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
                    ),
                    Wrap(
                      spacing: 13, runSpacing: 13,
                      children: _albums.take(8).map((album) {
                        return WebCard(
                          title: album.title,
                          subtitle: album.artist,
                          imageUrl: _api.getArtworkUrl(album.image.isNotEmpty ? album.image : album.hash),
                          onTap: () => setState(() => _selectedAlbum = album),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Chansons
                  if (_songs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: Text('Chansons (${_songs.length})', style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
                    ),
                    ...List.generate(
                      _songs.length > 50 ? 50 : _songs.length,
                      (i) {
                        final song = _songs[i];
                        final player = context.read<PlayerProvider>();
                        final isPlaying = context.watch<PlayerProvider>().currentSong?.hash == song.hash;

                        return _SongRow(
                          song: song,
                          isPlaying: isPlaying,
                          api: _api,
                          onTap: () => player.playSong(song, queue: _songs),
                          isFavourite: player.isFavourite(song.hash),
                          onFavTap: () => player.toggleFavourite(song.hash),
                        );
                      },
                    ),
                  ],

                  if (_songs.isEmpty && _albums.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 64),
                      child: Center(
                        child: Text('Aucun résultat trouvé', style: TextStyle(color: Sp.t3, fontSize: 15)),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SongRow extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final SwingApiService api;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback onFavTap;

  const _SongRow({
    required this.song, required this.isPlaying, required this.api, required this.onTap, required this.isFavourite, required this.onFavTap,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: widget.isPlaying ? Sp.ac4 : (_hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: widget.api.getArtworkUrl(widget.song.image ?? widget.song.hash),
                  httpHeaders: widget.api.authHeaders,
                  width: 38, height: 38,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 38, height: 38,
                    color: Sp.bg4,
                    child: const Icon(Icons.music_note_rounded, color: Sp.t3, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isPlaying ? Sp.ac : Sp.t1,
                        fontWeight: FontWeight.w400,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      widget.song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Sp.t2, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (_hover) const Icon(Icons.play_arrow_rounded, color: Sp.t1, size: 20),
              
              const SizedBox(width: 12),
              IconButton(
                splashRadius: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                icon: Icon(widget.isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                color: widget.isFavourite ? Sp.ac : Sp.t4,
                iconSize: 16,
                onPressed: widget.onFavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, color: Sp.bg4, size: 80),
          SizedBox(height: 16),
          Text('Explorez la galaxie musicale', style: TextStyle(color: Sp.t3, fontSize: 15)),
        ],
      ),
    );
  }
}
