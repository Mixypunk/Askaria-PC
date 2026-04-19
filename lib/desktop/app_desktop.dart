import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    await Future.delayed(const Duration(seconds: 3));
    final updateUrl = await UpdaterService.checkForUpdate();
    if (updateUrl != null && mounted) {
      UpdaterDialog.showIfUpdateAvailable(context, updateUrl);
    }
  }

  Widget _buildPage(NavDest dest) {
    switch (dest) {
      case NavDest.home:        return const HomePage();
      case NavDest.search:      return const SearchPage();
      case NavDest.songs:       return const SongsPage();
      case NavDest.albums:      return const LibraryPage();
      case NavDest.artists:     return const ArtistsPage();
      case NavDest.genres:      return const GenresPage();
      case NavDest.decades:     return const DecadesPage();
      case NavDest.favourites:  return const FavouritesPage();
      case NavDest.playlists:   return const PlaylistsPage();
      case NavDest.discovery:   return const PlaylistsPage(); // handled inside
      case NavDest.recentlyPlayed: return const RecentlyPlayedPage();
      case NavDest.profile:     return const ProfilePage();
      case NavDest.admin:       return const AdminPage();
      case NavDest.settings:    return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onDestSelected: (dest) => setState(() => _currentDest = dest),
                    ),
                    // Main content
                    Expanded(
                      child: Container(
                        color: Sp.bg0,
                        // Use AnimatedSwitcher for smooth page transitions
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: KeyedSubtree(
                            key: ValueKey(_currentDest),
                            child: _buildPage(_currentDest),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Player Bar
              PlayerBar(
                onLyricsPressed: () => setState(() => _showLyrics = !_showLyrics),
              ),
            ],
          ),

          // Lyrics Overlay
          if (_showLyrics)
            Positioned.fill(
              child: LyricsOverlay(
                onClose: () => setState(() => _showLyrics = false),
              ),
            ),
        ],
      ),
    );
  }
}