import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
import 'package:todo_app_new/UI/todolist.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Todolist()),
    );
  }

  
  Future<void> signUp() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password min 6 characters")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      goToHome();
    } on FirebaseAuthException catch (e) {
      String msg = "Signup failed";

      if (e.code == 'email-already-in-use') {
        msg = "Email already used";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email";
      } else if (e.code == 'weak-password') {
        msg = "Weak password";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => isLoading = false);
    }
  }

  
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      await googleSignIn.signOut(); // optional

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      goToHome();
    } catch (e) {
      print("GOOGLE SIGNUP ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In Failed")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  
  Widget buildTextField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? !isPasswordVisible : false,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
        ],
      ),
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Sign up Now",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      buildTextField(
                        icon: Icons.email,
                        hint: "Email",
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        icon: Icons.lock,
                        hint: "Password",
                        controller: passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 30),

                      // 🔹 Signup button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signUp,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Sign Up"),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text("OR"),

                      const SizedBox(height: 20),

                     
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              isLoading ? null : signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 30),
                          label:
                              const Text("Continue with Google"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}