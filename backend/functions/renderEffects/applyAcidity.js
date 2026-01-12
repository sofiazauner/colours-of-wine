/* Apply acidity tint in the center */

import { hsvToHex, blendHSV, AcidityColor } from "./colorUtils.js";

/**
 * Draw acidity as a greenish tint in the center
 * @param {number} intensity - How prominent the acidity effect should be (0-1)
 */
export function applyAcidity(ctx, centerX, centerY, radius, baseColor, acidity, intensity) {
  if (acidity <= 0.1 || intensity <= 0) return;

  const effectiveAcidity = acidity * intensity;
  const acidityBlend = blendHSV(baseColor, AcidityColor, effectiveAcidity * 0.4);

  const acidGradient = ctx.createRadialGradient(
    centerX, centerY, 0,
    centerX, centerY, radius
  );

  acidGradient.addColorStop(
    0,
    hsvToHex(acidityBlend.h, acidityBlend.s, Math.min(acidityBlend.v + 0.1, 1))
  );
  acidGradient.addColorStop(
    0.6,
    hsvToHex(acidityBlend.h, acidityBlend.s * 0.9, acidityBlend.v)
  );
  acidGradient.addColorStop(
    1,
    hsvToHex(baseColor.h, baseColor.s, baseColor.v)
  );

  ctx.beginPath();
  ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
  ctx.fillStyle = acidGradient;
  ctx.fill();
}
