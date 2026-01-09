/* entry point of the app; initializes firebase and launches the WineApp UI */

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:colours_of_wine/config/firebase_options.dart';
import 'package:colours_of_wine/services/login.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import 'package:colours_of_wine/providers/wine_provider.dart';
import 'package:colours_of_wine/providers/language_provider.dart';
import 'package:colours_of_wine/theme/app_theme.dart';

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
  const WineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()..loadSavedLanguage()),
        ChangeNotifierProvider(create: (_) => WineProvider()..loadInitialData()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'Colors of Wine',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de', ''),                 // german
              Locale('en', ''),                 // english
            ],
            locale: languageProvider.locale,
            home: const InitPage(),             // authentication wrapper
          );
        },
      ),
    );
  }
}