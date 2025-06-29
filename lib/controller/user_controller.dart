import 'package:get/get.dart';

class UserController extends GetxController {
  var uid = ''.obs;
  var email = ''.obs;
  var username = ''.obs;

  void setUser({
    required String id,
    required String emailadd,
    required String uname,
  }) {
    uid.value = id;
    email.value = emailadd;
    username.value = uname;
  }
}
