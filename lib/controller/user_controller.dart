import 'package:get/get.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  var currentUser = UserModel(uid: '', name: '', email: '').obs;

  void setCurrentUser(UserModel user) {
    currentUser.value = user;
  }

  UserModel get user => currentUser.value;
}
