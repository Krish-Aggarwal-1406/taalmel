import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/user_controller.dart';
import 'controller/meeting_controller.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  Get.put(UserController());
  Get.put(MeetingController());

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    ),
  );
}