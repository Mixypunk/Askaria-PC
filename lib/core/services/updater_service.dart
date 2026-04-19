import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdaterService {
  static const String repoOwner = 'Mixypunk';
  static const String repoName = 'Askaria-PC';

  /// Vérifie si une nouvelle version est disponible et retourne l'URL de téléchargement de l'exécutable
  static Future<String?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTarget = data['tag_name'] as String; // e.g. "v1.0.1"
        final cleanLatest = latestTarget.replaceAll('v', '');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version; // e.g. "1.0.0"

        if (_isNewerVersion(currentVersion, cleanLatest)) {
          final assets = data['assets'] as List;
          // Cherche l'asset se terminant par .exe
          final exeAsset = assets.firstWhere((asset) => asset['name'].toString().endsWith('.exe'), orElse: () => null);
          if (exeAsset != null) {
            return exeAsset['browser_download_url'] as String;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Démarre le téléchargement et exécute l'installateur à la fin
  static Future<void> downloadAndInstall(String url, Function(double) onProgress) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}\\Askaria-Update.exe';
    
    final dio = Dio();
    await dio.download(
      url,
      tempPath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = received / total;
          onProgress(progress);
        }
      },
    );

    // Création d'un script batch pour attendre la fermeture de l'app puis lancer l'installateur
    final batPath = '${tempDir.path}\\Askaria-Update.bat';
    final batContent = '''
@echo off
echo Mise a jour d'Askaria en cours... Veuillez patienter.
timeout /t 2 /nobreak > NUL
start "" "$tempPath" /SILENT /FORCECLOSEAPPLICATIONS
del "%~f0"
''';
    await File(batPath).writeAsString(batContent);

    // Lancer le script en arrière-plan
    await Process.start('cmd.exe', ['/c', batPath], mode: ProcessStartMode.detached);
    
    // Ferme l'application courante pour déverrouiller l'exécutable
    exit(0);
  }

  /// Compare deux versions sémantiques basiques "x.y.z"
  static bool _isNewerVersion(String current, String latest) {
    List<int> currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      int curr = i < currParts.length ? currParts[i] : 0;
      int lat = i < latestParts.length ? latestParts[i] : 0;
      if (lat > curr) return true;
      if (lat < curr) return false;
    }
    return false;
  }
}
