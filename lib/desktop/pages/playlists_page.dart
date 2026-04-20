import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/song.dart';
import '../../core/models/album.dart';
import '../../core/providers/player_provider.dart';
import '../components/song_table.dart';
import '../components/toast_service.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final _api = SwingApiService();
  List<Playlist> _playlists = [];
  bool _loading = true;
  Playlist? _selected;
  bool _showPublic = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pls = await _api.getPlaylists();
      if (mounted) setState(() { _playlists = pls; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    if (_selected != null) {
      return _PlaylistDetailView(
        playlist: _selected!,
        api: _api,
        onBack: () => setState(() => _selected = null),
        onUpdated: _load,
      );
    }

    if (_showPublic) {
      return _PublicPlaylistsView(
        api: _api,
        onBack: () => setState(() => _showPublic = false),
        onSelectPlaylist: (pl) => setState(() { _selected = pl; _showPublic = false; }),
      );
    }

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
                    const Text('Playlists',
                        style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
                    Text('${_playlists.length} playlist${_playlists.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: Sp.t2, fontSize: 12)),
                  ],
                ),
              ),
              _OutlineBtn(icon: Icons.public_rounded, label: 'Découverte',
                  onTap: () => setState(() => _showPublic = true)),
              const SizedBox(width: 10),
              _FillBtn(icon: Icons.add_rounded, label: 'Nouvelle playlist', onTap: () => _createPlaylist(context)),
            ],
          ),
        ),
        Expanded(
          child: _playlists.isEmpty
              ? const _EmptyCenter(icon: Icons.queue_music_rounded, message: 'Aucune playlist',
                  subtitle: 'Créez votre première playlist')
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: Wrap(
                    spacing: 13, runSpacing: 13,
                    children: _playlists.map((pl) => _PlaylistCard(
                      playlist: pl,
                      api: _api,
                      onTap: () => setState(() => _selected = pl),
                    )).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isPublic = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: Sp.bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Nouvelle playlist', style: TextStyle(color: Sp.t1, fontWeight: FontWeight.w700, fontFamily: 'Segoe UI')),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, hint: 'Nom de la playlist'),
                const SizedBox(height: 10),
                _Field(ctrl: descCtrl, hint: 'Description (optionnel)', maxLines: 3),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isPublic,
                      onChanged: (v) => setSt(() => isPublic = v ?? false),
                      activeColor: Sp.ac,
                    ),
                    const Text('Rendre publique', style: TextStyle(color: Sp.t2, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler', style: TextStyle(color: Sp.t2))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Sp.ac),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    if (result == true) {
      await _api.createPlaylist(nameCtrl.text.trim(),
          description: descCtrl.text.trim(), isPublic: isPublic);
      await _load();
      if (context.mounted) ToastService.show(context, 'Playlist créée !');
    }
  }
}

