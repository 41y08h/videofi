import 'package:socket_io_client/socket_io_client.dart' as IO;

const kWebsocketsApiUrl = "http://10.0.2.2:5000";

class SocketConnection {
  static final SocketConnection _instance = SocketConnection._();
  SocketConnection._();

  factory SocketConnection() {
    return _instance;
  }

  IO.Socket? _socket;
  Future<IO.Socket> get socket async => _socket ??= await initialize();

  Future<IO.Socket> initialize() async {
    return IO.io(kWebsocketsApiUrl,
        IO.OptionBuilder().setTransports(['websocket']).build());
  }
}
