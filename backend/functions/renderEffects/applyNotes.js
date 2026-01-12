/* Apply tasting note overlays as transparent rings */

import { hsvToRgb } from "./colorUtils.js";

/**
 * Draw a single note overlay as a transparent radial ring
 */
function drawNoteOverlay(ctx, centerX, centerY, ringCenter, glowRadius, noteColor, intensity) {
  const rgb = hsvToRgb(noteColor.h, noteColor.s, noteColor.v);

  // Peak opacity based on intensity (very subtle: 0.05 to moderate: 0.25)
  const peakOpacity = 0.05 + intensity * 0.2;

  const noteGradient = ctx.createRadialGradient(
    centerX, centerY, Math.max(0, ringCenter - glowRadius),
    centerX, centerY, ringCenter + glowRadius
  );

  // Very gentle: transparent -> subtle peak -> transparent
  noteGradient.addColorStop(0, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0)`);
  noteGradient.addColorStop(0.3, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${peakOpacity * 0.3})`);
  noteGradient.addColorStop(0.45, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${peakOpacity * 0.7})`);
  noteGradient.addColorStop(0.5, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${peakOpacity})`);
  noteGradient.addColorStop(0.55, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${peakOpacity * 0.7})`);
  noteGradient.addColorStop(0.7, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${peakOpacity * 0.3})`);
  noteGradient.addColorStop(1, `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0)`);

  ctx.beginPath();
  ctx.arc(centerX, centerY, ringCenter + glowRadius, 0, Math.PI * 2);
  ctx.fillStyle = noteGradient;
  ctx.fill();
}

/**
 * Apply all tasting notes as overlays
 */
export function applyNotes(ctx, centerX, centerY, maxRadius, coreRadius, fruitNotes, nonFruitNotes) {
  const allNotes = [
    ...(fruitNotes || []).map((n) => ({ ...n, type: "fruit" })),
    ...(nonFruitNotes || []).map((n) => ({ ...n, type: "nonFruit" })),
  ];

  const numNotes = allNotes.length;
  if (numNotes === 0) return;

  const availableSpace = maxRadius - coreRadius - 15;
  const spacePerNote = availableSpace / numNotes;

  allNotes.forEach((note, i) => {
    const ringCenter = maxRadius - 15 - spacePerNote * (i + 0.5);
    const glowRadius = spacePerNote * 0.8;
    const intensity = note.intensity ?? 0.5;

    drawNoteOverlay(ctx, centerX, centerY, ringCenter, glowRadius, note.color, intensity);
  });
}
