import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/providers/player_provider.dart';
import '../../core/services/api_service.dart';

/// Overlay plein écran avec les paroles de la chanson en cours.
/// Synchronisées (LRC) ou texte brut. S'ouvre depuis la PlayerBar.
///
/// Architecture :
/// - addListener sur PlayerProvider → setState propre (pas de mutation dans build)
/// - Scroll vers la ligne active déclenché dans _onPlayerChanged, PAS dans build
/// - Séparation claire entre l'état de chargement et l'état de lecture
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

  // État paroles
  int _activeLine = -1;
  bool _userScrolling = false; // désactive l'auto-scroll si l'user scrolle manuellement

  // Référence au provider pour l'écoute directe
  PlayerProvider? _playerProvider;

  /// Hash de la chanson actuellement affichée — permet de détecter un changement
  String? _displayedSongHash;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On s'abonne UNE SEULE FOIS au provider — pas dans build()
    final newProvider = Provider.of<PlayerProvider>(context, listen: false);
    if (_playerProvider != newProvider) {
      _playerProvider?.removeListener(_onPlayerChanged);
      _playerProvider = newProvider;
      _playerProvider!.addListener(_onPlayerChanged);
      // Calcul initial de la ligne active
      _onPlayerChanged();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _playerProvider?.removeListener(_onPlayerChanged);
    super.dispose();
  }

  /// Appelé à chaque changement du PlayerProvider (position, song, lyrics…).
  /// C'est ici qu'on met à jour _activeLine et déclenchons le scroll,
  /// jamais dans build().
  void _onPlayerChanged() {
    if (!mounted) return;
    final player = _playerProvider;
    if (player == null) return;

    final currentHash = player.currentSong?.hash;
    final currentPos = player.position;

    // Si la chanson a changé, réinitialiser la ligne active et le scroll
    if (currentHash != _displayedSongHash) {
      _displayedSongHash = currentHash;
      _lastPosition = currentPos;
      setState(() {
        _activeLine = -1;
      });
      // Remonter en haut pour la nouvelle chanson
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(0);
        }
      });
    } else {
      // Si la chanson est la même, mais qu'on a reculé (seek ou boucle)
      if (currentPos < _lastPosition - const Duration(seconds: 1) || currentPos == Duration.zero) {
        if (currentPos.inMilliseconds < 1000) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollCtrl.hasClients) {
              _scrollCtrl.jumpTo(0);
            }
          });
        }
      }
      _lastPosition = currentPos;
    }

    if (!player.lyricsSynced || player.syncedLines == null) return;

    final newActive =
        _findActiveLine(player.syncedLines!, player.position);

    if (newActive != _activeLine) {
      setState(() {
        _activeLine = newActive;
      });
      // Scroll seulement si l'utilisateur ne scrolle pas manuellement
      if (!_userScrolling && newActive >= 0) {
        _scrollToActive(newActive);
      }
    }
  }

  int _findActiveLine(List<Map<String, dynamic>> lines, Duration position) {
    final ms = position.inMilliseconds;
    int active = -1;
    for (int i = 0; i < lines.length; i++) {
      final t = lines[i]['time'] as int;
      if (t <= ms) active = i;
    }
    return active;
  }

  void _scrollToActive(int idx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Double vérification après le frame (le widget peut avoir été détaché)
      if (!mounted || !_scrollCtrl.hasClients) return;
      const itemH = 60.0;
      final viewportH = _scrollCtrl.position.viewportDimension;
      final maxExtent = _scrollCtrl.position.maxScrollExtent;
      final targetOffset =
          (idx * itemH) - (viewportH / 2) + (itemH / 2);
      _scrollCtrl.animateTo(
        targetOffset.clamp(0.0, maxExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // On lit le provider SANS écoute ici — toutes les mises à jour passent
    // par _onPlayerChanged(). On n'utilise watch() que pour les données
    // qui ne changent pas à chaque tick (song, lyricsLoading, etc.)
    final player = context.select<PlayerProvider, _LyricsSnapshot>(
      (p) => _LyricsSnapshot(
        song: p.currentSong,
        loading: p.lyricsLoading,
        synced: p.lyricsSynced,
        syncedLines: p.syncedLines,
        unsyncedLines: p.unsyncedLines,
        lyrics: p.lyrics,
      ),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification && n.dragDetails != null) {
          _userScrolling = true;
        } else if (n is ScrollEndNotification) {
          // Reprendre l'auto-scroll 2s après que l'utilisateur s'arrête
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _userScrolling = false;
          });
        }
        return false;
      },
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          color: const Color(0xFF080808).withValues(alpha: 0.97),
          child: Column(
            children: [
              _buildHeader(player),
              Expanded(child: _buildBody(player)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_LyricsSnapshot player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Sp.bd)),
      ),
      child: Row(
        children: [
          if (player.song != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CachedNetworkImage(
                imageUrl:
                    _api.getArtworkUrl(player.song!.image ?? player.song!.hash),
                httpHeaders: _api.authHeaders,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  color: Sp.bg4,
                  child: const Icon(Icons.music_note_rounded, color: Sp.t3),
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.song?.title ?? '—',
                  style: const TextStyle(
                      color: Sp.t1,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  player.song?.artist ?? '—',
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon:
                  const Icon(Icons.close_rounded, color: Sp.t1, size: 16),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(_LyricsSnapshot player) {
    if (player.loading) {
      return const Center(child: CircularProgressIndicator(color: Sp.ac));
    }

    if (player.synced && player.syncedLines != null && player.syncedLines!.isNotEmpty) {
      return _buildSyncedLyrics(player.syncedLines!);
    }

    if (player.unsyncedLines != null && player.unsyncedLines!.isNotEmpty) {
      return _buildUnsyncedLyrics(player.unsyncedLines!);
    }

    if (player.lyrics != null &&
        player.lyrics!.isNotEmpty &&
        player.lyrics != 'synced') {
      return _buildPlainLyrics(player.lyrics!);
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, color: Sp.bg4, size: 48),
          SizedBox(height: 12),
          Text('Aucune parole disponible',
              style: TextStyle(color: Sp.t3, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildSyncedLyrics(List<Map<String, dynamic>> lines) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      itemCount: lines.length,
      itemExtent: 60.0, // hauteur fixe → scroll précis + perf accrue
      itemBuilder: (_, i) {
        final isActive = i == _activeLine;
        final isPast = i < _activeLine;
        final text = lines[i]['text'] as String? ?? '';

        if (text.trim().isEmpty) {
          return const SizedBox(height: 60);
        }

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
                fontSize: isActive ? 23 : 18,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Sp.t1
                    : isPast
                        ? Colors.white.withValues(alpha: 0.13)
                        : Colors.white.withValues(alpha: 0.25),
                height: 1.6,
              ),
              child: Text(text, textAlign: TextAlign.center),
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
            style: const TextStyle(color: Sp.t2, fontSize: 15, height: 1.9),
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

/// Snapshot immuable du PlayerProvider pour le context.select de LyricsOverlay.
/// N'inclut PAS la position — celle-ci est gérée via addListener pour éviter
/// des rebuilds à chaque tick.
class _LyricsSnapshot {
  final dynamic song;
  final bool loading;
  final bool synced;
  final List<Map<String, dynamic>>? syncedLines;
  final List<String>? unsyncedLines;
  final String? lyrics;

  const _LyricsSnapshot({
    required this.song,
    required this.loading,
    required this.synced,
    required this.syncedLines,
    required this.unsyncedLines,
    required this.lyrics,
  });

  @override
  bool operator ==(Object other) =>
      other is _LyricsSnapshot &&
      other.song?.hash == song?.hash &&
      other.loading == loading &&
      other.synced == synced &&
      other.syncedLines == syncedLines &&
      other.unsyncedLines == unsyncedLines &&
      other.lyrics == lyrics;

  @override
  int get hashCode => Object.hash(
      song?.hash, loading, synced, syncedLines, unsyncedLines, lyrics);
}
