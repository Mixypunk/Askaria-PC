import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/player_provider.dart';
import '../components/toast_service.dart';

class GenresPage extends StatefulWidget {
  const GenresPage({super.key});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  final _api = SwingApiService();
  List<Map<String, dynamic>> _genres = [];
  bool _loading = true;

  // Palette de couleurs pour les genres
  static const List<Color> _palette = [
    Color(0xFFE8375A), Color(0xFF3B82F6), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFF06B6D4), Color(0xFFEF4444), Color(0xFF84CC16),
    Color(0xFFF97316),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _api.getGenres();
      if (mounted) setState(() { _genres = data; _loading = false; });
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Genres', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
              Text('${_genres.length} genres', style: const TextStyle(color: Sp.t2, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: _genres.isEmpty
              ? const Center(child: Text('Aucun genre disponible', style: TextStyle(color: Sp.t3)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: Wrap(
                    spacing: 13, runSpacing: 13,
                    children: _genres.asMap().entries.map((e) {
                      final g = e.value;
                      final color = _palette[e.key % _palette.length];
                      return _GenreCard(
                        name: g['name'] as String? ?? '',
                        count: g['count'] as int? ?? 0,
                        color: color,
                        onTap: () => _playGenre(context, g['name'] as String? ?? ''),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _playGenre(BuildContext context, String name) async {
    ToastService.show(context, 'Chargement du genre...');
    final tracks = await _api.getGenreTracks(name);
    if (tracks.isNotEmpty && context.mounted) {
      context.read<PlayerProvider>().playSong(tracks.first, queue: tracks);
      ToastService.show(context, 'Genre : $name');
    }
  }
}

class _GenreCard extends StatefulWidget {
  final String name;
  final int count;
  final Color color;
  final VoidCallback onTap;
  const _GenreCard({required this.name, required this.count, required this.color, required this.onTap});
  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> {
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
          width: 155, padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg3 : Sp.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? Sp.bd : Colors.transparent),
            boxShadow: _hover
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Container(
                width: 129, height: 129,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.7),
                      widget.color.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        widget.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.15),
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text('${widget.count} titres', textAlign: TextAlign.center,
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}
