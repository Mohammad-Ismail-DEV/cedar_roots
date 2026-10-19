import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'logger.dart';

/// Owns the single socket connection. Event listeners are registered once per
/// event name and exposed as broadcast streams, so screens only subscribe and
/// cancel; they never add or remove raw socket handlers themselves.
class SocketClient {
  io.Socket? _socket;
  int? _userId;
  String? _token;

  final _controllers = <String, StreamController<dynamic>>{};
  final _connection = StreamController<bool>.broadcast();

  bool get isConnected => _socket?.connected ?? false;

  /// Emits true on every (re)connect and false on disconnect.
  Stream<bool> get connection => _connection.stream;

  void connect({
    required String url,
    required String token,
    required int userId,
  }) {
    if (_socket != null && _userId == userId && _token == token) return;
    disconnect();

    _userId = userId;
    _token = token;
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          // Without this the library reuses one connection per URL, so a second sign-in
          // (account switch) would silently keep the first user's token.
          .enableForceNew()
          .build(),
    );
    _socket = socket;

    socket
      ..onConnect((_) {
        AppLog.d('connected as user $userId', 'socket');
        _connection.add(true);
      })
      ..onDisconnect((_) {
        AppLog.d('disconnected', 'socket');
        _connection.add(false);
      })
      ..onConnectError((e) => AppLog.w('connect error: $e', 'socket'));

    for (final event in _controllers.keys) {
      _attach(socket, event);
    }
    socket.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _userId = null;
    _token = null;
  }

  /// Completes once the socket is connected (immediately if it already is).
  Future<void> whenConnected({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (isConnected) return;
    await connection
        .firstWhere((connected) => connected)
        .timeout(
          timeout,
          onTimeout:
              () => throw const SocketRequestException('Socket not connected'),
        );
  }

  /// Broadcast stream of payloads for [event]. Safe to call many times.
  Stream<dynamic> on(String event) {
    final existing = _controllers[event];
    if (existing != null) return existing.stream;

    final controller = StreamController<dynamic>.broadcast();
    _controllers[event] = controller;
    final socket = _socket;
    if (socket != null) _attach(socket, event);
    return controller.stream;
  }

  void _attach(io.Socket socket, String event) {
    socket.on(event, (data) => _controllers[event]?.add(data));
  }

  void emit(String event, [Object? data]) {
    final socket = _socket;
    if (socket == null) {
      AppLog.w('emit "$event" ignored: socket not connected', 'socket');
      return;
    }
    socket.emit(event, data);
  }

  /// Emits [event] and waits for one [responseEvent] (or [errorEvent]).
  /// Subscribes before emitting so the reply can never be missed.
  Future<dynamic> request(
    String event,
    Object? payload, {
    required String responseEvent,
    String? errorEvent,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final completer = Completer<dynamic>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    void finish(void Function() complete) {
      if (completer.isCompleted) return;
      for (final s in subscriptions) {
        s.cancel();
      }
      complete();
    }

    subscriptions.add(
      on(
        responseEvent,
      ).listen((data) => finish(() => completer.complete(data))),
    );
    if (errorEvent != null) {
      subscriptions.add(
        on(errorEvent).listen(
          (data) => finish(
            () => completer.completeError(SocketRequestException('$data')),
          ),
        ),
      );
    }

    emit(event, payload);
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        for (final s in subscriptions) {
          s.cancel();
        }
        throw SocketRequestException('$event timed out');
      },
    );
  }
}

class SocketRequestException implements Exception {
  const SocketRequestException(this.message);
  final String message;

  @override
  String toString() => message;
}
