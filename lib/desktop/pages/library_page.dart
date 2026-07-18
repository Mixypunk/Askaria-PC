import 'package:flutter/material.dart';
import '../../main.dart'; // Palette Sp
import '../../core/services/api_service.dart';
import '../../core/models/album.dart';
import 'album_detail_page.dart';
import 'home_page.dart'; // Pour WebCard

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _api = SwingApiService();
  List<Album> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final data = await _api.getAlbums(limit: 200);
      if (mounted) setState(() { _albums = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Sp.ac));
    }

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(28, 26, 28, 22),
          sliver: SliverToBoxAdapter(
            child: Text('Albums', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
          ),
        ),
        SliverPadding(
          padding: Sp.pagePaddingNoTop,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childAspectRatio: 0.75, // Ajusté pour le format de WebCard
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final album = _albums[index];
                return WebCard(
                  title: album.title,
                  subtitle: album.artist,
                  imageUrl: _api.getArtworkUrl(album.image.isNotEmpty ? album.image : album.hash),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AlbumDetailPage(album: album)),
                    );
                  },
                );
              },
              childCount: _albums.length,
            ),
          ),
        ),
      ],
    );
  }
}
