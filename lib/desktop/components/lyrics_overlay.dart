import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/providers/player_provider.dart';
import '../../core/services/api_service.dart';

/// Overlay plein écran avec les paroles de la chanson en cours.
/// Synchronisées (LRC) ou texte brut. S'ouvre depuis la PlayerBar.
class LyricsOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const LyricsOverlay({super.key, required this.onClose});

  @override
  State<LyricsOverlay> createState() => _LyricsOverlayState();
}

class _LyricsOverlayState extends State<LyricsOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  final ScrollController _scrollCtrl = ScrollController();
  final _api = SwingApiService();
  int _activeLine = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  int _findActiveLine(List<Map<String, dynamic>> lines, Duration position) {
    final ms = position.inMilliseconds;
    int active = -1;
    for (int i = 0; i < lines.length; i++) {
      final t = (lines[i]['time'] as int);
      if (t <= ms) active = i;
    }
    return active;
  }

  void _scrollToActive(int idx, int total) {
    if (!_scrollCtrl.hasClients) return;
    final itemH = 60.0;
    final targetOffset = (idx * itemH) - (MediaQuery.of(context).size.height / 2);
    _scrollCtrl.animateTo(
      targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    // Update active line for synced lyrics
    if (player.lyricsSynced && player.syncedLines != null) {
      final newActive = _findActiveLine(player.syncedLines!, player.position);
      if (newActive != _activeLine) {
        _activeLine = newActive;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_activeLine >= 0) _scrollToActive(_activeLine, player.syncedLines!.length);
        });
      }
    }

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        color: const Color(0xFF080808).withValues(alpha: 0.97),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Sp.bd)),
              ),
              child: Row(
                children: [
                  // Artwork
                  if (song != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: _api.getArtworkUrl(song.image ?? song.hash),
                        httpHeaders: _api.authHeaders,
                        width: 46, height: 46,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 46, height: 46, color: Sp.bg4,
                          child: const Icon(Icons.music_note_rounded, color: Sp.t3),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song?.title ?? '—',
                            style: const TextStyle(color: Sp.t1, fontSize: 14.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(song?.artist ?? '—',
                            style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  // Fermer
                  Container(
                    width: 33, height: 33,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: Sp.t1, size: 16),
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
            ),
            // Corps paroles
            Expanded(
              child: _buildLyricsBody(player),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsBody(PlayerProvider player) {
    if (player.lyricsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Sp.ac),
      );
    }

    if (player.syncedLines != null && player.syncedLines!.isNotEmpty) {
      return _buildSyncedLyrics(player.syncedLines!, player.position);
    }

    if (player.unsyncedLines != null && player.unsyncedLines!.isNotEmpty) {
      return _buildUnsyncedLyrics(player.unsyncedLines!);
    }

    if (player.lyrics != null && player.lyrics!.isNotEmpty && player.lyrics != 'synced') {
      return _buildPlainLyrics(player.lyrics!);
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, color: Sp.bg4, size: 48),
          SizedBox(height: 12),
          Text('Aucune parole disponible', style: TextStyle(color: Sp.t3, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildSyncedLyrics(List<Map<String, dynamic>> lines, Duration position) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      itemCount: lines.length,
      itemBuilder: (_, i) {
        final isActive = i == _activeLine;
        final isPast = i < _activeLine;
        final text = lines[i]['text'] as String? ?? '';
        if (text.isEmpty) return const SizedBox(height: 20);
        return GestureDetector(
          onTap: () {
            final ms = lines[i]['time'] as int;
            context.read<PlayerProvider>().seek(Duration(milliseconds: ms));
          },
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: isActive ? 25 : 20,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Sp.t1
                    : isPast
                        ? Colors.white.withValues(alpha: 0.13)
                        : Colors.white.withValues(alpha: 0.20),
                height: 1.6,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(text, textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnsyncedLyrics(List<String> lines) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            lines.join('\n'),
            style: const TextStyle(
              color: Sp.t2, fontSize: 15, height: 1.9,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ),
    );
  }

  Widget _buildPlainLyrics(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            text,
            style: const TextStyle(color: Sp.t2, fontSize: 15, height: 1.9),
          ),
        ),
      ),
    );
  }
}
