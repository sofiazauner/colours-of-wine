/* messages shown in the snackbars*/

import 'package:flutter/material.dart';
import 'package:colours_of_wine/utils/app_constants.dart';


class SnackbarMessages {

  // loging in /out
  static const String signin = 
    "Failed to sign in - Please try again!";
  static const String signout = 
    "Failed to sign out - Please try again!";

  // label analysis
  static const String analysisFailed =
    "Something went wrong while analyzing your wine label - Please try again!";
  static const String picMissing = 
    "Please upload both label photos!";

  // summary
  static const String summaryFailed =
    "An error occurred while generating the summary - Please try again!";

  // descriptions
  static const String descriptionFailed =
    "An error occurred while retrieving wine descriptions - Please try again!";
  static const String missingGrapeVariety =
    "Grape Variety is mandatory! Please make sure it gets registered and try again!";

  // history
  static const String historyFailed =
    "An error occurred while retrieving your previous searches - Please try again!";
  static const String deleteFailed =
    "Failed to delete entry - Please try again!";
  static const String deleteSuccess =
    "Entry was successfully deleted!";

  // generic
  static const String unknownError =
    "An unexpected error occurred - Please try again!";

  static showErrorBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
          style: TextStyle(color: AppConstants.infoTextColour),
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        duration: AppConstants.defaultSnackBarDuration,
        backgroundColor: AppConstants.informationOrange,
        margin: EdgeInsets.only(
          bottom: 500,
          left: 50,
          right: 50,
        ),
      ),
    );
  }
}
