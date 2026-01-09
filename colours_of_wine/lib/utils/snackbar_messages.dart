/* utility class for showing snackbars */

import 'package:flutter/material.dart';
import 'package:colours_of_wine/utils/app_constants.dart';

class SnackbarMessages {
  /// show a snackbar with the given text
  static void show(BuildContext context, String text, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: duration ?? AppConstants.defaultSnackBarDuration,
      ),
    );
  }

  /// hide the currently shown snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}