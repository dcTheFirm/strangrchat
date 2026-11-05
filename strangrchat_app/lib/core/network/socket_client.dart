import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'auth_service.dart';

class SocketClient {
  SocketClient({required this._authService});

  final AuthService _authService;
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<io.Socket> connect() async {
    if (_socket?.connected == true) return _socket!;
    final session = await _authService.ensureAnonymousSession();

    _socket?.dispose();
    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': session.token})
          .enableForceNew()
          .enableReconnection()
          .build(),
    );
    return _socket!;
  }

  void emit(String event, [Object? payload]) {
    if (payload == null) {
      _socket?.emit(event);
    } else {
      _socket?.emit(event, payload);
    }
  }

  void emitWithAck(
    String event,
    Object? payload,
    void Function(dynamic response) acknowledge,
  ) {
    _socket?.emitWithAck(event, payload, ack: acknowledge);
  }

  void on(String event, void Function(dynamic data) listener) {
    _socket?.on(event, listener);
  }

  void off(String event, [void Function(dynamic data)? listener]) {
    _socket?.off(event, listener);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}

final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient(authService: ref.watch(authServiceProvider));
  ref.onDispose(client.dispose);
  return client;
});
