import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart' as model;
import 'user_controller.dart';

class ChatController extends GetxController {
  var users = <model.UserModel>[].obs;
  var messages = <Map<String, dynamic>>[].obs;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final UserController userController = Get.find<UserController>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    print("Fetching users...");
    try {
      QuerySnapshot querySnapshot = await firestore.collection('users').get();
      users.value = querySnapshot.docs.map((doc) => model.UserModel.fromDocument(doc)).toList();
      print("Users fetched: ${users.length}");
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void listenToMessages(String userId) {
    print("Listening to messages for user: $userId");
    firestore
        .collection('chats')
        .where('participants', arrayContains: userController.user.uid)
        .orderBy('timestamp')
        .snapshots()
        .listen((querySnapshot) {
      messages.value = querySnapshot.docs
          .where((doc) => doc['participants'].contains(userController.user.uid) && doc['participants'].contains(userId))
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      print("Messages updated: ${messages.length}");
    });
  }

  void sendMessage(String recipientId, String message) async {
    print("Sending message to $recipientId: $message");
    try {
      await firestore.collection('chats').add({
        'sender': userController.user.uid,
        'recipient': recipientId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [userController.user.uid, recipientId],
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> sendImage(String recipientId) async {
    print("Sending image to $recipientId");
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        String fileName = 'chats/${DateTime.now().millisecondsSinceEpoch}.png';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        await firestore.collection('chats').add({
          'sender': userController.user.uid,
          'recipient': recipientId,
          'message': '',
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'participants': [userController.user.uid, recipientId],
        });
      }
    } catch (e) {
      print("Error sending image: $e");
    }
  }
}
