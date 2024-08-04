import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  String uid;
  String name;
  String email;

  UserModel({required this.uid, required this.name, required this.email});

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      uid: doc['uid'],
      name: doc['name'],
      email: doc['email'],
    );
  }
}
