/* defines app theme with colors etc. */

import 'package:flutter/material.dart';
import 'package:colours_of_wine/utils/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.themeSeedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.themeScaffoldBg,
      cardTheme: CardThemeData(
        elevation: AppConstants.themeCardElevation.toDouble(),
        color: AppConstants.themeCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: AppConstants.themeAppBarElevation.toDouble(),
        backgroundColor: AppConstants.themeAppBarBg,
        foregroundColor: AppConstants.themeAppBarFg,
      ),
    );
  }
}
