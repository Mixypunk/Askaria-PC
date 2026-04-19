import 'package:flutter/material.dart';
import '../../core/services/updater_service.dart';
import '../../../main.dart'; // Palette Sp

class UpdaterDialog extends StatefulWidget {
  final String updateUrl;

  const UpdaterDialog({Key? key, required this.updateUrl}) : super(key: key);

  static void showIfUpdateAvailable(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdaterDialog(updateUrl: url),
    );
  }

  @override
  State<UpdaterDialog> createState() => _UpdaterDialogState();
}

class _UpdaterDialogState extends State<UpdaterDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _statusMessage = 'Une nouvelle version est disponible.';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Téléchargement en cours...';
    });

    try {
      await UpdaterService.downloadAndInstall(widget.updateUrl, (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            if (progress == 1.0) {
              _statusMessage = 'Lancement de l\'installation...';
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Erreur lors du téléchargement.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Sp.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Sp.bd),
      ),
      title: Row(
        children: const [
          Icon(Icons.system_update_rounded, color: Sp.ac),
          SizedBox(width: 12),
          Text('Mise à jour disponible', style: TextStyle(color: Sp.t1, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_statusMessage, style: const TextStyle(color: Sp.t2, fontSize: 14)),
            const SizedBox(height: 24),
            if (_isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Sp.bg3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Sp.ac),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${(_progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Sp.t2, fontSize: 12)),
              )
            ]
          ],
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard', style: TextStyle(color: Sp.t3)),
          ),
        if (!_isDownloading)
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Sp.ac,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Télécharger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
