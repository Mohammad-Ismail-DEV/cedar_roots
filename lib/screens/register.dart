import 'package:cedar_roots/components/nav_bar.dart';
import 'package:cedar_roots/screens/verification.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart'; // For Platform checks
import 'package:cedar_roots/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for the new fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Registration logic for email, first name, last name, phone number, and password
  Future<void> _register(BuildContext context) async {
    final email = _emailController.text;
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        phone.isNotEmpty &&
        password.isNotEmpty) {
      // Save user data to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('is_logged_in', true);
      prefs.setString('email', email);
      prefs.setString('first_name', firstName);
      prefs.setString('last_name', lastName);
      prefs.setString('phone', phone);

      // Navigate to verification screen after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  VerificationScreen(phoneNumber: _phoneController.text),
        ), // Navigate to VerificationScreen
      );
    } else {
      print("Please fill in all the fields.");
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
  Future<void> _appleSignUp(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Save user data to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('is_logged_in', true);
      prefs.setString('username', credential.givenName ?? "Apple User");

      // Navigate to home screen after successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavBar()),
      );
    } catch (error) {
      print("Apple sign-up failed: $error");
    }
  }

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
            // First Name field
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            // Last Name field
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            // Phone Number field
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
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
            if (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
              ElevatedButton(
                onPressed: () => _appleSignUp(context),
                child: Text('Sign Up with Apple'),
              ),
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
