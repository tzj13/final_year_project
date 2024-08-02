// class UserModel {
//   String uid;
//   String name;
//   String email;
//
//   UserModel({required this.uid, required this.name, required this.email});
//
//   factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
//     return UserModel(
//       uid: documentId,
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'email': email,
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String email;

  UserModel({this.uid = '', this.name = '', this.email = ''});

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      uid: doc.id,
      name: doc['name'],
      email: doc['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
    );
  }
}

