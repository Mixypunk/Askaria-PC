import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/player_provider.dart';
import '../components/toast_service.dart';

class DecadesPage extends StatefulWidget {
  const DecadesPage({super.key});

  @override
  State<DecadesPage> createState() => _DecadesPageState();
}

class _DecadesPageState extends State<DecadesPage> {
  final _api = SwingApiService();
  List<Map<String, dynamic>> _decades = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _api.getDecades();
      if (mounted) setState(() { _decades = data; _loading = false; });
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
          child: Text('Décennies',
              style: TextStyle(fontFamily: 'Segoe UI', fontSize: 24, fontWeight: FontWeight.w800, color: Sp.t1, letterSpacing: -0.3)),
        ),
        Expanded(
          child: _decades.isEmpty
              ? const Center(child: Text('Aucune décennie disponible', style: TextStyle(color: Sp.t3)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
                  child: Wrap(
                    spacing: 13, runSpacing: 13,
                    children: _decades.map((d) => _DecadeCard(
                      decade: d,
                      onTap: () => _playDecade(context, d['year']?.toString() ?? '', d['label']?.toString() ?? ''),
                    )).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _playDecade(BuildContext context, String year, String label) async {
    ToastService.show(context, 'Chargement de la décennie...');
    final tracks = await _api.getDecadeTracks(year);
    if (tracks.isNotEmpty && context.mounted) {
      context.read<PlayerProvider>().playSong(tracks.first, queue: tracks);
      ToastService.show(context, 'Lecture : $label');
    }
  }
}

class _DecadeCard extends StatefulWidget {
  final Map<String, dynamic> decade;
  final VoidCallback onTap;
  const _DecadeCard({required this.decade, required this.onTap});
  @override
  State<_DecadeCard> createState() => _DecadeCardState();
}

class _DecadeCardState extends State<_DecadeCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final label = widget.decade['label']?.toString() ?? '';
    final count = widget.decade['count'] as int? ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 155, padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _hover ? Sp.bg3 : Sp.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? Sp.bd : Colors.transparent),
          ),
          child: Column(
            children: [
              Container(
                width: 129, height: 129,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Sp.bg4,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Sp.ac,
                          fontSize: 22, fontWeight: FontWeight.w900,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: Sp.ac, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Text('$count titres', textAlign: TextAlign.center,
                  style: const TextStyle(color: Sp.t2, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}
