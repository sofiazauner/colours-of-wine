/* data extraction from wine labels */

import logger from "firebase-functions/logger";
import { parseMultipart, getMultipartBoundary } from "@remix-run/multipart-parser/node";
import { getAi, GeminiModel, admin, onWineRequest } from "./config.js";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";


// parameters for labelextraction
const GeminiLabelImagesPrompt = `
Du bist Experte für Weine und ihre Etiketten.
Analysiere die folgenden Weinetiketten (VORDER- UND RÜCKSEITE) gründlich.
Extrahiere und gebe die gesuchten Informationen im folgenden JSON-FORMAT zurück:
{
  "Name": "",
  "Winery": "",
  "Vintage": "",
  "Grape Variety": "",
  "Vineyard Location": "",
  "Country": ""
}

Versuche alle daten KORREKT herauszufinden.
Wenn eine Information NICHT angegeben ist, lasse das Feld LEER!
`;

const LabelSchema = zodToJsonSchema(z.object({
  "Name": z.string(),
  "Winery": z.string(),
  "Vintage": z.string(),
  "Grape Variety": z.string(),
  "Vineyard Location": z.string(),
  "Country": z.string(),
}));

/** Label front and back images. */
async function labelUserImages(front, back) {
  const contents = [
    { text: GeminiLabelImagesPrompt },
    { inlineData: { mimeType: "image/jpeg", data: front } },
    { inlineData: { mimeType: "image/jpeg", data: back } },
  ];
  const ai = await getAi()
  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: contents,
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: LabelSchema,
    }
  });
  return LabelSchema.parse(JSON.parse(response.text));
}


/** Ask Gemini to label the images. */
export const callGemini = onWineRequest(async (req, res, user) => {
  const contentType = req.get("Content-Type");
  if (req.method != "POST" || !contentType) {
    logger.info("Wrong method", {method: req.method, contentType: contentType});
    return res.status(400).send("Wrong request");
  }
  let front, back, token;
  const boundary = getMultipartBoundary(req.get('content-type'));
  for await (const part of parseMultipart(req.rawBody, {boundary: boundary})) {
    switch (part.name) {
    case 'front':
      front = Buffer.from(part.arrayBuffer).toString('base64');
      break;
    case 'back':
      back = Buffer.from(part.arrayBuffer).toString('base64');
      break;
    case 'token':
      token = part.text;
      break;
    }
  }
  const uid = user.uid;
  if (!front || !back) {
    logger.info("Wrong images", {front: !!front, back: !!back});
    return res.status(400).send("Wrong images");
  }
  let obj;
  try {
    obj = await labelUserImages(front, back);
  } catch (e) {
    logger.error("Failed to label images", {error: e});
    return res.status(500).send("Failed to call Gemini");
  }
  // send normalized JSON
  return res.status(200).send(JSON.stringify(obj));
});
