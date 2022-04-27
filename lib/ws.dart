import 'package:socket_io_client/socket_io_client.dart' as IO;

const kWebsocketsApiUrl = "http://127.0.0.1:5000";

class SocketConnection {
  static final SocketConnection _instance = SocketConnection._();
  SocketConnection._();

  factory SocketConnection() {
    return _instance;
  }

  final IO.Socket _socket = IO.io(
    kWebsocketsApiUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setReconnectionDelay(500)
        .setReconnectionAttempts(10000)
        .build(),
  );
  IO.Socket get socket => _socket;
}