class _PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final SwingApiService api;
  final VoidCallback onTap;
  const _PlaylistCard({required this.playlist, required this.api, required this.onTap});
  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 129, height: 129,
                    decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.queue_music_rounded, color: Sp.t3, size: 48),
                  ),
                  Positioned(
                    bottom: 7, right: 7,
                    child: AnimatedOpacity(
                      opacity: _hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 34, height: 34,
                        decoration: const BoxDecoration(color: Sp.ac, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(widget.playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Sp.t1, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text('${widget.playlist.trackCount} titre${widget.playlist.trackCount != 1 ? 's' : ''}',
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistDetailView extends StatefulWidget {
  final Playlist playlist;
  final SwingApiService api;
  final VoidCallback onBack;
  final VoidCallback onUpdated;
  const _PlaylistDetailView({required this.playlist, required this.api, required this.onBack, required this.onUpdated});
  @override
  State<_PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends State<_PlaylistDetailView> {
  List<Song> _tracks = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final tracks = await widget.api.getPlaylistTracks(widget.playlist.id);
      if (mounted) setState(() { _tracks = tracks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackBtn(onTap: widget.onBack),
          const SizedBox(height: 6),
          // Header playlist
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 180, height: 180,
                decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.queue_music_rounded, color: Sp.t3, size: 64),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Playlist', style: TextStyle(color: Sp.t2, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.1)),
                    const SizedBox(height: 5),
                    Text(widget.playlist.name,
                        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 34, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.7)),
                    const SizedBox(height: 7),
                    Text('${_tracks.length} titre${_tracks.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: Sp.t2, fontSize: 12.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_tracks.isNotEmpty) ...[
                          _FillBtn(
                            icon: Icons.play_arrow_rounded, label: 'Lecture',
                            onTap: () => player.playSong(_tracks.first, queue: _tracks),
                          ),
                          const SizedBox(width: 10),
                        ],
                        _OutlineBtn(icon: Icons.edit_rounded, label: 'Modifier',
                            onTap: () => _editPlaylist(context)),
                        const SizedBox(width: 10),
                        _OutlineBtn(icon: Icons.delete_rounded, label: 'Supprimer',
                            danger: true,
                            onTap: () => _deletePlaylist(context)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Sp.ac))
          else if (_tracks.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: Text('Playlist vide', style: TextStyle(color: Sp.t3, fontSize: 13.5)),
            ))
          else
            SongTable(songs: _tracks),
        ],
      ),
    );
  }

  Future<void> _editPlaylist(BuildContext context) async {
    final nameCtrl = TextEditingController(text: widget.playlist.name);
    final descCtrl = TextEditingController(text: widget.playlist.description ?? '');
    bool isPublic = widget.playlist.isPublic;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: Sp.bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Modifier la playlist', style: TextStyle(color: Sp.t1, fontWeight: FontWeight.w700, fontFamily: 'Segoe UI')),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, hint: 'Nom de la playlist'),
                const SizedBox(height: 10),
                _Field(ctrl: descCtrl, hint: 'Description', maxLines: 3),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isPublic,
                      onChanged: (v) => setSt(() => isPublic = v ?? false),
                      activeColor: Sp.ac,
                    ),
                    const Text('Playlist publique', style: TextStyle(color: Sp.t2, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler', style: TextStyle(color: Sp.t2))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Sp.ac),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await widget.api.updatePlaylist(widget.playlist.id,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          isPublic: isPublic);
      widget.onUpdated();
      if (context.mounted) ToastService.show(context, 'Playlist mise à jour');
      widget.onBack();
    }
    nameCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _deletePlaylist(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Sp.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Supprimer la playlist ?', style: TextStyle(color: Sp.t1)),
        content: Text('Cette action est irréversible.', style: TextStyle(color: Sp.t2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler', style: TextStyle(color: Sp.t2))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.api.deletePlaylist(widget.playlist.id);
      widget.onUpdated();
      if (context.mounted) ToastService.show(context, 'Playlist supprimée');
      widget.onBack();
    }
  }
}

class _PublicPlaylistsView extends StatefulWidget {
  final SwingApiService api;
  final VoidCallback onBack;
  final void Function(Playlist) onSelectPlaylist;
  const _PublicPlaylistsView({required this.api, required this.onBack, required this.onSelectPlaylist});
  @override
  State<_PublicPlaylistsView> createState() => _PublicPlaylistsViewState();
}

class _PublicPlaylistsViewState extends State<_PublicPlaylistsView> {
  List<Playlist> _pls = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pls = await widget.api.getPublicPlaylists();
      if (mounted) setState(() { _pls = pls; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Row(
            children: [
              _BackBtn(onTap: widget.onBack),
              const SizedBox(width: 12),
              const Text('Playlists de la communauté',
                  style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
            ],
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator(color: Sp.ac))
        else if (_pls.isEmpty)
          const _EmptyCenter(icon: Icons.public_off_rounded, message: 'Aucune playlist publique', subtitle: '')
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
              child: Wrap(
                spacing: 13, runSpacing: 13,
                children: _pls.map((pl) => _PlaylistCard(
                  playlist: pl, api: widget.api,
                  onTap: () => widget.onSelectPlaylist(pl),
                )).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Helpers widgets ────────────────────────────────────────────────────
class _EmptyCenter extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyCenter({required this.icon, required this.message, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Sp.bg4, size: 72),
        const SizedBox(height: 14),
        Text(message, style: const TextStyle(color: Sp.t2, fontSize: 16, fontWeight: FontWeight.w500)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Sp.t3, fontSize: 12.5)),
        ],
      ],
    ),
  );
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
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
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: Sp.t2, size: 14),
              SizedBox(width: 6),
              Text('Retour', style: TextStyle(color: Sp.t2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FillBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FillBtn({required this.icon, required this.label, required this.onTap});
  @override
  State<_FillBtn> createState() => _FillBtnState();
}

class _FillBtnState extends State<_FillBtn> {
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? Sp.ac2 : Sp.ac,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 14),
              const SizedBox(width: 7),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap, this.danger = false});
  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.danger ? const Color(0xFFF87171) : Sp.t1;
    final borderColor = widget.danger ? const Color(0xFFE8375A).withValues(alpha: 0.35) : Sp.bd2;
    final hoverBg = widget.danger ? const Color(0xFFE8375A).withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.04);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: color, size: 13),
              const SizedBox(width: 7),
              Text(widget.label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _Field({required this.ctrl, required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Sp.t1, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Sp.t3),
        filled: true,
        fillColor: Sp.bg3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Sp.ac)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }
}
