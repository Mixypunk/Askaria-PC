import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/providers/player_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/theme_notifier.dart';
import 'desktop/app_desktop.dart';
import 'desktop/login_desktop.dart';
// ── Palette partagée (Match Web: --bg0, --bg1, --ac) ────────────────────
class Sp {
  static const bg0 = Color(0xFF080808);
  static const bg1 = Color(0xFF111111);
  static const bg2 = Color(0xFF191919);
  static const bg3 = Color(0xFF222222);
  static const bg4 = Color(0xFF2C2C2C);
  static const bg5 = Color(0xFF383838);

  static const ac  = Color(0xFFE8375A); // Rouge/Rose Web
  static const ac2 = Color(0xFFC92D4A); // Rouge survol (hover)
  static final ac4 = const Color(0xFFE8375A).withValues(alpha: 0.07);

  static const t1  = Color(0xFFF0F0F0); // Text principal
  static const t2  = Color(0xFF909090); // Text secondaire
  static const t3  = Color(0xFF525252);
  static const t4  = Color(0xFF303030);

  static final bd  = Colors.white.withValues(alpha: 0.07);
  static final bd2 = Colors.white.withValues(alpha: 0.13);
}

class GText extends StatelessWidget {
  final String t; final TextStyle? s;
  const GText(this.t, {super.key, this.s});
  @override
  Widget build(BuildContext ctx) => Text(t, style: (s ?? const TextStyle()).copyWith(color: Sp.ac));
}

class GIcon extends StatelessWidget {
  final IconData icon; final double? size;
  const GIcon(this.icon, {super.key, this.size});
  @override
  Widget build(BuildContext ctx) => Icon(icon, size: size, color: Sp.ac);
}

class GBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final bool loading;
  const GBtn(this.label, {super.key, this.onTap, this.loading = false});
  @override
  Widget build(BuildContext ctx) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // Rayon --r du web
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: Sp.ac, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
      ),
    ),
  );
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de la fenêtre Desktop
  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.setSize(const Size(1000, 700));
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.show();
  });
  runApp(const _SplashWrapper());
}
class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();
  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}
class _SplashWrapperState extends State<_SplashWrapper> {
  bool _ready = false;
  bool _logged = false;
  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init() async {
    try {
      await ThemeNotifier.instance.load();
      final api = SwingApiService();
      await api.loadSettings();
      _logged = await api.checkAuth();
    } catch (e) {
      debugPrint('Auth error: $e');
      _logged = SwingApiService().isLoggedIn;
    }
    if (mounted) setState(() => _ready = true);
  }
  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider.value(value: ThemeNotifier.instance),
      ],
      child: _App(logged: _logged),
    );
  }
}
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Sp.bg0,
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_rounded, size: 90, color: Sp.ac),
            SizedBox(height: 40),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Sp.ac, strokeWidth: 2)),
          ],
        )),
      ),
    );
  }
}
class _App extends StatelessWidget {
  final bool logged;
  const _App({required this.logged});
  
  @override
  Widget build(BuildContext ctx) => Consumer<ThemeNotifier>(
    builder: (ctx, theme, _) => MaterialApp(
      title: 'Askaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Segoe UI', // Rapproche visuellement DM Sans sur Windows natif
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Sp.bg0,
        colorScheme: const ColorScheme.dark(
          primary: Sp.ac, secondary: Sp.ac2,
          surface: Sp.bg1,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Sp.t1),
          bodyMedium: TextStyle(color: Sp.t2),
        ),
      ),
      initialRoute: logged ? '/app' : '/login',
      routes: {
        '/login': (_) => const LoginDesktop(),
        '/app':   (_) => const AppDesktop(),
      },
    ),
  );
}