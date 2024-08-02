import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';
import '../controller/user_controller.dart';
import '../models/user_model.dart';
class ChatScreen extends StatelessWidget {
  final ChatController chatController = Get.put(ChatController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Obx(() {
        if (chatController.users.isEmpty) {
          return Center(child: CircularProgressIndicator());
        } else {
          return ListView.builder(
            itemCount: chatController.users.length,
            itemBuilder: (context, index) {
              UserModel user = chatController.users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Get.to(ChatDetailScreen(user: user));
                },
              );
            },
          );
        }
      }),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final UserModel user;
  final ChatController chatController = Get.find();
  final TextEditingController messageController = TextEditingController();

  ChatDetailScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    chatController.fetchMessages(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${user.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (chatController.messages.isEmpty) {
                return Center(child: Text('No messages yet.'));
              } else {
                return ListView.builder(
                  itemCount: chatController.messages.length,
                  itemBuilder: (context, index) {
                    var message = chatController.messages[index];
                    return ListTile(
                      title: Text(message['message']),
                      subtitle: Text(message['sender']),
                    );
                  },
                );
              }
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    chatController.sendMessage(user.uid, messageController.text);
                    messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}