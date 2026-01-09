/* app logo widget to display the app logo image */

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? height;
  
  const AppLogo({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();             // fallback if logo is not found
      },
    );
  }
}
