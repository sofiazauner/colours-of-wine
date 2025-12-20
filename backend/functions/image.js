/* image generation */

import { createCanvas } from "canvas";
import { convert } from "@asamuzakjp/css-color";
import { WineComponents } from "./config.js";

/** Generate an image out of info we got from Gemini. */
export async function generateImage(colors, fillLevel) {  // for testing, should be determined by LLM
  const height = 200;
  const circleSectionWidth = 210;
  const barSectionWidth = 60;

  const canvas = createCanvas(circleSectionWidth + barSectionWidth, height);
  const ctx = canvas.getContext('2d')
  // create circular gradient
  const cx = circleSectionWidth / 2;
  const cy = height / 2;
  const gradient = ctx.createRadialGradient(cx, cy, 15, cx, cy, 100);
  const len = WineComponents.length;
  for (let i = 0, len = WineComponents.length; i < len; i++) {
    const color = colors[WineComponents[i]];
    gradient.addColorStop(i / (len - 1), convert.colorToHex(color));
  }
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, circleSectionWidth, height);
  // create bar indicating sugar level
  // background
  const leftx = circleSectionWidth
  ctx.fillStyle = "#ffffffff";
  ctx.fillRect(leftx, 0, barSectionWidth, height);
  // background bar
  const padding = 18;
  const barWidth = 35;
  const barHeight = height - padding * 2;
  const filledHeight = barHeight * Math.max(0, Math.min(fillLevel, 1));     // must be between 0 and 1 (meassured in %)
  const barX = leftx + (barSectionWidth - barWidth) / 2;
  const barY = padding + (barHeight - filledHeight);
  ctx.fillStyle = "#e3e1e1ff";
  ctx.fillRect(barX, padding, barWidth, barHeight);
  // filled bar
  ctx.fillStyle = gradient;
  ctx.fillRect(barX, barY, barWidth, filledHeight);
  return canvas.toBuffer("image/jpeg");
};
