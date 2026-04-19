import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/models/song.dart';
import '../../core/providers/player_provider.dart';
import '../components/song_table.dart';

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  final _api = SwingApiService();
  List<Song> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // D'abord l'historique local du player
    final localHistory = context.read<PlayerProvider>().history;
    if (localHistory.isNotEmpty) {
      setState(() { _recent = localHistory; _loading = false; });
    }
    // Puis l'historique serveur
    try {
      final data = await _api.getHistory(limit: 50);
      final tracks = data['tracks'] as List? ?? data['items'] as List? ?? [];
      final songs = tracks.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted && songs.isNotEmpty) setState(() { _recent = songs; _loading = false; });
      else if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Sp.ac));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 26, 28, 22),
          child: Text('Récemment joués',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
        ),
        Expanded(
          child: _recent.isEmpty
              ? const Center(child: Text('Aucun historique', style: TextStyle(color: Sp.t3)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: SongTable(songs: _recent),
                ),
        ),
      ],
    );
  }
}
