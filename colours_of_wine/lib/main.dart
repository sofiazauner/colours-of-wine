/* entry point of the app; initializes firebase and launches the WineApp UI */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:colours_of_wine/config/firebase_options.dart';
import 'package:colours_of_wine/features/login.dart';


// runs app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WineApp());
}


// root widget (stateless)
class WineApp extends StatelessWidget {
  const WineApp({super.key});                          // for widget identification

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colours of Wine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromRGBO(237, 237, 213, 1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(225, 237, 237, 213)),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),
      ),
      home: const InitPage(),                          // start screen
    );
  }
}