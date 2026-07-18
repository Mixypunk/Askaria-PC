import '../models/song.dart';
import 'api_service.dart';

class LyricsResult {
  final bool isSynced;
  final String? rawText;
  final List<Map<String, dynamic>>? syncedLines;
  final List<String>? unsyncedLines;

  const LyricsResult({
    required this.isSynced,
    this.rawText,
    this.syncedLines,
    this.unsyncedLines,
  });
}

class LyricsService {
  final SwingApiService _api;

  LyricsService(this._api);

  Future<LyricsResult?> fetchLyrics(Song song) async {
    final result = await _api.getLyrics(
      song.hash,
      filepath: song.filepath,
    );

    if (result == null) return null;

    final isSynced = result['synced'] == true;
    final raw = result['lyrics'];

    String? rawText;
    List<Map<String, dynamic>>? syncedLines;
    List<String>? unsyncedLines;

    if (isSynced && raw is List) {
      syncedLines = [];
      for (final e in raw) {
        try {
          syncedLines.add({
            'time': (e['time'] as num).toInt(),
            'text': (e['text'] ?? '').toString(),
          });
        } catch (_) {}
      }
      rawText = 'synced';
    } else if (raw is List) {
      unsyncedLines = List<String>.from(raw.map((e) => e.toString()));
      rawText = unsyncedLines.join('\n');
    } else if (raw is String) {
      rawText = raw;
    }

    return LyricsResult(
      isSynced: isSynced,
      rawText: rawText,
      syncedLines: syncedLines,
      unsyncedLines: unsyncedLines,
    );
  }
}
