import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/player_provider.dart';
import '../../core/services/updater_service.dart';
import '../components/updater_dialog.dart';
import '../../../main.dart'; // Palette Sp
import 'package:qr_flutter/qr_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 110),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 22),
          child: Text('Paramètres', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
        ),

        // Serveur
        _Section(
          title: 'Connexion au serveur',
          icon: Icons.dns_rounded,
          child: _ServerConfig(),
        ),
        const SizedBox(height: 24),

        // Audio
        _Section(
          title: 'Audio',
          icon: Icons.equalizer_rounded,
          child: _AudioConfig(),
        ),
        const SizedBox(height: 24),

        // Mises à jour & Compte
        _Section(
          title: 'Application',
          icon: Icons.system_update_rounded,
          child: Column(
            children: [
              _UpdateConfig(context: context),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Divider(color: Sp.bg3, height: 1),
              const SizedBox(height: 16),
              _PairingConfig(context: context),
              const SizedBox(height: 16),
              const Divider(color: Sp.bg3, height: 1),
              const SizedBox(height: 16),
              _AccountConfig(context: context),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Sp.bg2,
        borderRadius: BorderRadius.circular(10), // --r: 10px
        border: Border.all(color: Sp.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Sp.ac, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Sp.t1, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Sp.bg3, height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ServerConfig extends StatefulWidget {
  @override
  State<_ServerConfig> createState() => _ServerConfigState();
}

class _ServerConfigState extends State<_ServerConfig> {
  final _ctrl = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = SwingApiService().baseUrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('URL du serveur Askaria', style: TextStyle(color: Sp.t2, fontSize: 13.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Sp.t1, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'https://askaria-music.duckdns.org',
                  hintStyle: const TextStyle(color: Sp.t3),
                  filled: true,
                  fillColor: Sp.bg4,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Sp.ac)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                await SwingApiService().saveUrl(_ctrl.text.trim());
                if (mounted) setState(() => _saved = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _saved = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Sp.ac,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_saved ? '✓ Sauvegardé' : 'Sauvegarder', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AudioConfig extends StatefulWidget {
  @override
  State<_AudioConfig> createState() => _AudioConfigState();
}

class _AudioConfigState extends State<_AudioConfig> {
  @override
  Widget build(BuildContext context) {
    final crossfadeSeconds = context.select<PlayerProvider, int>((p) => p.crossfadeSeconds);
    final player = context.read<PlayerProvider>();

    return Column(
      children: [
        _SettingRow(
          label: 'Crossfade',
          subtitle: 'Fondu entre les chansons (${crossfadeSeconds}s)',
          child: SizedBox(
            width: 200,
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 4,
                activeTrackColor: Sp.ac,
                inactiveTrackColor: Sp.bg3,
                thumbColor: Sp.ac,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: crossfadeSeconds.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                onChanged: (v) => player.setCrossfade(v.toInt()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateConfig extends StatefulWidget {
  final BuildContext context;
  const _UpdateConfig({required this.context});

  @override
  State<_UpdateConfig> createState() => _UpdateConfigState();
}

class _UpdateConfigState extends State<_UpdateConfig> {
  bool _checking = false;
  String? _statusDesc;

  @override
  Widget build(BuildContext bc) {
    return _SettingRow(
      label: 'Mises à jour',
      subtitle: _statusDesc ?? 'Vérifier manuellement les mises à jour',
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Sp.bg3,
          foregroundColor: Sp.t1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _checking ? null : () async {
          setState(() { _checking = true; _statusDesc = 'Recherche en cours...'; });
          final updateUrl = await UpdaterService.checkForUpdate();
          if (!bc.mounted) return;
          setState(() { _checking = false; _statusDesc = updateUrl != null ? 'Mise à jour trouvée !' : 'Vous êtes à jour.'; });
          if (updateUrl != null) UpdaterDialog.showIfUpdateAvailable(bc, updateUrl);
        },
        child: _checking
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Sp.t1))
          : const Text('Vérifier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      ),
    );
  }
}

class _AccountConfig extends StatelessWidget {
  final BuildContext context;
  const _AccountConfig({required this.context});

  @override
  Widget build(BuildContext bc) {
    return _SettingRow(
      label: 'Déconnexion',
      subtitle: 'Retourner à l\'écran de connexion',
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        onPressed: () async {
          await SwingApiService().logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget child;

  const _SettingRow({required this.label, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Sp.t1, fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Sp.t2, fontSize: 12.5)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PairingConfig extends StatelessWidget {
  final BuildContext context;
  const _PairingConfig({required this.context});

  @override
  Widget build(BuildContext bc) {
    return _SettingRow(
      label: 'Connexion rapide (Mobile)',
      subtitle: 'Affiche un QR Code pour vous connecter rapidement depuis l\'application mobile',
      child: ElevatedButton.icon(
        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
        label: const Text('Afficher le QR Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        onPressed: () => _showQrDialog(bc),
        style: ElevatedButton.styleFrom(
          backgroundColor: Sp.ac,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _showQrDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const _QrDialog(),
    );
  }
}

class _QrDialog extends StatefulWidget {
  const _QrDialog();
  @override
  State<_QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends State<_QrDialog> {
  String? _qrData;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final data = await SwingApiService().getPairCode();
    if (!mounted) return;
    if (data != null && data['code'] != null) {
      final serverUrl = SwingApiService().baseUrl;
      setState(() {
        _qrData = '$serverUrl ${data['code']}';
        _loading = false;
      });
    } else {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Sp.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Connexion rapide', style: TextStyle(color: Sp.t1, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Scannez ce code depuis l\'application mobile pour vous connecter instantanément.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Sp.t2, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Sp.ac)))
            else if (_error || _qrData == null)
              const SizedBox(height: 200, child: Center(child: Text('Erreur lors de la génération du code', style: TextStyle(color: Colors.redAccent))))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Sp.t1,
                  side: BorderSide(color: Sp.bd),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
