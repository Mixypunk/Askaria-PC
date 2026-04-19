import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart'; // Palette Sp
import '../../core/services/api_service.dart';
import '../../core/models/album.dart';
import '../../core/providers/player_provider.dart';
import 'album_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = SwingApiService();
  List<Playlist> _playlists = [];
  List<Album> _recentAlbums = [];
  bool _loading = true;
  Album? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getPlaylists(),
        _api.getAlbums(limit: 12),
      ]);
      if (mounted) {
        setState(() {
          _playlists = (results[0] as List).cast<Playlist>();
          _recentAlbums = (results[1] as List).cast<Album>();
          _loading = false;
        });
      }
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Sp.ac));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          const Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: Text(
              'Bonne journée',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3),
            ),
          ),

          if (_playlists.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 13),
              child: Text('Vos Playlists', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
            ),
            Wrap(
              spacing: 13, runSpacing: 13,
              children: _playlists.map((pl) {
                final artUrl = pl.imageHash != null ? '${_api.baseUrl}/img/playlist/${pl.imageHash}.webp' : null;
                return WebCard(
                  title: pl.name,
                  subtitle: '${pl.trackCount} titre${pl.trackCount > 1 ? 's' : ''}',
                  imageUrl: artUrl,
                  onTap: () async {
                    final tracks = await _api.getPlaylistTracks(pl.id);
                    if (tracks.isNotEmpty && context.mounted) {
                      context.read<PlayerProvider>().playSong(tracks.first, queue: tracks);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          if (_recentAlbums.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 13),
              child: Text('Albums Récents', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1)),
            ),
            Wrap(
              spacing: 13, runSpacing: 13,
              children: _recentAlbums.map((album) {
                return WebCard(
                  title: album.title,
                  subtitle: album.artist,
                  imageUrl: _api.getArtworkUrl(album.image.isNotEmpty ? album.image : album.hash),
                  onTap: () => setState(() => _selectedAlbum = album),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class WebCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isCircular;

  const WebCard({
    super.key, required this.title, required this.subtitle, this.imageUrl, required this.onTap, this.isCircular = false,
  });

  @override
  State<WebCard> createState() => _WebCardState();
}

class _WebCardState extends State<WebCard> {
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
          width: 155,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg3 : Sp.bg2,
            borderRadius: BorderRadius.circular(10), // --r: 10px
            border: Border.all(color: _hover ? Sp.bd : Colors.transparent, width: 1),
            boxShadow: _hover ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))] : [],
          ),
          child: Column(
            crossAxisAlignment: widget.isCircular ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // Image Container
              Container(
                width: 129, height: 129, // 155 - 2*13 padding
                margin: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  color: Sp.bg4,
                  shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.isCircular ? null : BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Image with scale animation
                    AnimatedScale(
                      scale: _hover ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: widget.imageUrl != null 
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            width: 129, height: 129,
                            fit: BoxFit.cover,
                            httpHeaders: SwingApiService().authHeaders,
                            errorWidget: (_, __, ___) => const Center(child: Icon(Icons.music_note, color: Sp.t3, size: 40)),
                          )
                        : const Center(child: Icon(Icons.queue_music, color: Sp.t3, size: 40)),
                    ),
                    // Hover Play Button Overlay
                    Positioned(
                      bottom: 7, right: 7,
                      child: AnimatedOpacity(
                        opacity: _hover ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedSlide(
                          offset: _hover ? Offset.zero : const Offset(0, 0.2),
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Sp.ac,
                              shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
                              borderRadius: widget.isCircular ? null : BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text Content
              Text(
                widget.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: widget.isCircular ? TextAlign.center : TextAlign.left,
                style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: widget.isCircular ? TextAlign.center : TextAlign.left,
                style: const TextStyle(color: Sp.t2, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
