/* widget for restzucker (residual sugar) chart */

import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class RestzuckerChart extends StatelessWidget {
  final double restzucker;    // in g/l
  final double? width;

  const RestzuckerChart({
    super.key,
    required this.restzucker,
    this.width,
  });

  // scale reference values from the image: 9, 10, 20, 30, 40, 50, 500 g/l
  static const List<double> scaleValues = [9, 10, 20, 30, 40, 50, 500];
  static const double maxValue = 500;

  @override
  Widget build(BuildContext context) {
    // calculate the height percentage (0-1) based on the scale
    final height = (restzucker / maxValue).clamp(0.0, 1.0);
    
    // use hot pink color (#FF1493 or similar)
    const barColor = AppConstants.restzuckerBarColor;
    final chartWidth = width ?? AppConstants.restzuckerChartWidth;
    final chartHeight = width != null ? (width! * 8) : AppConstants.restzuckerChartMaxHeight; // proportional height if width is set

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: chartWidth,
          height: chartHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // background bar (unfilled)
              Container(
                height: chartHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.restzuckerBgColor, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // filled portion
              FractionallySizedBox(
                heightFactor: height,
                child: Container(
                  width: chartWidth,
                  decoration: const BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${restzucker.toStringAsFixed(1)} g/l',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
