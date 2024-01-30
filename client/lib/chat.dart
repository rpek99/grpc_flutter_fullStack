import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:protos/protos.dart';

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key});

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _messages = [];

  late String userName = "";

  late ClientChannel _channel;
  late ChatServiceClient _stub;
  late StreamController<Message> _messageStreamController;
  late StreamSubscription<Message> _messageSubscription;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _channel = ClientChannel(
      'localhost',
      port: 8081,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _stub = ChatServiceClient(_channel);
    _startChatListener();
  }

  void _startChatListener() async {
    final user = User()
      ..id = 'user_id'
      ..name = 'User Name'; // Kullanıcı kimliği ve adını ayarlayın

    final connect = Connect()
      ..user = user
      ..isActive = true;

    final stream = _stub.receiveMessages(connect);

    // Mesajları dinleyin ve UI'yi güncelleyin
    await for (var message in stream) {
      setState(() {
        _messages.add('${message.id}: ${message.content}');
      });
    }
  }

  _sendMessage(String userId, String userName) async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isNotEmpty) {
      final randomMessageId = Random().nextInt(100000);
      final user = User()
        ..id = userId
        ..name = userName; // Kullanıcı kimliği ve adını ayarlayın
      final message = Message()
        ..id = '$randomMessageId'
        ..content = messageContent
        ..user = user;

      await _stub.sendMessage(message);

      setState(() {
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('gRPC Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      userName = _nameController.text;
                    }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (userName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter your name first!!"),
                          ),
                        );
                      } else {
                        _sendMessage(
                          Random().nextInt(1000).toString(),
                          _nameController.text,
                        );
                      }
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.shutdown();
    super.dispose();
  }
}
