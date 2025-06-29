import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controller/user_controller.dart';
import '../utils/toast_message.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<UserCredential> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser!.authentication;
    final googleAuthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await auth.signInWithCredential(googleAuthCredential);

    final user = userCredential.user!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Get.find<UserController>().setUser(
      id: user.uid,
      emailadd: user.email ?? '',
      uname: user.displayName ?? '',
    );

    Get.off(() => HomePage());

    return userCredential;
  }

  void login() async {
    setState(() {
      loading = true;
    });

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        Utils().toastMessage("User record not found");
        setState(() {
          loading = false;
        });
        return;
      }

      final data = userDoc.data()!;

      Get.find<UserController>().setUser(
        id: uid,
        emailadd: data['email'],
        uname: data['username'],
      );

      Get.offAll(() => HomePage());
    } catch (e) {
      Utils().toastMessage(e.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7F00FF);
    final secondaryColor = const Color(0xFFE100FF);
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.04),
                    Image.asset(
                      "assets/Taalmel_logo-removebg-preview.png",
                      height: height * 0.35,
                      fit: BoxFit.fitWidth,
                    ),
                    Text(
                      "Hey you are already set",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    Text(
                      "Just Log in and go",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.03),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Email is required";
                              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value)) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withAlpha(20),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryColor, width: 2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              labelText: "Email",
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.025),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Password is required";
                              if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d]{8,}$')
                                  .hasMatch(value)) {
                                return "Password must be 8+ chars, 1 uppercase, 1 lowercase & 1 number";
                              }
                              return null;
                            },
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withAlpha(20),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryColor, width: 2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.035),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          login();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 3,
                        shadowColor: secondaryColor.withOpacity(0.4),
                      ),
                      child: Container(
                        height: height * 0.06,
                        width: width * 0.7,
                        alignment: Alignment.center,
                        child: loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Log In",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      "-------------------------or-------------------------",
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    SizedBox(height: height * 0.02),
                    GestureDetector(
                      onTap: () async {
                        try {
                          await loginWithGoogle();
                        } catch (e) {
                          Get.snackbar("Error", "Google Sign-In failed",
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: secondaryColor.withOpacity(0.6),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 17),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => SignUpPage());
                          },
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
