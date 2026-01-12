/* Apply body/texture as saturation boost + swirling movement */

import { hsvToRgb } from "./colorUtils.js";

/**
 * Draw body/structure effect:
 * 1. Saturation/darkness boost - intensifies the base color
 * 2. Swirling patterns - flowing curves suggesting liquid movement
 *
 * @param {CanvasRenderingContext2D} ctx
 * @param {number} centerX
 * @param {number} centerY
 * @param {number} maxRadius
 * @param {number} width
 * @param {number} height
 * @param {object} baseColor - HSV base color
 * @param {number} body - 0-1 body/structure value
 */
export function applyBody(ctx, centerX, centerY, maxRadius, width, height, baseColor, body) {
  if (body <= 0.1) return;

  // === 1. SATURATION/DARKNESS BOOST ===
  // Fuller wines = more saturated, deeper color
  const satBoost = body * 0.25; // Up to 25% saturation increase
  const darkBoost = body * 0.15; // Up to 15% darker

  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const dx = x - centerX;
      const dy = y - centerY;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist > maxRadius) continue;

      const idx = (y * width + x) * 4;
      const r = data[idx];
      const g = data[idx + 1];
      const b = data[idx + 2];

      // Convert to HSV-ish adjustment (simplified)
      // Increase saturation by pushing colors away from gray
      const gray = (r + g + b) / 3;
      const satFactor = 1 + satBoost;
      const darkFactor = 1 - darkBoost;

      data[idx] = Math.max(0, Math.min(255, (gray + (r - gray) * satFactor) * darkFactor));
      data[idx + 1] = Math.max(0, Math.min(255, (gray + (g - gray) * satFactor) * darkFactor));
      data[idx + 2] = Math.max(0, Math.min(255, (gray + (b - gray) * satFactor) * darkFactor));
    }
  }

  ctx.putImageData(imageData, 0, 0);

  // === 2. SWIRLING PATTERNS ===
  // Draw flowing curves suggesting liquid movement
  const numSwirls = Math.floor(3 + body * 2); // 3-5 swirl arms
  const swirlOpacity = 0.04 + body * 0.09; // 0.04-0.13 opacity (balanced)
  const swirlWidth = 27 + body * 35; // 27-62px wide swirls

  ctx.globalCompositeOperation = "soft-light";

  for (let i = 0; i < numSwirls; i++) {
    const startAngle = (i / numSwirls) * Math.PI * 2;
    const rotations = 0.8 + body * 0.7; // More rotations for fuller wines

    ctx.beginPath();

    // Draw spiral from center outward
    for (let t = 0; t <= 1; t += 0.01) {
      const angle = startAngle + t * Math.PI * 2 * rotations;
      const radius = t * maxRadius * 0.9;

      const px = centerX + Math.cos(angle) * radius;
      const py = centerY + Math.sin(angle) * radius;

      if (t === 0) {
        ctx.moveTo(px, py);
      } else {
        ctx.lineTo(px, py);
      }
    }

    // Create gradient along the swirl
    const gradient = ctx.createRadialGradient(
      centerX, centerY, 0,
      centerX, centerY, maxRadius
    );

    // Alternating light/dark swirls
    if (i % 2 === 0) {
      gradient.addColorStop(0, `rgba(255, 255, 255, 0)`);
      gradient.addColorStop(0.3, `rgba(255, 255, 255, ${swirlOpacity})`);
      gradient.addColorStop(0.7, `rgba(255, 255, 255, ${swirlOpacity * 0.5})`);
      gradient.addColorStop(1, `rgba(255, 255, 255, 0)`);
    } else {
      gradient.addColorStop(0, `rgba(0, 0, 0, 0)`);
      gradient.addColorStop(0.3, `rgba(0, 0, 0, ${swirlOpacity})`);
      gradient.addColorStop(0.7, `rgba(0, 0, 0, ${swirlOpacity * 0.5})`);
      gradient.addColorStop(1, `rgba(0, 0, 0, 0)`);
    }

    ctx.strokeStyle = gradient;
    ctx.lineWidth = swirlWidth;
    ctx.lineCap = "round";
    ctx.stroke();
  }

  ctx.globalCompositeOperation = "source-over";
}
