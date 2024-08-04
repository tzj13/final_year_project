import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';
import '../models/user_model.dart' as model;

class ChatDetailScreen extends StatelessWidget {
  final model.UserModel user;
  final ChatController chatController = Get.find();
  final TextEditingController messageController = TextEditingController();

  ChatDetailScreen({required this.user}) {
    // Start listening to messages for the specific chat
    chatController.listenToMessages(user.uid);
  }

  @override
  Widget build(BuildContext context) {
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
                    bool isSender = message['sender'] == chatController.userController.user.uid;

                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              message['imageUrl'] != null
                                  ? Image.network(
                                message['imageUrl'],
                                height: 280,
                                width: 300,
                                fit: BoxFit.cover,
                              )
                                  : Text(message['message']),
                              SizedBox(height: 5),
                              Text(
                                message['sender'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () {
                    chatController.sendImage(user.uid);
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
