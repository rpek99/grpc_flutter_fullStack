import 'dart:async';

import 'package:protos/protos.dart';

class ChatService extends ChatServiceBase {
  final List<StreamController<Message>> _clients = [];

  @override
  Stream<Message> receiveMessages(ServiceCall call, Void request) async* {
    final controller = StreamController<Message>();
    _clients.add(controller);

    // Yield all messages to the client
    for (var client in _clients) {
      await for (var message in client.stream) {
        yield message;
      }
    }
  }

  @override
  Future<Void> sendMessage(ServiceCall call, Message request) async {
    for (var client in _clients) {
      client.add(request);
    }
    return Void();
  }
}
