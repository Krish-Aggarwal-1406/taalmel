import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Utils {
  void toastMessage(String message) {
    Get.snackbar(
      "Alert",
      message,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(10),
      borderRadius: 8,
    );
  }
}
