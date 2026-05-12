import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../components/toast_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = SwingApiService();
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _heatmap = [];
  bool _loading = true;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _currPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confPwdCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getMyProfile(),
        _api.getHeatmap(),
      ]);
      final prof = results[0] as Map<String, dynamic>;
      final hm   = results[1] as List<Map<String, dynamic>>;
      if (mounted) {
        setState(() {
          _profile = prof;
          _heatmap = hm;
          _usernameCtrl.text = prof['username'] ?? '';
          _emailCtrl.text    = prof['email'] ?? '';
          _bioCtrl.text      = prof['bio'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _emailCtrl.dispose(); _bioCtrl.dispose();
    _currPwdCtrl.dispose(); _newPwdCtrl.dispose(); _confPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon profil',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
          const SizedBox(height: 24),
          // Grid 2 colonnes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar card
              Expanded(child: _AvatarCard(profile: _profile, api: _api, onUpdated: _load)),
              const SizedBox(width: 22),
              // Infos card
              Expanded(child: _InfoCard(
                usernameCtrl: _usernameCtrl,
                emailCtrl: _emailCtrl,
                bioCtrl: _bioCtrl,
                saving: _saving,
                onSave: _saveProfile,
              )),
            ],
          ),
          const SizedBox(height: 22),
          // Heatmap
          _HeatmapCard(heatmap: _heatmap),
          const SizedBox(height: 22),
          // Changer mot de passe
          _PasswordCard(
            currCtrl: _currPwdCtrl,
            newCtrl: _newPwdCtrl,
            confCtrl: _confPwdCtrl,
            onSave: _changePassword,
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _api.updateProfile(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      if (mounted) ToastService.show(context, 'Profil sauvegardé');
    } catch (e) {
      if (mounted) ToastService.show(context, 'Erreur : $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changePassword() async {
    if (_newPwdCtrl.text != _confPwdCtrl.text) {
      ToastService.show(context, 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_newPwdCtrl.text.isEmpty) {
      ToastService.show(context, 'Entrez un nouveau mot de passe');
      return;
    }
    try {
      await _api.changePassword(_currPwdCtrl.text, _newPwdCtrl.text);
      _currPwdCtrl.clear(); _newPwdCtrl.clear(); _confPwdCtrl.clear();
      if (mounted) ToastService.show(context, 'Mot de passe changé !');
    } catch (e) {
      if (mounted) ToastService.show(context, 'Erreur : $e');
    }
  }
}

class _AvatarCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final SwingApiService api;
  final VoidCallback onUpdated;
  const _AvatarCard({required this.profile, required this.api, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final userId = profile['id'];
    final name = profile['username'] ?? '?';
    final role = profile['role'] ?? 'user';
    final initials = name.substring(0, name.length.clamp(0, 2)).toUpperCase();

    return _Card(
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(color: Sp.bg4, shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: userId != null
                    ? CachedNetworkImage(
                        imageUrl: api.getAvatarUrl(userId),
                        httpHeaders: api.authHeaders,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(initials, style: const TextStyle(color: Sp.t1, fontSize: 32, fontWeight: FontWeight.w700)),
                        ),
                      )
                    : Center(
                        child: Text(initials, style: const TextStyle(color: Sp.t1, fontSize: 32, fontWeight: FontWeight.w700))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: () => _pickAvatar(context),
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(color: Sp.ac, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 18, fontWeight: FontWeight.w700, color: Sp.t1)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Sp.ac.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role.toUpperCase(),
                style: const TextStyle(color: Sp.ac, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    // Champ texte pour saisir le chemin fichier (Windows)
    final ctrl = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Sp.bg2,
        title: const Text('Chemin de l\'image', style: TextStyle(color: Sp.t1, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Sp.t1, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'C:\\Users\\...\\photo.jpg',
            hintStyle: TextStyle(color: Sp.t3),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler', style: TextStyle(color: Sp.t2))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Sp.ac),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) {
      if (context.mounted) ToastService.show(context, 'Fichier introuvable');
      return;
    }
    final bytes = await file.readAsBytes();
    await api.uploadAvatar(bytes);
    onUpdated();
    if (context.mounted) ToastService.show(context, 'Avatar mis à jour');
  }
}

class _InfoCard extends StatelessWidget {
  final TextEditingController usernameCtrl, emailCtrl, bioCtrl;
  final bool saving;
  final VoidCallback onSave;
  const _InfoCard({
    required this.usernameCtrl, required this.emailCtrl, required this.bioCtrl,
    required this.saving, required this.onSave,
  });
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Informations'),
          const SizedBox(height: 10),
          _ProfField(ctrl: usernameCtrl, icon: Icons.person_rounded, hint: "Nom d'utilisateur"),
          const SizedBox(height: 10),
          _ProfField(ctrl: emailCtrl, icon: Icons.email_rounded, hint: 'Email'),
          const SizedBox(height: 10),
          _ProfField(ctrl: bioCtrl, icon: Icons.edit_rounded, hint: 'Bio courte...', maxLines: 2),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Sp.ac,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final List<Map<String, dynamic>> heatmap;
  const _HeatmapCard({required this.heatmap});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel("Activité d'écoute"),
          const SizedBox(height: 14),
          if (heatmap.isEmpty)
            const Center(child: Text("Aucune donnée d'activité", style: TextStyle(color: Sp.t3)))
          else
            Wrap(
              spacing: 4, runSpacing: 4,
              children: heatmap.map((h) {
                final count = (h['count'] as int? ?? 0);
                final maxCount = heatmap.map((e) => e['count'] as int? ?? 0).fold(1, (a, b) => a > b ? a : b);
                final ratio = maxCount > 0 ? count / maxCount : 0.0;
                final color = count == 0
                    ? Sp.bg4
                    : Color.lerp(Sp.ac.withValues(alpha: 0.15), Sp.ac, ratio)!;
                return Tooltip(
                  message: '${h['date'] ?? h['hour'] ?? ''}: $count écoutes',
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final TextEditingController currCtrl, newCtrl, confCtrl;
  final VoidCallback onSave;
  const _PasswordCard({required this.currCtrl, required this.newCtrl, required this.confCtrl, required this.onSave});
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Changer le mot de passe'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ProfField(ctrl: currCtrl, icon: Icons.lock_rounded, hint: 'Mot de passe actuel', obscure: true)),
              const SizedBox(width: 10),
              Expanded(child: _ProfField(ctrl: newCtrl, icon: Icons.lock_reset_rounded, hint: 'Nouveau mot de passe', obscure: true)),
              const SizedBox(width: 10),
              Expanded(child: _ProfField(ctrl: confCtrl, icon: Icons.lock_rounded, hint: 'Confirmer', obscure: true)),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Sp.bg3,
              foregroundColor: Sp.t1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Sp.bd2)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: onSave,
            child: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
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
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(color: Sp.t3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.1));
  }
}

class _ProfField extends StatelessWidget {
  final TextEditingController ctrl;
  final IconData icon;
  final String hint;
  final int maxLines;
  final bool obscure;
  const _ProfField({required this.ctrl, required this.icon, required this.hint, this.maxLines = 1, this.obscure = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Sp.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Sp.bd),
      ),
      child: Row(
        children: [
          Icon(icon, color: Sp.t3, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              obscureText: obscure,
              maxLines: obscure ? 1 : maxLines,
              style: const TextStyle(color: Sp.t1, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Sp.t4),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
