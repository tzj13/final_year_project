import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartcryptology/controller/user_controller.dart';
import '../models/user_model.dart';
class ChatController extends GetxController {
  var users = <UserModel>[].obs;
  var messages = <Map<String, dynamic>>[].obs;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final UserController userController = Get.find<UserController>();
  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }
  void fetchUsers() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('users').get();
      users.value = querySnapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching users: $e");
    }
  }
  void fetchMessages(String userId) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('chats')
          .where('sender', isEqualTo: userController.user.uid)
          .where('recipient', isEqualTo: userId)
          .orderBy('timestamp')
          .get();

      messages.value = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  void sendMessage(String recipientId, String message) async {
    try {
      await firestore.collection('chats').add({
        'sender': userController.user.uid,
        'recipient': recipientId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      fetchMessages(recipientId); // Refresh messages after sending
    } catch (e) {
      print("Error sending message: $e");
    }
  }
}
