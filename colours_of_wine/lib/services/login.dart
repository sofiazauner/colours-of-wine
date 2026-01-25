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

  // UI (Google Sign-In + Email/Password)
  Widget _buildLoginView() {
    final l10n = AppLocalizations.of(context)!;
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
          label: Text(l10n.signInWithGoogle),
          onPressed: _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.signInButtonColor,
            foregroundColor: AppConstants.signInButtonTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.email),
          label: Text(l10n.signInWithEmail),
          onPressed: () => _showEmailPasswordDialog(context),
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

  // Email/Password login popup dialog
  void _showEmailPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EmailPasswordDialog(),
    );
  }
}

class _EmailPasswordDialog extends StatefulWidget {
  @override
  State<_EmailPasswordDialog> createState() => _EmailPasswordDialogState();
}

class _EmailPasswordDialogState extends State<_EmailPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.emailPasswordLogin),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailHint,
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.emailRequired;
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  hintText: l10n.passwordHint,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.passwordRequired;
                  }
                  if (value.length < 6) {
                    return l10n.passwordTooShort;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleEmailPasswordAuth(true),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.login),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleEmailPasswordAuth(false),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.register),
        ),
      ],
    );
  }

  // email/password firebase-authentication logic
  Future<void> _handleEmailPasswordAuth(bool isLogin) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? userCredential;
      
      if (isLogin) {
        // Login
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          SnackbarMessages.show(context, l10n.loginSuccess);
        }
      } else {
        // Register
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          SnackbarMessages.show(context, l10n.registerSuccess);
        }
      }

      if (mounted && userCredential != null) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = l10n.signinFailed;
      if (e.code == 'email-already-in-use') {
        errorMessage = l10n.emailAlreadyInUse;
      } else if (e.code == 'wrong-password') {
        errorMessage = l10n.wrongPassword;
      } else if (e.code == 'user-not-found') {
        errorMessage = l10n.userNotFound;
      } else if (e.code == 'invalid-email') {
        errorMessage = l10n.invalidEmail;
      }
      
      if (mounted) {
        SnackbarMessages.show(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        SnackbarMessages.show(context, '${l10n.signinFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
