/* Apply vignette effect to indicate barrel material */

import { hsvToRgb } from "./colorUtils.js";

/**
 * Draw a vignette effect from the edges to indicate barrel material
 * - Oak barrel: brown tones (woody)
 * - Stainless steel barrel: blue-gray tones (metallic)
 * - None: no effect
 *
 * @param {string} barrelMaterial - "oak", "stainless", or "none"
 * @param {number} barrelIntensity - Intensity of the vignette effect (0-1)
 */
export function applyBarrel(ctx, centerX, centerY, width, height, barrelMaterial, barrelIntensity) {
  if (barrelMaterial === "none") return;

  barrelIntensity = Math.max(0 , Math.min(1, barrelIntensity));

  // Determine color based on barrel material
  let h, s, v;
  if (barrelMaterial === "oak") {
    h = 20;                                 // brown-town
    s = 0.35 + barrelIntensity * 0.65;      // more intense  = more color
    v = 0.45 - barrelIntensity * 0.25;      // more intense  = darker
  } else if (barrelMaterial === "stainless") {
    h = 210;                                // blue-gray
    s = 0.25 + barrelIntensity * 0.17;      // more intense  = more grey
    v = 0.70 - barrelIntensity * 0.15;      // more intense  = darker
  } else {
    return;
  }
  const { r, g, b } = hsvToRgb(h, s, v);

  // Maximum distance from center to corners
  const corners = [
    [0, 0],
    [width - 1, 0],
    [0, height - 1],
    [width - 1, height - 1],
  ];
  let maxDist = 1;
  for (const [cx, cy] of corners) {
    const dx = cx - centerX;
    const dy = cy - centerY;
    maxDist = Math.max(maxDist, Math.hypot(dx, dy));
  }

  // Gradient Borders
  // Inner radius = where vignette starts; Outer radius = where vignette ends
  const innerRadius = maxDist * (0.45 - barrelIntensity * 0.15); // bigger intensity = starts earlier
  const outerRadius = maxDist * 1.02;                            // outside of canvas, to get full strength at edges

  const vignette = ctx.createRadialGradient(centerX, centerY, innerRadius, centerX, centerY, outerRadius);

  // Define gradient color stops; adjust to move vignette strength
  const edgeAlpha = 0.35 + barrelIntensity * 0.55;
  vignette.addColorStop(0.00, `rgba(${r},${g},${b},0.00)`);
  vignette.addColorStop(0.45, `rgba(${r},${g},${b},0.00)`);
  vignette.addColorStop(0.65, `rgba(${r},${g},${b},${edgeAlpha * 0.52})`);
  vignette.addColorStop(0.90, `rgba(${r},${g},${b},${edgeAlpha * 0.82})`);
  vignette.addColorStop(1.00, `rgba(${r},${g},${b},${edgeAlpha})`);

  // Apply vignette with blending
  ctx.save();
  ctx.globalCompositeOperation = "multiply";
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, width, height);
  ctx.restore();

  // Subtle soft-light overlay to enhance effect
  ctx.save();
  ctx.globalCompositeOperation = "soft-light";
  ctx.globalAlpha = 0.35 + barrelIntensity * 0.25;
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, width, height);
  ctx.restore();
}