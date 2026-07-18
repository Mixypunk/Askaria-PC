import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../../core/providers/player_provider.dart';
import '../../main.dart';
import 'components/sidebar.dart';
import 'components/player_bar.dart';
import 'components/lyrics_overlay.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/songs_page.dart';
import 'pages/library_page.dart';
import 'pages/artists_page.dart';
import 'pages/genres_page.dart';
import 'pages/decades_page.dart';
import 'pages/favourites_page.dart';
import 'pages/playlists_page.dart';
import 'pages/recently_played_page.dart';
import 'pages/profile_page.dart';
import 'pages/admin_page.dart';
import 'pages/settings_page.dart';
import '../core/services/updater_service.dart';
import 'components/updater_dialog.dart';

class AppDesktop extends StatefulWidget {
  const AppDesktop({super.key});

  @override
  State<AppDesktop> createState() => _AppDesktopState();
}

class _AppDesktopState extends State<AppDesktop> {
  NavDest _currentDest = NavDest.home;
  bool _showLyrics = false;

  /// Pages pré-construites une seule fois dans initState.
  /// IndexedStack les garde en vie, mais _buildPage() était appelé à chaque
  /// rebuild de AppDesktop (chaque changement de nav), ce qui recrée
  /// inutilement les widgets constants. En les mémorisant ici, le build()
  /// devient O(1) pour la liste des pages.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Ordre identique à NavDest.values — NE PAS changer sans mettre à jour NavDest
    const pages = [
      HomePage(),
      SearchPage(),
      SongsPage(),
      LibraryPage(),
      ArtistsPage(),
      GenresPage(),
      DecadesPage(),
      FavouritesPage(),
      PlaylistsPage(),
      PlaylistsPage(), // discovery → même page
      RecentlyPlayedPage(),
      ProfilePage(),
      AdminPage(),
      SettingsPage(),
    ];

    _pages = pages.map((page) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => page),
    )).toList();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    await Future.delayed(const Duration(seconds: 3));
    final updateUrl = await UpdaterService.checkForUpdate();
    if (updateUrl != null && mounted) {
      UpdaterDialog.showIfUpdateAvailable(context, updateUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          player.playPause();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Sp.bg0,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kWindowCaptionHeight),
        child: SizedBox(
          height: kWindowCaptionHeight,
          child: WindowCaption(
            brightness: Brightness.dark,
            backgroundColor: Sp.bg0,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sidebar
                    Sidebar(
                      selectedDest: _currentDest,
                      onDestSelected: (dest) =>
                          setState(() => _currentDest = dest),
                    ),
                    // Contenu principal — IndexedStack préserve l'état de toutes les pages
                    Expanded(
                      child: RepaintBoundary(
                        child: Container(
                          color: Sp.bg0,
                          // _pages est pré-construit dans initState : pas de recréation
                          child: IndexedStack(
                            index: NavDest.values.indexOf(_currentDest),
                            children: _pages,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Barre de lecture
              PlayerBar(
                onLyricsPressed: () =>
                    setState(() => _showLyrics = !_showLyrics),
              ),
            ],
          ),

          // Overlay Paroles
          if (_showLyrics)
            Positioned.fill(
              child: LyricsOverlay(
                onClose: () => setState(() => _showLyrics = false),
              ),
            ),
        ],
      ),
    ));
  }
}