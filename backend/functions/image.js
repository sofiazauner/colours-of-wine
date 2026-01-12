/* Wine visualization image generation */

import { createCanvas } from "canvas";
import {
  hsvToHex,
  WineTypeBaseColors,
  applyBase,
  applyNotes,
  applyAcidity,
  applyDepth,
  applySugar,
} from "./renderEffects/index.js";

/**
 * Determine acidity/depth intensity based on wine type
 * - Reds/fortified: depth is more important
 * - Whites/sparkling: acidity is more important
 */
function getEffectIntensities(wineType) {
  switch (wineType) {
    case "red":
    case "fortified":
      return { acidityIntensity: 0.3, depthIntensity: 1.0 };
    case "white":
    case "sparkling":
      return { acidityIntensity: 1.0, depthIntensity: 0.3 };
    case "rose":
    case "orange":
      return { acidityIntensity: 0.7, depthIntensity: 0.5 };
    case "dessert":
      return { acidityIntensity: 0.5, depthIntensity: 0.8 };
    default:
      return { acidityIntensity: 0.5, depthIntensity: 0.5 };
  }
}

/** Generate an image from wine visualization data */
export async function generateImage(data) {
  const {
    wineType,
    baseColor: geminiBaseColor,
    acidity,
    residualSugar,
    depth,
    fruitNotes,
    nonFruitNotes,
  } = data;

  // Canvas setup
  const width = 300;
  const height = 300;
  const centerX = width / 2;
  const centerY = height / 2;
  const maxRadius = 130;
  const coreRadius = 35;

  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext("2d");

  // Get base color - use Gemini's color if provided, otherwise fall back to predefined
  const baseColor = geminiBaseColor || WineTypeBaseColors[wineType] || WineTypeBaseColors.red;

  // Fill background with very light tint of base color
  ctx.fillStyle = hsvToHex(baseColor.h, baseColor.s * 0.08, 0.98);
  ctx.fillRect(0, 0, width, height);

  // === RENDER PIPELINE ===

  // 1. Base wine color gradient
  applyBase(ctx, centerX, centerY, maxRadius, baseColor);

  // 2. Tasting note overlays
  applyNotes(ctx, centerX, centerY, maxRadius, coreRadius, fruitNotes, nonFruitNotes);

  // 3. Acidity and Depth (intensity based on wine type)
  const { acidityIntensity, depthIntensity } = getEffectIntensities(wineType);
  const coreRadiusInner = coreRadius * 0.8;

  applyAcidity(ctx, centerX, centerY, coreRadiusInner, baseColor, acidity, acidityIntensity);
  applyDepth(ctx, centerX, centerY, coreRadius, depth, depthIntensity);

  // 4. Sugar indicator (golden glow at bottom)
  applySugar(ctx, centerX, centerY, maxRadius, width, height, residualSugar);

  return canvas.toBuffer("image/png");
}
