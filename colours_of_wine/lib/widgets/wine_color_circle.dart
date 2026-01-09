/* widget for wine color circle */

import 'package:flutter/material.dart';
import 'package:colours_of_wine/utils/app_constants.dart';

class WineColorCircle extends StatelessWidget {
  final String? colorHex;
  final String colorDescription;

  const WineColorCircle({
    super.key,
    this.colorHex,
    required this.colorDescription,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        final hexCode = colorHex!.replaceAll('#', '');
        circleColor = Color(int.parse('FF$hexCode', radix: 16));
      } catch (e) {
        circleColor = _getDefaultColor();
      }
    } else {
      circleColor = _getDefaultColor();
    }

    return Container(
      width: AppConstants.wineCircleSize,
      height: AppConstants.wineCircleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        border: Border.all(
          color: AppConstants.circleBorderColor,
          width: AppConstants.wineCircleBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.circleShadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Color _getDefaultColor() {
    // default wine color if hex is not available
    return AppConstants.defaultCircleColor;
  }
}
