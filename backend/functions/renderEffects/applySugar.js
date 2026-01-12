/* Apply sugar indicator as pink glow */

/**
 * Draw sugar as a pink glow at the bottom of the image
 * Color: #FF69B4 (hot pink)
 */
export function applySugar(ctx, centerX, centerY, maxRadius, width, height, residualSugar) {
  if (residualSugar <= 0.05) return;

  const sugarIntensity = residualSugar;
  const sugarGradient = ctx.createRadialGradient(
    centerX,
    centerY + maxRadius * 0.3,
    0,
    centerX,
    centerY + maxRadius * 0.3,
    maxRadius * sugarIntensity * 0.8
  );

  // #FF69B4 = rgb(255, 105, 180)
  sugarGradient.addColorStop(0, `rgba(255, 105, 180, ${0.3 * sugarIntensity})`);
  sugarGradient.addColorStop(0.5, `rgba(255, 105, 180, ${0.15 * sugarIntensity})`);
  sugarGradient.addColorStop(1, "rgba(255, 105, 180, 0)");

  ctx.fillStyle = sugarGradient;
  ctx.fillRect(0, 0, width, height);
}
