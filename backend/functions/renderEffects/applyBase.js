/* Apply base wine color gradient */

import { hsvToRgb } from "./colorUtils.js";

/**
 * Draw the base wine color with fade-out to transparent at edges
 */
export function applyBase(ctx, centerX, centerY, maxRadius, baseColor) {
  const baseRgb = hsvToRgb(baseColor.h, baseColor.s, baseColor.v);
  const lighterRgb = hsvToRgb(
    baseColor.h,
    baseColor.s * 0.9,
    Math.min(baseColor.v + 0.05, 1),
  );

  const baseGradient = ctx.createRadialGradient(
    centerX,
    centerY,
    0,
    centerX,
    centerY,
    maxRadius,
  );

  // Lighter center -> full color -> smooth fade out to transparent
  baseGradient.addColorStop(
    0,
    `rgba(${lighterRgb.r}, ${lighterRgb.g}, ${lighterRgb.b}, 0.9)`,
  );
  baseGradient.addColorStop(
    0.3,
    `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 1)`,
  );
  baseGradient.addColorStop(
    0.6,
    `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 1)`,
  );
  baseGradient.addColorStop(
    0.85,
    `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0.95)`,
  );
  baseGradient.addColorStop(
    1,
    `rgba(${baseRgb.r}, ${baseRgb.g}, ${baseRgb.b}, 0)`,
  );

  ctx.beginPath();
  ctx.arc(centerX, centerY, maxRadius, 0, Math.PI * 2);
  ctx.fillStyle = baseGradient;
  ctx.fill();
}
