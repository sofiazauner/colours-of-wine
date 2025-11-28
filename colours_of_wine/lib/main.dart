/* entry point of the app; initializes firebase and launches the WineApp UI */

import 'package:colours_of_wine/utils/app_constants.dart';
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
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppConstants.bgColour,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.schemeColour),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),
      ),
      home: const InitPage(),                          // start screen
    );
  }
}