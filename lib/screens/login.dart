import 'package:cedar_roots/components/nav_bar.dart';
import 'package:cedar_roots/screens/register.dart';
import 'package:cedar_roots/screens/verification.dart';
import 'package:cedar_roots/services/api_service.dart';
import 'package:cedar_roots/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false; // Variable to control password visibility

  // // Google Sign-In instance
  // final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   clientId:
  //       "344338108473-q33tljdv7berb5qqlv417rm9fdjji1gg.apps.googleusercontent.com",
  //   scopes: ['email'],
  // );

  void onLoginSuccess(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    SocketService().connect(userId); // Connect to the socket
  }

  // Simulate a login function
  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Error"),
              content: Text("Please enter valid credentials."),
            ),
      );
      return;
    }

    try {
      final response = await ApiServices().login(email, password);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final user = data['user'];
        final userId = user['id'];
        final name = user['name'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('auth_token', token);
        await prefs.setString('name', name);
        await prefs.setInt('user_id', userId);

        ApiServices().setToken(token);

        SocketService().connect(userId); // Connect to socket after login

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavBar()),
        );
      } else {
        final error = json.decode(response.body)['error'] ?? 'Login failed';

        if (error.toLowerCase().contains("not verified")) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text("Email Not Verified"),
                  content: Text(
                    "Your email is not verified. Please verify to continue.",
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).pop(), // Close the dialog
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VerificationScreen(email: email),
                          ),
                        );
                      },
                      child: Text("Verify Email"),
                    ),
                  ],
                ),
          );
        } else {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text("Login Failed"),
                  content: Text(error),
                ),
          );
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Error"),
              content: Text("An error occurred: $e"),
            ),
      );
    }
  }

  // // Google login function
  // Future<void> _googleLogin(BuildContext context) async {
  //   try {
  //     GoogleSignInAccount? user = await _googleSignIn.signInSilently();
  //     user ??= await _googleSignIn.signIn(); // If not signed in, prompt login

  //     if (user != null) {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       prefs.setBool('is_logged_in', true);
  //       prefs.setString('username', user.displayName ?? "Google User");

  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => NavBar()),
  //       );
  //     }
  //   } catch (error) {
  //     print("Google login failed: $error");
  //   }
  // }

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
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible, // Toggle password visibility
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Log In'),
            ),
            // SizedBox(height: 20),
            // // Google login button
            // ElevatedButton(
            //   onPressed: () => _googleLogin(context),
            //   child: Text('Login with Google'),
            // ),
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


 // Apple login function
  // Future<void> _appleLogin(BuildContext context) async {
  //   try {
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     prefs.setBool('is_logged_in', true);
  //     prefs.setString('username', credential.givenName ?? "Apple User");

  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => NavBar()),
  //     );
  //   } catch (error) {
  //     print("Apple login failed: $error");
  //   }
  // }

  // Apple login button
            // Show Apple Sign-Up button only on Apple devices (iOS/macOS)
            // if (defaultTargetPlatform == TargetPlatform.iOS ||
            //     defaultTargetPlatform == TargetPlatform.macOS)
            //   ElevatedButton(
            //     onPressed: () => _appleLogin(context),
            //     child: Text('Sign Up with Apple'),
            //   ),
