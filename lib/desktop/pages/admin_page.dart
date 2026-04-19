import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../components/toast_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _api = SwingApiService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _scanStatus = '';
  bool _scanning = false;
  Map<String, dynamic> _lastfm = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getAdminUsers(),
        _api.getLastFmStatus(),
      ]);
      if (mounted) setState(() {
        _users = results[0] as List<Map<String, dynamic>>;
        _lastfm = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan(bool incremental) async {
    setState(() { _scanning = true; _scanStatus = 'Scan en cours...'; });
    try {
      await _api.scanLibrary(incremental: incremental);
      if (mounted) setState(() { _scanning = false; _scanStatus = incremental ? 'Scan incrémental terminé' : 'Scan complet terminé'; });
    } catch (e) {
      if (mounted) setState(() { _scanning = false; _scanStatus = 'Erreur : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Administration',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
          const SizedBox(height: 24),

          // Bibliothèque
          _Card(
            title: 'Bibliothèque', icon: Icons.library_music_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    _AdminBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Scanner tout',
                      loading: _scanning,
                      onTap: () => _scan(false),
                    ),
                    _AdminBtn(
                      icon: Icons.update_rounded,
                      label: 'Scan incrémental',
                      loading: _scanning,
                      onTap: () => _scan(true),
                    ),
                  ],
                ),
                if (_scanStatus.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_scanStatus, style: const TextStyle(color: Sp.t2, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Utilisateurs
          _Card(
            title: 'Utilisateurs', icon: Icons.people_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._users.map((u) => _UserRow(user: u, api: _api, onDeleted: _load)),
                const SizedBox(height: 10),
                _AdminBtn(
                  icon: Icons.person_add_rounded,
                  label: 'Nouvel utilisateur',
                  onTap: () => _createUser(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Last.fm
          _Card(
            title: 'Last.fm', icon: Icons.radio_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastfm['status'] ?? 'Non configuré',
                  style: const TextStyle(color: Sp.t2, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Config : LASTFM_API_KEY · LASTFM_API_SECRET · LASTFM_USERNAME · LASTFM_PASSWORD_HASH',
                  style: TextStyle(color: Sp.t3, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser(BuildContext context) async {
    final usrCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String role = 'user';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: Sp.bg2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Nouvel utilisateur', style: TextStyle(color: Sp.t1, fontWeight: FontWeight.w700, fontFamily: 'Segoe UI')),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: usrCtrl, hint: "Nom d'utilisateur"),
                const SizedBox(height: 10),
                _Field(ctrl: pwdCtrl, hint: 'Mot de passe', obscure: true),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: role,
                  dropdownColor: Sp.bg3,
                  style: const TextStyle(color: Sp.t1),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setSt(() => role = v ?? 'user'),
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
    if (result == true && usrCtrl.text.isNotEmpty && pwdCtrl.text.isNotEmpty) {
      try {
        await _api.createUser(usrCtrl.text.trim(), pwdCtrl.text, role);
        await _load();
        if (context.mounted) ToastService.show(context, 'Utilisateur créé');
      } catch (e) {
        if (context.mounted) ToastService.show(context, 'Erreur : $e');
      }
    }
    usrCtrl.dispose();
    pwdCtrl.dispose();
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final SwingApiService api;
  final VoidCallback onDeleted;
  const _UserRow({required this.user, required this.api, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Sp.bg2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Sp.bd),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Sp.bg4, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Sp.t3, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['username'] ?? '', style: const TextStyle(color: Sp.t1, fontWeight: FontWeight.w500, fontSize: 13.5)),
                Text(user['role'] ?? 'user', style: const TextStyle(color: Sp.t2, fontSize: 11)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Sp.bg2,
                  title: Text("Supprimer ${user['username']} ?", style: const TextStyle(color: Sp.t1)),
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
                try {
                  await api.deleteUser(user['id'].toString());
                  onDeleted();
                  if (context.mounted) ToastService.show(context, 'Utilisateur supprimé');
                } catch (e) {
                  if (context.mounted) ToastService.show(context, 'Erreur : $e');
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            child: const Text('Supprimer', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Sp.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Sp.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Sp.ac, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Sp.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Divider(color: Sp.bg3, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AdminBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _AdminBtn({required this.icon, required this.label, required this.onTap, this.loading = false});
  @override
  State<_AdminBtn> createState() => _AdminBtnState();
}

class _AdminBtnState extends State<_AdminBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg4 : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Sp.bd2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.loading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Sp.t1))
                  : Icon(widget.icon, color: Sp.t1, size: 14),
              const SizedBox(width: 8),
              Text(widget.label, style: const TextStyle(color: Sp.t1, fontWeight: FontWeight.w500, fontSize: 12.5)),
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
  final bool obscure;
  const _Field({required this.ctrl, required this.hint, this.obscure = false});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Sp.t1, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Sp.t3),
        filled: true, fillColor: Sp.bg3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Sp.ac)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }
}
