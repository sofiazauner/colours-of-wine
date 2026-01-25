/* login logic */

import 'package:colours_of_wine/utils/app_constants.dart';
import 'package:colours_of_wine/utils/snackbar_messages.dart';
import 'package:colours_of_wine/screens/home_screen.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';                           // for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';                  // for authentification (Google Sign-In)
import 'package:google_sign_in/google_sign_in.dart';

// init screen - decide if we need login or not
class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildInitView(),
        ),
      ),
    );
  }

  Widget _buildInitView() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        if (!snapshot.hasData) {                   // needs sign in
          return const LoginPage();
        }

        final user = snapshot.data!;               // signed in
        return const HomeScreen();                 // show new frontend after login
      },
    );
  }
}


// login screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColorLogin,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLoginView(),
        ),
      ),
    );
  }

  // UI (Google Sign-In)
  Widget _buildLoginView() {
   return Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      const Text(
        'Colours of Wine',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      const Text(
        'A new way to experience Wine',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 12),
       Image.asset('assets/logo.png',
         height: 300,
         fit: BoxFit.contain,
       ),
       const SizedBox(height: 15),
       ElevatedButton.icon(
         icon: const Icon(Icons.login),
         label: const Text(AppConstants.signInButton),
         onPressed: _signInWithGoogle,
         style: ElevatedButton.styleFrom(
           backgroundColor: AppConstants.signInButtonColor,
           foregroundColor: AppConstants.signInButtonTextColor,
         ),
       ),
     ],
   );
}

  Future<Widget> _signInWithGoogle() async {
    final user = await _signInWithGoogleImpl();
    if (user == null) {
      SnackbarMessages.show(context, AppLocalizations.of(context)!.signinFailed);
    }
    return InitPage();
  }

  Future<UserCredential?> _signInWithGoogleImpl() async {
    if (kIsWeb) {                                             
      // create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser!.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }
}
