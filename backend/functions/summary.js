/* summarize descriptions from web */

import { onRequest } from "firebase-functions/https";
import logger from "firebase-functions/logger";
import { serpApiKey, ai, GeminiModel, admin } from "./config.js";
import { extractDescriptionsFromSerp } from "./descriptions.js";
import { generateImageColors, generateImage } from "./image.js";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";

// (TODO: Don't search for descriptions again, use the onse already fetched!)
// --> Maybe merge the functions; get descriptions and summarize(+image) at the same time?

// generate summary with loop of Writer and Reviewer until approved or max iterations reached 
export const generateSummary = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  // check parameters
  if (!req.query.q) {
    logger.info("Wrong q", {q: req.query.q});
    return res.status(400).send("Query missing");
  }
  const token = req.query.token;
  try {
    await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
  // call SerpApi to get descriptions
  const serpUrl = new URL("https://serpapi.com/search.json"); 
  serpUrl.searchParams.set("q", req.query.q); 
  serpUrl.searchParams.set("api_key", serpApiKey); 
  serpUrl.searchParams.set("hl", "en"); 

  const serpRes = await fetch(serpUrl); 
  const serpText = await serpRes.text(); 

  if (serpRes.status != 200) { 
    logger.info("SERP error", {status: serpRes.status, msg: serpText});
    return res.status(500).send("Error in SERP");
  } 
  // parse response
  let serpObj;
  try {
    serpObj = JSON.parse(serpText);
  } catch (e) {
    logger.error("Failed to parse SERP JSON", { error: e, body: serpText });
    return res.status(500).send("Failed to parse SERP response");
  }
  // generate summary using Gemini (with feedback loop)
  const result = await buildValidatedSummaryFromSerp(serpObj);
  // generate image based on summary
  const colors = await generateImageColors(result.summary);
  const image = await generateImage(colors);

  // (TODO: this ought to be multipart, transporting JPEG as base64 is a joke!)
  result.image = image.toString('base64');
  return res.status(200).send(JSON.stringify(result));
});
 
// (TODO: waiting for a single iteration takes tens of seconds, 2 is already
// a stretch.  The original value was 25, but after 25 iterations even the
// Buddha himself will uninstall the app.)
// ^^^ above applies to flash, but that doesn't always work in the first
// place.  Turns out flash lite does the thing in 4s with 2 iters.  Still
// unclear what the ideal number is, extrapolating from the above 5 iters
// are already 10s which feels annoying enough.

// operate wirter/reviewer-loop
const MaxIterations = 5;
async function buildValidatedSummaryFromSerp(serpObj) {
  const descriptions = await extractDescriptionsFromSerp(serpObj);

  if (descriptions.length === 0) {
    throw new Error("No descriptions available from SERP to summarize");
  }

  const start = new Date();
  let summary = await runWriterModel(descriptions);
  let review = await runReviewerModel(descriptions, summary);
  let prevSummary;
  let iteration = 1;

  while (!review.approved && iteration < MaxIterations) {
    prevSummary = summary;
    summary = await runWriterModel(descriptions, review.feedback, prevSummary);
    review = await runReviewerModel(descriptions, summary);
    iteration++;
  }
  const end = new Date();
  logger.info(`Wasted ${(end - start) / 1000} seconds of the user's time in ${iteration} iterations`);

  return {summary, approved: review.approved};
}


const WriterModelSchema = zodToJsonSchema(z.object({
  summary: z.string(),
}));

// writer-AI: generates Summary of descriptions (+ Feedback)
async function runWriterModel(descriptions, feedback, prevSummary) {
  const sourcesText = descriptions.map((d, i) => `Quelle ${i + 1}:\n${d}`).join("\n\n");
  const prompt = `
Du bist ein Weinexperte und Profi darin, gute, akkurate Weinbeschreibungen zu erstellen.

Hier sind mehrere Beschreibungen eines Weins aus dem Internet:${sourcesText}
${prevSummary? `Hier ist der vorheriger Draft der erstellten Zusammenfassung dieser Weine:\n${prevSummary}\n` : ""}
${feedback? `Hier hast du Feedback von einer Qualitätskontrolle-KI, das du zur Verbesserung des vorherigen drafts nutzen sollst:\n${feedback}\n` : ""}

Deine Aufgabe ist es, eine einheitliche, konsistente Zusammenfassung der bereitgestellten Weinbeschreibungen zu erstellen.

Wähle Formulierung und Länge so, wie du es für am besten hältst.

WICHTIG:
- Fasse die wichtigsten Infos zusammen (Stil, Aroma, Herkunft, Charakter, Mineralik/Süße, Komplexität, Holzeinsatz/Ausbaustil, Intensität, Säure, Fruchtcharacter, Nicht-Frucht Komponenten).
- Nutze die bereitgestellten Quellen als einzige Informationsquelle.
- Erfinde keine Fakten, die in den Quellen nicht zumindest implizit angelegt sind.
- Schreibe neutral und informativ.
- Deine Ausgabe MUSS ausschließlich im folgenden JSON-Format sein:

{
  "summary": "DEINE ZUSAMMENFASSUNG HIER"
}`;

  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: WriterModelSchema
    }
  });

  const obj = JSON.parse(response.text);
  return obj.summary;
}


const ReviewerModelSchema = zodToJsonSchema(z.object({
  approved: z.boolean(),
  summary: z.string(),
}));

// reviewer-AI: reviews Summary and provides feedback
async function runReviewerModel(descriptions, summary) {
  const sourcesText = descriptions.map((d, i) => `Quelle ${i + 1}:\n${d}`).join("\n\n");
  const prompt = `
Du bist eine unabhängige Qualitätskontrolle-KI für Weinzusammenfassungen.

Hier sind die Quellen der Ursprungsbeschreibungen (Beschreibungen aus dem Web):${sourcesText}

Hier ist die Zusammenfassung, die überprüft werden soll:"${summary}"

Deine Aufgabe:
- Prüfe, ob die Zusammenfassung die Kernaussagen der Quellen korrekt und vollständig widerspiegelt.
- Prüfe, ob nichts grob Falsches erfunden wurde.
- Prüfe, ob die Zusammenfassung ausreichend informativ ist.
- Prüfe, ob die Zusammenfassung aussagekräftig und ansprechend formuliert ist.
- Prüfe, ob der Zusammenfassung wichtige Details fehlen.
- Prüfe, ob Stil und Klarheit für eine Weinbeschreibung geeignet sind.
- Gib konstruktives Feedback zur Verbesserung der Zusammenfassung, falls nötig.

WICHTIG:
- Wenn die Zusammenfassung in Ordnung ist, stimme zu.
- Wenn die Zusammenfassung Mängel aufweist, lehne ab und gib konkretes Feedback zur Verbesserung.
-  Deine Ausgabe MUSS ausschließlich im folgenden JSON-Format sein:

{
  "approved": true/false,
  "feedback": "Kurze Begründung + konkretes Feedback zur Verbesserung, falls (approved == false)"
}`;

  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: ReviewerModelSchema
    }
  });

  return JSON.parse(response.text);
}
