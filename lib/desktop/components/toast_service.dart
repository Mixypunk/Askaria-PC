import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';

/// Service de toasts légers — s'affiche au-dessus de la PlayerBar.
/// Usage : ToastService.show(context, 'Message')
class ToastService {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(message: message),
    );
    overlay.insert(entry);
    _current = entry;

    _timer = Timer(duration, () {
      _current?.remove();
      _current = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 88 + 14, // au-dessus de la PlayerBar (88px)
      left: 0, right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Sp.bg4,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Sp.bd2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(color: Sp.t1, fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
