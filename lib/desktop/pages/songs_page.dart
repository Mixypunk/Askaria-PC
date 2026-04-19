import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/song.dart';
import '../../core/providers/player_provider.dart';
import '../components/song_table.dart';
import '../components/toast_service.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final _api = SwingApiService();
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Charge jusqu'à 5000 titres comme la version web
      final songs = await _api.getSongs(limit: 5000);
      if (mounted) setState(() { _songs = songs; _loading = false; });
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tous les titres',
                        style: TextStyle(
                            fontFamily: 'Segoe UI', fontSize: 24,
                            fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
                    Text('${_songs.length} titres',
                        style: const TextStyle(color: Sp.t2, fontSize: 12)),
                  ],
                ),
              ),
              // Lecture aléatoire
              _ActionButton(
                icon: Icons.shuffle_rounded,
                label: 'Lecture aléatoire',
                onTap: () {
                  if (_songs.isEmpty) return;
                  final player = context.read<PlayerProvider>();
                  final shuffled = List<Song>.from(_songs)..shuffle();
                  player.playSong(shuffled.first, queue: shuffled);
                  ToastService.show(context, 'Lecture aléatoire lancée');
                },
              ),
            ],
          ),
        ),
        // Liste
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
            child: SongTable(songs: _songs),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
            boxShadow: _hover
                ? [BoxShadow(color: Sp.ac.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
