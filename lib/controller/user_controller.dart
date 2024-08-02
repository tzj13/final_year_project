import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';




class UserController extends GetxController {
  var currentUser = UserModel().obs;

  void setCurrentUser(UserModel user) {
    currentUser.value = user;
  }

  UserModel get user => currentUser.value;
}
