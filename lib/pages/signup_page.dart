import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controller/user_controller.dart';
import '../utils/toast_message.dart';
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  RxBool usernameAvailable = true.obs;
  bool loading = false;
  bool isChecked = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> handleGoogleLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception("Google user is null");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'username': user.displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final userController = Get.isRegistered<UserController>()
          ? Get.find<UserController>()
          : Get.put(UserController());

      userController.setUser(
        id: user.uid,
        emailadd: user.email ?? '',
        uname: user.displayName ?? '',
      );


      Get.offAll(() => HomePage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign in failed: ${e.toString()}',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signup() async {
    if (!formKey.currentState!.validate()) return;

    if (!usernameAvailable.value) {
      Utils().toastMessage("Username already taken");
      return;
    }

    if (!isChecked) {
      Utils().toastMessage("Please accept Privacy Policy and Terms");
      return;
    }

    setState(() => loading = true);

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.find<UserController>().setUser(
        id: user.uid,
        emailadd: emailController.text.trim(),
        uname: usernameController.text.trim(),
      );

      Get.offAll(() => HomePage());
    } catch (e) {
      Utils().toastMessage(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF007ACC);
    final secondaryColor = const Color(0xFF00BFA6);
    final inputFillColor = Color(0xFFF5F9FF);
    final textColor = Colors.black87;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome! Please fill the details below to create a new account.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      onChanged: (value) async {
                        if (value.trim().isEmpty) {
                          usernameAvailable.value = true;
                          return;
                        }
                        final query = await FirebaseFirestore.instance
                            .collection('users')
                            .where('username', isEqualTo: value.trim())
                            .get();
                        usernameAvailable.value = query.docs.isEmpty;
                        formKey.currentState?.validate();
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Username is required';
                        if (!usernameAvailable.value) return 'Username already taken';
                        return null;
                      },
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFillColor,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                        hintText: "Username",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      if (usernameController.text.trim().isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          usernameAvailable.value ? '✓ Username available' : '✗ Username already taken',
                          style: TextStyle(
                            color: usernameAvailable.value ? Colors.green : Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Email is required";
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$').hasMatch(value)) return "Enter a valid email";
                    return null;
                  },
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFillColor,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                    hintText: "you@example.com",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Password is required";
                    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
                      return "8+ chars, 1 uppercase, 1 lowercase & 1 number";
                    }
                    return null;
                  },
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputFillColor,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    hintText: "Enter password",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (val) => setState(() => isChecked = val ?? false),
                      activeColor: secondaryColor,
                      checkColor: Colors.white,
                    ),
                    const Expanded(
                      child: Text(
                        "I accept the Privacy Policy and Terms of Use",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: loading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                        : const Text(
                      "Register",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: handleGoogleLogin,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryColor.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.google,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
