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
  Album? _selectedAlbum;

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
    if (_selectedAlbum != null) {
      return Stack(
        children: [
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
        ],
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Sp.ac));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 22),
            child: Text('Albums', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
          ),
          Wrap(
            spacing: 13, runSpacing: 13,
            children: _albums.map((album) {
              return WebCard(
                title: album.title,
                subtitle: album.artist,
                imageUrl: _api.getArtworkUrl(album.image.isNotEmpty ? album.image : album.hash),
                onTap: () => setState(() => _selectedAlbum = album),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
