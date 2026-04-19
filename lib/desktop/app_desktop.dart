import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../main.dart'; // Import pour Palette Sp
import 'components/sidebar.dart';
import 'components/player_bar.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/library_page.dart';
import 'pages/settings_page.dart';
import '../core/services/updater_service.dart';
import 'components/updater_dialog.dart';

class AppDesktop extends StatefulWidget {
  const AppDesktop({Key? key}) : super(key: key);

  @override
  State<AppDesktop> createState() => _AppDesktopState();
}

class _AppDesktopState extends State<AppDesktop> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  Future<void> _checkUpdates() async {
    // Vérification silencieuse 3s après le démarrage pour ne pas ralentir le rendu initial
    await Future.delayed(const Duration(seconds: 3));
    final updateUrl = await UpdaterService.checkForUpdate();
    if (updateUrl != null && mounted) {
      UpdaterDialog.showIfUpdateAvailable(context, updateUrl);
    }
  }

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Sp.bg0,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kWindowCaptionHeight),
        child: SizedBox(
          height: kWindowCaptionHeight,
          child: const WindowCaption(
            brightness: Brightness.dark,
            backgroundColor: Sp.bg0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sidebar
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (idx) => setState(() => _selectedIndex = idx),
                ),

                // 2. Zone principale avec contenu
                Expanded(
                  child: Container(
                    color: Sp.bg0,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Player Bar (toujours visible en bas)
          const PlayerBar(),
        ],
      ),
    );
  }
}