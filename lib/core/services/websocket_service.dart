import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Streams pour l'UI
  final _scanProgressController = StreamController<Map<String, dynamic>>.broadcast();
  final _userActivityController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get scanProgressStream => _scanProgressController.stream;
  Stream<Map<String, dynamic>> get userActivityStream => _userActivityController.stream;

  bool get isConnected => _isConnected;

  void connect() async {
    if (_isConnected || _isReconnecting) return;
    _isReconnecting = true;

    try {
      final token = SwingApiService().accessToken;
      if (token == null) {
        _isReconnecting = false;
        return;
      }

      var wsUrl = SwingApiService().baseUrl.replaceFirst('http', 'ws');
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      wsUrl = '$wsUrl/ws/$token';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel?.ready;
      
      _isConnected = true;
      _isReconnecting = false;
      _reconnectTimer?.cancel();
      
      debugPrint('WebSocket connecté !');

      _startPingTimer();

      _channel?.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _handleMessage(data);
          } catch (e) {
            debugPrint('Erreur de parsing WS: $e');
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (e) {
          debugPrint('Erreur WebSocket: $e');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('Impossible de se connecter au WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isReconnecting = false;
    _pingTimer?.cancel();
    _channel = null;

    // Tentative de reconnexion après 5 secondes
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (SwingApiService().isLoggedIn) {
        connect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'ping') {
      _send({'type': 'pong'});
    } else if (type == 'scan_progress') {
      _scanProgressController.add(data);
    } else if (type == 'user_activity') {
      _userActivityController.add(data);
    } else if (type == 'connected') {
      debugPrint('WS: Session établie (Users: ${data['active_users']})');
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        debugPrint('Erreur d\'envoi WS: $e');
      }
    }
  }

  void scrobble(String songHash, int positionSeconds, int durationSeconds) {
    _send({
      'type': 'scrobble',
      'song_hash': songHash,
      'position': positionSeconds,
      'duration': durationSeconds,
    });
  }

  void broadcastNowPlaying(String songHash, String title) {
    _send({
      'type': 'now_playing',
      'song_hash': songHash,
      'title': title,
    });
  }

  void disconnect() {
    _isConnected = false;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
