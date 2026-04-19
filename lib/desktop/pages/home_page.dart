import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
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
  List<Artist> _artists = [];
  Map<String, dynamic> _stats = {};
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
        _api.getArtists(limit: 12),
        _api.getStatsOverview(),
      ]);
      if (mounted) {
        setState(() {
          _playlists    = (results[0] as List).cast<Playlist>();
          _recentAlbums = (results[1] as List).cast<Album>();
          _artists      = (results[2] as List).cast<Artist>();
          _stats        = results[3] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour 👋';
    if (h < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
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

    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(_greeting(),
                style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
          ),

          // Stats
          if (_stats.isNotEmpty) ...[
            _StatsRow(stats: _stats),
            const SizedBox(height: 26),
          ],

          // Albums récents
          if (_recentAlbums.isNotEmpty) ...[
            const _SectionHeader(title: 'Albums récents'),
            const SizedBox(height: 13),
            Wrap(
              spacing: 13, runSpacing: 13,
              children: _recentAlbums.map((album) => WebCard(
                title: album.title,
                subtitle: album.artist,
                imageUrl: _api.getArtworkUrl(album.image.isNotEmpty ? album.image : album.hash),
                onTap: () => setState(() => _selectedAlbum = album),
              )).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Artistes
          if (_artists.isNotEmpty) ...[
            const _SectionHeader(title: 'Artistes'),
            const SizedBox(height: 13),
            Wrap(
              spacing: 13, runSpacing: 13,
              children: _artists.map((a) => WebCard(
                title: a.name,
                subtitle: '${a.albumCount} album${a.albumCount != 1 ? 's' : ''}',
                imageUrl: '${_api.baseUrl}/img/artist/small/${a.image}',
                isCircular: true,
                onTap: () {},
              )).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Playlists
          if (_playlists.isNotEmpty) ...[
            const _SectionHeader(title: 'Vos Playlists'),
            const SizedBox(height: 13),
            Wrap(
              spacing: 13, runSpacing: 13,
              children: _playlists.take(6).map((pl) {
                return WebCard(
                  title: pl.name,
                  subtitle: '${pl.trackCount} titre${pl.trackCount > 1 ? 's' : ''}',
                  imageUrl: null,
                  onTap: () async {
                    final tracks = await _api.getPlaylistTracks(pl.id);
                    if (tracks.isNotEmpty && context.mounted) {
                      context.read<PlayerProvider>().playSong(tracks.first, queue: tracks);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Titres', value: '${stats['total_songs'] ?? stats['songs'] ?? '—'}'),
      _StatItem(label: 'Albums', value: '${stats['total_albums'] ?? stats['albums'] ?? '—'}'),
      _StatItem(label: 'Artistes', value: '${stats['total_artists'] ?? stats['artists'] ?? '—'}'),
      _StatItem(label: 'Heures', value: '${stats['total_hours'] ?? stats['hours'] ?? '—'}'),
    ];
    return Row(
      children: items.map((item) => Expanded(
        child: _StatCard(item: item),
      )).toList().expand((e) => [e, const SizedBox(width: 11)]).toList()..removeLast(),
    );
  }
}

class _StatItem {
  final String label, value;
  const _StatItem({required this.label, required this.value});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Sp.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Sp.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.value, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 26, fontWeight: FontWeight.w800, color: Sp.ac)),
          const SizedBox(height: 2),
          Text(item.label, style: const TextStyle(color: Sp.t2, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w700, color: Sp.t1));
  }
}

// WebCard — identique à avant mais amélioré
class WebCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isCircular;

  const WebCard({
    super.key, required this.title, required this.subtitle, this.imageUrl,
    required this.onTap, this.isCircular = false,
  });

  @override
  State<WebCard> createState() => _WebCardState();
}

class _WebCardState extends State<WebCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final api = SwingApiService();
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? Sp.bd : Colors.transparent),
            boxShadow: _hover
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: widget.isCircular ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Container(
                width: 129, height: 129,
                margin: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  color: Sp.bg4,
                  shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.isCircular ? null : BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    AnimatedScale(
                      scale: _hover ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: widget.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              width: 129, height: 129,
                              fit: BoxFit.cover,
                              httpHeaders: api.authHeaders,
                              errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.music_note_rounded, color: Sp.t3, size: 40)),
                            )
                          : const Center(child: Icon(Icons.queue_music_rounded, color: Sp.t3, size: 40)),
                    ),
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
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: widget.isCircular ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: widget.isCircular ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}
