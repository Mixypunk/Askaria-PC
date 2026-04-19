import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/models/album.dart';
import '../../core/services/api_service.dart';

enum NavDest {
  home, search, songs, albums, artists, genres, decades,
  favourites, playlists, discovery,
  recentlyPlayed, profile, admin, settings,
}

typedef NavCallback = void Function(NavDest);

class Sidebar extends StatefulWidget {
  final NavDest selectedDest;
  final NavCallback onDestSelected;

  const Sidebar({
    super.key,
    required this.selectedDest,
    required this.onDestSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final _api = SwingApiService();
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final pls = await _api.getPlaylists();
      if (mounted) setState(() => _playlists = pls);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: Sp.bg1,
        border: Border(right: BorderSide(color: Sp.bd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35), // Zone draggable

          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Sp.ac, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 9),
                RichText(
                  text: const TextSpan(
                    text: 'Askaria',
                    style: TextStyle(fontFamily: 'Segoe UI', fontSize: 17, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3),
                    children: [TextSpan(text: '.', style: TextStyle(color: Sp.ac))],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nav principale
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Item(icon: Icons.home_rounded, label: 'Accueil', dest: NavDest.home, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.search_rounded, label: 'Rechercher', dest: NavDest.search, selected: widget.selectedDest, onTap: widget.onDestSelected),
                      ],
                    ),
                  ),

                  _Divider(),
                  _Label('Bibliothèque'),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Item(icon: Icons.library_music_rounded, label: 'Titres', dest: NavDest.songs, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.album_rounded, label: 'Albums', dest: NavDest.albums, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.person_rounded, label: 'Artistes', dest: NavDest.artists, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.music_note_rounded, label: 'Genres', dest: NavDest.genres, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.access_time_rounded, label: 'Décennies', dest: NavDest.decades, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.favorite_rounded, label: 'Favoris', dest: NavDest.favourites, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.public_rounded, label: 'Découverte', dest: NavDest.discovery, selected: widget.selectedDest, onTap: widget.onDestSelected),
                      ],
                    ),
                  ),

                  _Divider(),

                  // Playlists header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 8, 3),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('PLAYLISTS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Sp.t4, letterSpacing: 0.1)),
                        ),
                        GestureDetector(
                          onTap: () => widget.onDestSelected(NavDest.playlists),
                          child: Container(
                            width: 19, height: 19,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: Sp.t3, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Liste des playlists
                  if (_playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 6, 8, 6),
                      child: Text('Aucune playlist', style: TextStyle(color: Sp.t3, fontSize: 11.5)),
                    )
                  else
                    ...(_playlists.take(20).map((pl) => _PlaylistItem(
                      playlist: pl,
                      onTap: () => widget.onDestSelected(NavDest.playlists),
                    ))),

                  _Divider(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Item(icon: Icons.history_rounded, label: 'Récents', dest: NavDest.recentlyPlayed, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.person_outline_rounded, label: 'Mon profil', dest: NavDest.profile, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.admin_panel_settings_rounded, label: 'Administration', dest: NavDest.admin, selected: widget.selectedDest, onTap: widget.onDestSelected),
                        _Item(icon: Icons.settings_rounded, label: 'Paramètres', dest: NavDest.settings, selected: widget.selectedDest, onTap: widget.onDestSelected),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: Divider(color: Sp.bd, height: 1),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 8, 5),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Sp.t4, letterSpacing: 0.1)),
    );
  }
}

class _Item extends StatefulWidget {
  final IconData icon;
  final String label;
  final NavDest dest;
  final NavDest selected;
  final NavCallback onTap;
  const _Item({required this.icon, required this.label, required this.dest, required this.selected, required this.onTap});
  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.dest == widget.selected;
    final color = isSelected ? Sp.t1 : (_hover ? Sp.t1 : Sp.t3);
    final bgColor = isSelected
        ? Colors.white.withValues(alpha: 0.08)
        : (_hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.dest),
        child: Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7)),
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              if (isSelected)
                Positioned(
                  left: -10,
                  child: Container(
                    width: 2.5, height: 15,
                    decoration: const BoxDecoration(
                      color: Sp.ac,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(widget.icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.label,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          fontSize: 12.5,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistItem extends StatefulWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  const _PlaylistItem({required this.playlist, required this.onTap});
  @override
  State<_PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<_PlaylistItem> {
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hover ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Sp.bg4, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.queue_music_rounded, color: Sp.t3, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.playlist.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _hover ? Sp.t1 : Sp.t3, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
