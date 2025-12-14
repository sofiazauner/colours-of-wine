/* constant values used in the code */

import 'package:flutter/material.dart';


class AppConstants {
  // basic app layout
  static const String appTitle = "Discover your wine";
  static const String signInText = "Sign in to start";
  static const Color bgColour = Color.fromRGBO(237, 237, 213, 1);
  static const Color schemeColour = Color.fromARGB(225, 237, 237, 213);
  static const Color urlColour = Colors.blue;
  static const Color userEmailColour = Color.fromRGBO(255, 255, 255, 0);


  // ui strings
  static const String confirmPhotosTitle = "Confirm Photos";
  static const String uploadTitel = "Upload Photos of Label";
  static const String succFrontLabel = "✅ Front Label";
  static const String succBackLabel = "✅ Back Label";
  static const String conftimFrontTitle = "Front Label";
  static const String conftimBackTitle = "Back Label";
  static const String manualTitle = "Enter wine details";


  // ui buttons
  static const String closeButton = "Close";
  static const String saveButton = "Save";
  static const String confirmButton = "Confirm";
  static const String cancelButton = "Cancel";

  static const String signInButton = "Sign in with Google";
  static const String signOutButton = "Sign out";

  static const String startScanButton = "Scan label";
  static const String uploadFrontLabelButton = "Upload Front Label";
  static const String uploadBackLabelButton = "Upload Back Label";
  static const String retakePicButton = "Retake Photos";
  static const String analysisButton = "Analyze Label";
  static const String startManualButton = "Fill data in manually";

  static const String getDescrButton = "Get Wine Descriptions";
  static const String tryAgainButton = "Try Again";

  static const String generateSumAndImageButton = "Generate Summary + Image";

  static const String startHistoryButton = "Previous searches";
  static const String searchInHistoryButton = "Search";
  static const String resetSearch = "Reset Search";

  static const String settingsButton = "Settings";

  // settings view
  static const String settingsTitle = "Settings";
  static const String defaultDescriptionSelectionText = "Default number of descriptions selected:";


  // description view
  static const String descriptionTitle = "Wine Descriptions   ||";
  static const String noDescriptionsText = "No descriptions found.";
  static const String selectDescriptionsText = "Select up to 7 descriptions to be used for the summary.";
  static const String addDescriptionText = "Add Description";
  static const String chooseFileText = "Choose file";
  static const String loadFromUrlText = "Load from URL";
  static const int defaultSelectedDescriptionsCount = 3;
  static const int maximumDescriptionsForSummary = 7;


  // history view
  static const Color redEmoji = Color.fromARGB(255, 113, 9, 9);
  static const Color deleteButtonColor = Color.fromARGB(255, 111, 101, 25);
  static const Color dateColor = Color.fromARGB(255, 71, 69, 69);
  static const Color fillColor = Color.fromARGB(255, 249, 246, 233);
  static const Color borderColor = Color.fromARGB(255, 236, 111, 111);
  static const String descripTitle = "Descriptions: ";
  static const String emptyDescr = "No descriptions saved.";
  static const String historyTitle = "Previous Searches:";
  static const String searchHintText = "Search for a wine name";
  static const String emptySearch = "No entries found.";


  // result view
  static const Color resultTextCol = Color.fromARGB(255, 0, 0, 0);
  static const Color resultTitleCol = Color.fromRGBO(66, 66, 66, 1);
  static const String wineCradTitle = "Registered Information:";
  static const String summarySucc = "AI Summary:";
  static const String summaryFail = "There was an issue with the summary - Please try again!";


  // snackbar + showing informations
  static const Duration defaultSnackBarDuration = Duration(seconds: 5);
  static const Color errorRed = Color.fromARGB(255, 210, 8, 8);
  static const Color informationOrange = Color.fromARGB(255, 184, 114, 17);
  static const Color successGreen = Colors.green;
  static const Color infoTextColour = Color.fromARGB(255, 255, 255, 251);
}
