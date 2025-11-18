/* image generation */

import { createCanvas } from "canvas";
import { convert } from "@asamuzakjp/css-color";
import { ai, GeminiModel } from "./config.js";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";

const CSSColors = [
  "aliceblue", "aqua", "aquamarine", "azure", "beige", "black",
  "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "chartreuse",
  "chocolate", "coral", "cornflowerblue", "cornsilk", "cyan", "darkblue",
  "darkcyan", "darkgoldenrod", "darkgreen", "darkkhaki", "darkmagenta",
  "darkolivegreen", "darkorange", "darkred", "darksalmon", "darkseagreen",
  "darkslategray", "darkturquoise", "darkviolet", "deeppink", "deepskyblue",
  "dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite",
  "forestgreen", "fuchsia", "ghostwhite", "gold", "goldenrod", "gray",
  "green", "greenyellow", "grey", "hotpink", "indianred", "indigo",
  "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lightblue",
  "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgreen",
  "lightgrey", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue",
  "lightslategray", "lightslategrey", "lightsteelblue", "lightyellow",
  "lime", "limegreen", "linen", "magenta", "mediumblue", "mediumorchid",
  "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen",
  "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream",
  "mistyrose", "navy", "oldlace", "olive", "olivedrab", "orange", "orangered",
  "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred",
  "papayawhip", "peachpuff", "pink", "plum", "purple", "rebeccapurple", "red",
  "rosybrown", "royalblue", "salmon", "sandybrown", "seagreen", "seashell",
  "sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow",
  "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise",
  "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen"
];

const WineComponents = [
  "Holzeinsatz",
  "Mousseux",
  "Säure",
  "Fruchtcharacter",
  "Nicht-Frucht-Komponenten",
  "Körper",
  "Tannin",
  "Reifearomen",
];

const ColorSchema = (function() {
  const obj = {};
  const colors = z.enum(CSSColors)
  for (const it of WineComponents)
    obj[it] = colors;
  return zodToJsonSchema(z.object(obj))
})();

// use Gemini to generate image colors from summary
export async function generateImageColors(wineSummary) {
  /* 
   * Get an array of image colors.
   * TODO:
   * * do this in the same step as the summary (so we have a single feedback loop)
   * * generate sidebars (I think Anja asked for Mineralik/Süße)
   * I guess we can experiment with RGB too when all that's done, or possibly
   * just do something like a manual feedback loop where we parse the color
   * ourselves?
   */
  const prompt = `
Du bist ein Wein- und Farbassoziationsexperte.
Ich gebe dir eine Weinbeschreibung und du gibst eine Liste von ENGLISCHEN CSS-Farben im folgenden JSON-FORMAT zurück:

{
  "Holzeinsatz": "FARBE FÜR HOLZEINSATZ/AUSBAUSTIL",
  "Mousseux": "FARBE FÜR MOUSSEUX",
  "Säure": "FARBE FÜR SÄURE",
  "Fruchtcharacter": "FARBE FÜR FRUCHTCHARACTER",
  "Nicht-Frucht-Komponenten": "FARBE FÜR NICHT-FRUCHT-KOMPONENTEN",
  "Körper": "FARBE FÜR KÖRPER/BALANCE",
  "Tannin": "FARBE FÜR TANNIN",
  "Reifearomen": "FARBE FÜR REIFEAROMEN"
}

Die Weinbeschreibung = ${wineSummary}`;

  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: ColorSchema,
    }
  });
  return JSON.parse(response.text);
}


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
