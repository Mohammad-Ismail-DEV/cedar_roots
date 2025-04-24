import 'package:cedar_roots/components/nav_bar.dart';
import 'package:cedar_roots/screens/verification.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:flutter/foundation.dart'; // For Platform checks
import 'package:cedar_roots/screens/login.dart';
import 'package:cedar_roots/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for the new fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Registration logic for email, first name, last name, phone number, and password
  Future<void> _register(BuildContext context) async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    final passwordRegex = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,16}$",
    );

    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      _showError("Please fill in all the fields.");
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      _showError("Please enter a valid email address.");
      return;
    }

    if (!passwordRegex.hasMatch(password)) {
      _showError(
        "Password must be 8-16 characters, include uppercase, lowercase, number, and symbol.",
      );
      return;
    }

    try {
      final response = await ApiService().register(name, email, password);

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(email: email),
          ),
        );
      } else {
        print('Registration failed: ${response.statusCode}');
        _showError('Registration failed. Please try again.');
      }
    } catch (e) {
      print('Error during registration: $e');
      _showError('An error occurred. Please try again later.');
    }
  }

  // Google Sign-Up function
  Future<void> _googleSignUp(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Save user data to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('is_logged_in', true);
        prefs.setString('username', googleUser.displayName ?? "Google User");

        // Navigate to home screen after successful sign-up
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavBar()),
        );
      }
    } catch (error) {
      print("Google sign-up failed: $error");
    }
  }

  // Apple Sign-Up function
  // Future<void> _appleSignUp(BuildContext context) async {
  //   try {
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     // Save user data to shared preferences
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     prefs.setBool('is_logged_in', true);
  //     prefs.setString('username', credential.givenName ?? "Apple User");

  //     // Navigate to home screen after successful sign-up
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => NavBar()),
  //     );
  //   } catch (error) {
  //     print("Apple sign-up failed: $error");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => NavBar()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            // Full Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            // Register button
            ElevatedButton(
              onPressed: () => _register(context),
              child: Text('Sign Up'),
            ),
            SizedBox(height: 20),
            // Google Sign-Up button (for all devices)
            ElevatedButton(
              onPressed: () => _googleSignUp(context),
              child: Text('Sign Up with Google'),
            ),
            SizedBox(height: 20),
            // Apple Sign-Up button only on Apple devices (iOS/macOS)
            // if (defaultTargetPlatform == TargetPlatform.iOS ||
            //     defaultTargetPlatform == TargetPlatform.macOS)
            //   ElevatedButton(
            //     onPressed: () => _appleSignUp(context),
            //     child: Text('Sign Up with Apple'),
            //   ),
            SizedBox(height: 20),
            // If user already has an account, navigate to LoginScreen
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ), // Navigate to LoginScreen
                );
              },
              child: Text('Already have an account? Login here'),
            ),
          ],
        ),
      ),
    );
  }
}
