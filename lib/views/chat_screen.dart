import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';
import '../models/user_model.dart' as model;
import 'detialscreen.dart';

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
              model.UserModel user = chatController.users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Get.to(() => ChatDetailScreen(user: user));
                },
              );
            },
          );
        }
      }),
    );
  }
}
