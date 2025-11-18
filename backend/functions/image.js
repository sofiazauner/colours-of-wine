/* image generation */

import { createCanvas } from "canvas";
import { convert } from "@asamuzakjp/css-color";
import { ai, GeminiModel } from "./config.js";


// heplers for image generation
const ImageColorMap = [
  ["Holzeinsatz", "FARBE FÜR HOLZEINSATZ/AUSBAUSTIL"],
  ["Mousseux", "FARBE FÜR MOUSSEUX"],
  ["Säure", "FARBE FÜR SÄURE"],
  ["Fruchtcharacter", "FARBE FÜR FRUCHTCHARACTER"],
  ["Nicht-Frucht-Komponenten", "FARBE FÜR NICHT-FRUCHT-KOMPONENTEN"],
  ["Körper", "FARBE FÜR KÖRPER/BALANCE"],
  ["Tannin", "FARBE FÜR TANNIN"],
  ["Reifearomen", "FARBE FÜR REIFEAROMEN"],
];
const ImageColorSchema = (function() {
  const schema = {};
  for (const [name, desc] of ImageColorMap)
    schema[name] = desc;
  return JSON.stringify(schema, null, "  ");
})();


// use Gemini to generate image colors from summary
export async function generateImageColors(wineSummary) {
  // Get an array of image colors.
  // TODO: this is ridiculously slow.
  // Why not do it in the same step as the summary??
  // TODO: Generate sidebars (I think Anja asked for Mineralik/Süße) -- maybe also with canva?
  const prompt = `
Du bist ein Wein- und Farbassoziationsexperte.
Ich gebe dir eine Weinbeschreibung und du gibst eine Liste von ENGLISCHEN CSS-Farben im folgenden JSON-FORMAT zurück:

${ImageColorSchema}

WICHTIG: die Farben müssen gültige CSS-Farben sein.  Eine Liste der gültigen CSS-Farben ist wie folgt:
aliceblue, antiquewhite, aqua, aquamarine, azure, beige, bisque, black, blanchedalmond, blue, blueviolet, brown, burlywood, cadetblue, chartreuse, chocolate, coral, cornflowerblue, cornsilk, crimson, cyan, darkblue, darkcyan, darkgoldenrod, darkgray, darkgreen, darkgrey, darkkhaki, darkmagenta, darkolivegreen, darkorange, darkorchid, darkred, darksalmon, darkseagreen, darkslateblue, darkslategray, darkslategrey, darkturquoise, darkviolet, deeppink, deepskyblue, dimgray, dimgrey, dodgerblue, firebrick, floralwhite, forestgreen, fuchsia, gainsboro, ghostwhite, gold, goldenrod, gray, green, greenyellow, grey, honeydew, hotpink, indianred, indigo, ivory, khaki, lavender, lavenderblush, lawngreen, lemonchiffon, lightblue, lightcoral, lightcyan, lightgoldenrodyellow, lightgray, lightgreen, lightgrey, lightpink, lightsalmon, lightseagreen, lightskyblue, lightslategray, lightslategrey, lightsteelblue, lightyellow, lime, limegreen, linen, magenta, maroon, mediumaquamarine, mediumblue, mediumorchid, mediumpurple, mediumseagreen, mediumslateblue, mediumspringgreen, mediumturquoise, mediumvioletred, midnightblue, mintcream, mistyrose, moccasin, navajowhite, navy, oldlace, olive, olivedrab, orange, orangered, orchid, palegoldenrod, palegreen, paleturquoise, palevioletred, papayawhip, peachpuff, peru, pink, plum, powderblue, purple, rebeccapurple, red, rosybrown, royalblue, saddlebrown, salmon, sandybrown, seagreen, seashell, sienna, silver, skyblue, slateblue, slategray, slategrey, snow, springgreen, steelblue, tan, teal, thistle, tomato, turquoise, violet, wheat, white, whitesmoke, yellow, yellowgreen

Die Weinbeschreibung = ${wineSummary}`;

  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
  });
  const text = response.text ?? response.response?.text?.();
  const jsonStart = text.indexOf("{");
  const jsonEnd = text.lastIndexOf("}") + 1;
  const jsonString = text.substring(jsonStart, jsonEnd);

  return JSON.parse(jsonString);
}


export async function generateImage(colors) {
  // ref. https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
  // I know, I'm a sham, I just copied out the same code that ChatGPT is
  // copying from MDN in the background.
  const canvas = createCanvas(200, 200)
  const ctx = canvas.getContext('2d')
  const gradient = ctx.createRadialGradient(100, 100, 30, 100, 100, 100);
  const len = ImageColorMap.length;
  for (let i = 0, len = ImageColorMap.length; i < len; i++) {
    const color = colors[ImageColorMap[i][0]];
    gradient.addColorStop(i / (len - 1), convert.colorToHex(color));
  }
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 200, 200);
  return canvas.toBuffer("image/jpeg");
};