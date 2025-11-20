/* image generation */

import { createCanvas } from "canvas";
import { convert } from "@asamuzakjp/css-color";
import { WineComponents } from "./config.js";

export async function generateImage(colors) {
  /* ref. https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
   * I know, I'm a sham, I just copied out the same code that ChatGPT is
   * copying from MDN in the background.
   */
  const canvas = createCanvas(200, 200)
  const ctx = canvas.getContext('2d')
  const gradient = ctx.createRadialGradient(100, 100, 30, 100, 100, 100);
  const len = WineComponents.length;
  for (let i = 0, len = WineComponents.length; i < len; i++) {
    const color = colors[WineComponents[i]];
    gradient.addColorStop(i / (len - 1), convert.colorToHex(color));
  }
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 200, 200);
  return canvas.toBuffer("image/jpeg");
};
