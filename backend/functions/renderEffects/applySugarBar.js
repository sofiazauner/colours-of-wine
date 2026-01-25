/* Apply residual sugar bar indicator on the right side */

/**
 * Draw a vertical bar on the right side showing residual sugar level
 * Only shown when residualSugarKnown is true
 * Fills logarithmically from bottom to top with #FF69B4 (hot pink)
 *
 * @param {number} residualSugar - Sugar level 0-100 (g/L)
 * @param {boolean} residualSugarKnown - Whether the value is known/reliable
 */
export function applySugarBar(ctx, width, height, residualSugar, residualSugarKnown) {
  //if (!residualSugarKnown) return;

  const barWidth = 30;
  const barX = width - barWidth;

  // Background for the bar (subtle dark)
  ctx.fillStyle = "rgba(0, 0, 0, 0.15)";
  ctx.fillRect(barX, 0, barWidth, height);

  // Logarithmic fill: log scale makes low values more visible
  // Max is 500 g/L, using log(1 + x) to handle 0
  const normalizedSugar = Math.max(0, Math.min(500, residualSugar));
  const logFill = Math.log(1 + normalizedSugar) / Math.log(501);

  const fillHeight = height * logFill;
  const fillY = height - fillHeight;

  // Gradient from bottom (more saturated) to top (lighter)
  const gradient = ctx.createLinearGradient(barX, height, barX, fillY);
  gradient.addColorStop(0, "rgba(255, 105, 180, 0.9)"); // #FF69B4 at bottom
  gradient.addColorStop(0.5, "rgba(255, 105, 180, 0.7)");
  gradient.addColorStop(1, "rgba(255, 140, 200, 0.5)"); // lighter at top

  ctx.fillStyle = gradient;
  ctx.fillRect(barX, fillY, barWidth, fillHeight);

  // Subtle border
  ctx.strokeStyle = "rgba(255, 105, 180, 0.4)";
  ctx.lineWidth = 1;
  ctx.strokeRect(barX, 0, barWidth, height);

  // Text label rotated 90° (bottom to top)
  const label = `${Math.round(normalizedSugar)} RZ`;
  ctx.save();
  ctx.translate(barX + barWidth / 2, height - 8);
  ctx.rotate(-Math.PI / 2);
  ctx.font = "bold 12px sans-serif";
  ctx.textAlign = "left";
  ctx.textBaseline = "middle";
  ctx.fillStyle = "rgba(255, 255, 255, 0.9)";
  ctx.fillText(label, 0, 0);
  ctx.restore();
}
