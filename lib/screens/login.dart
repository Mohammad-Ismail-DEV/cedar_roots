import 'package:cedar_roots/components/nav_bar.dart';
import 'package:cedar_roots/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart'; // For Platform checks

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "344338108473-q33tljdv7berb5qqlv417rm9fdjji1gg.apps.googleusercontent.com",
    scopes: ['email'],
  );

  // Simulate a login function
  Future<void> _login(BuildContext context) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      // Save user data to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('is_logged_in', true);
      prefs.setString('username', username);

      // Navigate to the home screen after successful login
      // Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavBar()),
      );
    } else {
      AlertDialog(content: const Text("Please enter valid credentials."));
    }
  }

  // Google login function
  Future<void> _googleLogin(BuildContext context) async {
    try {
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      user ??= await _googleSignIn.signIn(); // If not signed in, prompt login

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('is_logged_in', true);
        prefs.setString('username', user.displayName ?? "Google User");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavBar()),
        );
      }
    } catch (error) {
      print("Google login failed: $error");
    }
  }

  // Apple login function
  Future<void> _appleLogin(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('is_logged_in', true);
      prefs.setString('username', credential.givenName ?? "Apple User");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavBar()),
      );
    } catch (error) {
      print("Apple login failed: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
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
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Log In'),
            ),
            SizedBox(height: 20),
            // Google login button
            ElevatedButton(
              onPressed: () => _googleLogin(context),
              child: Text('Login with Google'),
            ),
            SizedBox(height: 20),
            // Apple login button
            // Show Apple Sign-Up button only on Apple devices (iOS/macOS)
            if (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
              ElevatedButton(
                onPressed: () => _appleLogin(context),
                child: Text('Sign Up with Apple'),
              ),
            SizedBox(height: 20),
            // Registration button (Navigate to register screen)
            TextButton(
              onPressed: () {
                // Navigate to register screen (You need to create RegisterScreen)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            RegisterScreen(), // Replace with your register screen
                  ),
                );
              },
              child: Text('Don’t have an account? Register here'),
            ),
          ],
        ),
      ),
    );
  }
}
