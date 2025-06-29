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
      if (googleUser == null) {
        return; // User cancelled the sign-in
      }
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

      Get.find<UserController>().setUser(
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
    final primaryColor = const Color(0xFF7F00FF);
    final secondaryColor = const Color(0xFFE100FF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/starrynight.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        height: 180,
                        child: Image.asset(
                          "assets/Kalpna_Kosh_final-removebg-preview.png",
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Hey There",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Create an Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 1))],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Fixed Username Field - Removed Obx wrapper
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
                              // Trigger form validation after checking username
                              formKey.currentState?.validate();
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Username is required';
                              if (!usernameAvailable.value) return 'Username already taken';
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
                              prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                              hintText: "Username",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          // Optional: Show username availability status
                          Obx(() => usernameController.text.trim().isNotEmpty
                              ? Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              usernameAvailable.value ? '✓ Username available' : '✗ Username already taken',
                              style: TextStyle(
                                color: usernameAvailable.value ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          )
                              : SizedBox.shrink()
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Email is required";
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
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
                      SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password is required";
                          if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
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
                          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                isChecked = val ?? false;
                              });
                            },
                            fillColor: MaterialStateProperty.all(primaryColor),
                            checkColor: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "By continuing you accept our Privacy Policy and Terms of Use",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loading ? null : signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                          shadowColor: secondaryColor.withOpacity(0.4),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                        ),
                        child: loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Register", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "-------------------------or-------------------------",
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      SizedBox(height: 20),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}