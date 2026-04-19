import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/album.dart';
import '../../core/providers/player_provider.dart';
import 'toast_service.dart';

/// Dialog pour ajouter un ou plusieurs titres à une playlist.
/// Affiche la liste des playlists + option "Créer une nouvelle playlist".
Future<void> showAddToPlaylistDialog(
  BuildContext context, {
  required List<String> trackHashes,
}) async {
  final api = SwingApiService();
  final player = context.read<PlayerProvider>();
  List<Playlist> pls = [];
  try {
    pls = await (player.getCachedPlaylists() as Future).then((v) => v.cast<Playlist>());
  } catch (_) {
    try { pls = await api.getPlaylists(); } catch (_) {}
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _AddToPlaylistDialog(
      playlists: pls,
      trackHashes: trackHashes,
      api: api,
      player: player,
    ),
  );
}

class _AddToPlaylistDialog extends StatelessWidget {
  final List<Playlist> playlists;
  final List<String> trackHashes;
  final SwingApiService api;
  final PlayerProvider player;

  const _AddToPlaylistDialog({
    required this.playlists,
    required this.trackHashes,
    required this.api,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Sp.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 390,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajouter à une playlist',
                style: TextStyle(
                    color: Sp.t1, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Segoe UI')),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Aucune playlist', style: TextStyle(color: Sp.t3))),
              )
            else
              LimitedBox(
                maxHeight: 280,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (_, i) {
                    final pl = playlists[i];
                    return _PlaylistPickItem(
                      playlist: pl,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await api.addTracksToPlaylist(pl.id, trackHashes);
                        player.invalidatePlaylistsCache();
                        if (context.mounted) {
                          ToastService.show(context, 'Ajouté à "${pl.name}"');
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            // Créer nouvelle playlist
            _NewPlaylistButton(
              api: api,
              trackHashes: trackHashes,
              player: player,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Sp.t2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPickItem extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  const _PlaylistPickItem({required this.playlist, required this.onTap});
  @override
  State<_PlaylistPickItem> createState() => _PlaylistPickItemState();
}

class _PlaylistPickItemState extends State<_PlaylistPickItem> {
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
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.queue_music_rounded, color: Sp.t3, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('${widget.playlist.trackCount} titre${widget.playlist.trackCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Sp.t2, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPlaylistButton extends StatefulWidget {
  final SwingApiService api;
  final List<String> trackHashes;
  final PlayerProvider player;
  const _NewPlaylistButton({required this.api, required this.trackHashes, required this.player});
  @override
  State<_NewPlaylistButton> createState() => _NewPlaylistButtonState();
}

class _NewPlaylistButtonState extends State<_NewPlaylistButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _createNew(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg3 : Sp.bg3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Sp.bd),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: Sp.t2, size: 16),
              SizedBox(width: 8),
              Text('Créer une nouvelle playlist', style: TextStyle(color: Sp.t2, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNew(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Sp.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Nouvelle playlist', style: TextStyle(color: Sp.t1, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Sp.t1),
          decoration: InputDecoration(
            hintText: 'Nom de la playlist',
            hintStyle: const TextStyle(color: Sp.t3),
            filled: true,
            fillColor: Sp.bg3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onSubmitted: (v) => Navigator.of(dCtx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Annuler', style: TextStyle(color: Sp.t2))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Sp.ac),
            onPressed: () => Navigator.of(dCtx).pop(nameCtrl.text.trim()),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.isEmpty) return;
    final pl = await widget.api.createPlaylist(name);
    if (pl != null) {
      await widget.api.addTracksToPlaylist(pl.id, widget.trackHashes);
      widget.player.invalidatePlaylistsCache();
      if (ctx.mounted) ToastService.show(ctx, 'Ajouté à "$name"');
    }
  }
}
