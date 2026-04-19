import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../main.dart';
import 'package:window_manager/window_manager.dart';

class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});
  @override
  State<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> {
  final _server = TextEditingController();
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false, _obs = true;
  String? _err;

  Future<void> _login() async {
    if (_u.text.trim().isEmpty || _p.text.isEmpty) {
      setState(() => _err = 'Remplissez tous les champs'); return;
    }
    setState(() { _loading = true; _err = null; });
    
    final customServer = _server.text.trim();
    if (customServer.isNotEmpty) {
       SwingApiService().setCustomBaseUrl(customServer);
    }

    final ok = await SwingApiService().login(_u.text.trim(), _p.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/app');
    } else {
      setState(() { _loading = false; _err = 'Identifiants ou serveur incorrects'; });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Sp.bg,
      body: Column(
        children: [
          SizedBox(height: 38, child: WindowCaption(brightness: Brightness.dark, backgroundColor: Colors.transparent)),
          Expanded(
            child: Center(
              child: Container(
                width: 400, padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: Sp.surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(shaderCallback: (b) => kGradV.createShader(b), child: const Icon(Icons.music_note_rounded, size: 60, color: Colors.white)),
                    const SizedBox(height: 20),
                    const Text('Connexion à Askaria PC', style: TextStyle(color: Sp.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    _input(_server, 'Adresse du serveur (Optionnel)', Icons.cloud_outlined),
                    const SizedBox(height: 12),
                    _input(_u, 'Nom d''utilisateur', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(color: Sp.card, borderRadius: BorderRadius.circular(6)),
                      child: TextField(
                        controller: _p, obscureText: _obs, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(),
                        style: const TextStyle(color: Sp.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Mot de passe', hintStyle: const TextStyle(color: Sp.white70),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Sp.white70, size: 20),
                          suffixIcon: IconButton(icon: Icon(_obs ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Sp.white70, size: 20), onPressed: () => setState(() => _obs = !_obs)),
                          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    if (_err != null) ...[const SizedBox(height: 12), Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))],
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: GBtn('Se connecter', onTap: _loading ? null : _login, loading: _loading)),
                  ]
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon) {
    return Container(
      height: 48, decoration: BoxDecoration(color: Sp.card, borderRadius: BorderRadius.circular(6)),
      child: TextField(
        controller: c, textInputAction: TextInputAction.next, style: const TextStyle(color: Sp.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Sp.white70),
          prefixIcon: Icon(icon, color: Sp.white70, size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}