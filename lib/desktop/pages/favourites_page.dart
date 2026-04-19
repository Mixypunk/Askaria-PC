import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/song.dart';
import '../../core/providers/player_provider.dart';
import '../components/song_table.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final _api = SwingApiService();
  List<Song> _favs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final songs = await _api.getFavourites();
      if (mounted) setState(() { _favs = songs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Favoris',
                        style: TextStyle(
                            fontFamily: 'Segoe UI', fontSize: 24,
                            fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
                    Text('${_favs.length} titre${_favs.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: Sp.t2, fontSize: 12)),
                  ],
                ),
              ),
              if (_favs.isNotEmpty)
                _PlayBtn(
                  onTap: () => context.read<PlayerProvider>().playSong(_favs.first, queue: _favs),
                ),
            ],
          ),
        ),
        Expanded(
          child: _favs.isEmpty
              ? const _EmptyState(
                  icon: Icons.favorite_border_rounded,
                  message: 'Aucun favori',
                  subtitle: 'Ajoutez des titres à vos favoris en cliquant sur ♥',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: SongTable(songs: _favs),
                ),
        ),
      ],
    );
  }
}

class _PlayBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayBtn({required this.onTap});
  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? Sp.ac2 : Sp.ac,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Row(
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState({required this.icon, required this.message, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Sp.bg4, size: 72),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Sp.t2, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Sp.t3, fontSize: 12.5)),
        ],
      ),
    );
  }
}
