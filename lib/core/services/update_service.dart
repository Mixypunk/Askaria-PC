import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _owner  = 'Mixypunk';
const _repo   = 'askaria-PC'; // Mettre à jour au besoin
const _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';
const _updateUrl = 'https://github.com/$_owner/$_repo/releases/latest';

class UpdateInfo {
  final String version;
  final String tagName;
  final String downloadUrl;
  final String releaseNotes;
  const UpdateInfo({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static final UpdateService _i = UpdateService._();
  factory UpdateService() => _i;
  UpdateService._();

  static bool _checkedThisSession = false;

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 8)
        ..options.receiveTimeout = const Duration(seconds: 8);

      final resp = await dio.get(_apiUrl, options: Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        validateStatus: (s) => s != null && s < 500,
      ));

      if (resp.statusCode != 200) return null;
      final data = resp.data as Map<String, dynamic>;

      final tagName       = (data['tag_name'] as String? ?? '').trim();
      if (tagName.isEmpty) return null;
      final latestVersion = tagName.replaceFirst(RegExp(r'^v'), '');

      final info          = await PackageInfo.fromPlatform();
      final currentVersion = info.version.trim();

      if (!_isNewer(latestVersion, currentVersion)) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('update_ignored_version') == latestVersion) return null;

      return UpdateInfo(
        version:      latestVersion,
        tagName:      tagName,
        downloadUrl:  _updateUrl,
        releaseNotes: data['body'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  bool _isNewer(String latest, String current) {
    try {
      final l = latest.split('+').first.split('.').map(int.parse).toList();
      final c = current.split('+').first.split('.').map(int.parse).toList();
      while (l.length < 3) l.add(0);
      while (c.length < 3) c.add(0);
      for (int i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> openUpdateUrl() async {
    final uri = Uri.parse(_updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<UpdateInfo?> checkOnce() async {
    if (_checkedThisSession) return null;
    _checkedThisSession = true;
    return checkForUpdate();
  }

  Future<void> ignoreVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('update_ignored_version', version);
  }
}

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.system_update_rounded, color: Color(0xFF8E54E9), size: 28),
        SizedBox(width: 10),
        Expanded(child: Text('Mise à jour disponible',
          style: TextStyle(color: Colors.white, fontSize: 17))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF4776E6), Color(0xFF8E54E9), Color(0xFFD63AF9)]),
            borderRadius: BorderRadius.circular(20)),
          child: Text('Version ${info.version}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        const Text('Une nouvelle version est disponible sur GitHub.',
          style: TextStyle(color: Color(0xFF9D9DB8))),
      ]),
      actions: [
        TextButton(
          onPressed: () async {
            await UpdateService().ignoreVersion(info.version);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Plus tard', style: TextStyle(color: Color(0xFF9D9DB8)))),
        GestureDetector(
          onTap: () async {
            await UpdateService().openUpdateUrl();
            if (context.mounted) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF4776E6), Color(0xFF8E54E9), Color(0xFFD63AF9)]),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('Télécharger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ],
    );
  }
}
