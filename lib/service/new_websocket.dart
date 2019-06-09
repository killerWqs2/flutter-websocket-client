import "dart:async";

import "package:stomp/impl/plugin.dart";
import "package:stomp/stomp.dart";
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

Future<StompClient> connect(String url,
        {String host,
        String login,
        String passcode,
        List<int> heartbeat,
        void onConnect(StompClient client, Map<String, String> headers),
        void onDisconnect(StompClient client),
        void onError(StompClient client, String message, String detail,
            Map<String, String> headers),
        void onFault(StompClient client, error, stackTrace)}) async =>
    connectWith(await IOWebSocketChannel.connect(url),
        host: host,
        login: login,
        passcode: passcode,
        heartbeat: heartbeat,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onError: onError,
        onFault: onFault);

Future<StompClient> connectWith(IOWebSocketChannel channel,
        {String host,
        String login,
        String passcode,
        List<int> heartbeat,
        void onConnect(StompClient client, Map<String, String> headers),
        void onDisconnect(StompClient client),
        void onError(StompClient client, String message, String detail,
            Map<String, String> headers),
        void onFault(StompClient client, error, stackTrace)}) =>
    StompClient.connect(_WSStompConnector.startWith(channel),
        host: host,
        login: login,
        passcode: passcode,
        heartbeat: heartbeat,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onError: onError,
        onFault: onFault);

class _WSStompConnector extends StringStompConnector {
  final IOWebSocketChannel _socket;
  StreamSubscription _listen;

  static _WSStompConnector startWith(IOWebSocketChannel socket) =>
      new _WSStompConnector(socket);

  _WSStompConnector(this._socket) {
    _init();
  }

  void _init() {
    _listen = _socket.stream.listen((data) {
      print("Read $data");
      if (data != null) {
        final String sdata = data.toString();
        if (sdata.isNotEmpty) onString(sdata);
      }
    });
    _listen.onError((err) => onError(err, null));
    _listen.onDone(() => onClose());

    _socket.stream.handleError((error) => onError(error, null));

    _socket.sink.done.then((v) {
      onClose();
    });
  }

  @override
  Future close() {
    _listen.cancel();
    _socket.sink.close(status.goingAway);
    return new Future.value();
  }

  @override
  void writeString_(String string) {
    print("Write $string");
    _socket.sink.add(string);
  }
}
