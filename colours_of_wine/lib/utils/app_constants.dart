/* constant values used in the code */

import 'package:flutter/material.dart';

class AppConstants {
  // authentication
  static const String signInButton = "Continue with Google";
  static const Color signInButtonColor = Color.fromRGBO(134, 24, 33, 0.875);
  static const Color signInButtonTextColor = Colors.white;
  static const Color bgColorLogin = Color.fromRGBO(237, 235, 228, 1.0);

  // descriptions
  static const int defaultSelectedDescriptionsCount = 3;
  static const int maximumDescriptionsForSummary = 20;

  // document icon
  static const Color docIconFallbackColor = Colors.black87;
  static const Color docIconFillColor = Colors.white;
  static const double docIconStrokeWidth = 1.5;
  static const double docIconSize = 24.0;

  // residual sugar chart
  static const double restzuckerChartWidth = 200.0;
  static const double restzuckerChartMaxHeight = 200.0;
  static const Color restzuckerBarColor = Color(0xFFFF1493);
  static const Color restzuckerBgColor = Color(0xFFFFE6F0);

  // circle 
  static const Color defaultCircleColor = Color(0xFF8B2635);
  static const Color circleShadowColor = Colors.black;
  static const Color circleBorderColor = Colors.grey;
  static const double wineCircleSize = 100.0;
  static const double wineCircleBorderWidth = 3.0;

  // snackbar
  static const Duration defaultSnackBarDuration = Duration(seconds: 5);
  static const Color informationOrange = Color.fromARGB(255, 184, 114, 17);
  static const Color infoTextColour = Color.fromARGB(255, 255, 255, 251);

  // HTTP timeouts
  static const Duration httpTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // UI spacing
  static const double dialogBorderRadius = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double dialogPadding = 24.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 24.0;

  // image/photo
  static const double photoFieldHeight = 350.0;
  static const double photoFieldWidth = 200.0;
  static const int imageQuality = 85;
  static const double maxImageWidth = 1024.0;
  static const double maxImageHeight = 1024.0;

  // colors
  static const Color emptyFieldHighlight = Color.fromARGB(255, 249, 120, 252);

  // theme colors
  static const Color themeSeedColor = Color(0xFF616161);
  static final Color themeScaffoldBg = Colors.grey.shade50;
  static final Color themeCardColor = Colors.grey.shade100;
  static final Color themeAppBarBg = Colors.grey.shade100;
  static final Color themeAppBarFg = Colors.grey.shade900;
  static const int themeCardElevation = 2;
  static const int themeAppBarElevation = 0;  

  // sharedpreferences Keys
  static const String defaultDescriptionCountKey = 'default_description_count';
  static const String appLanguageKey = 'app_language';

  // wine year validation
  static const int minWineYear = 1900;
  static const int maxWineYear = 2100;
}
