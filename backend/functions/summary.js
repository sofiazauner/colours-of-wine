/* summarize descriptions from web */

import logger from "firebase-functions/logger";
import { getAi, GeminiModel, admin, WineComponents, onWineRequest } from "./config.js";
import { generateImage } from "./image.js";
import { z } from "zod";
import { zodToJsonSchema } from "zod-to-json-schema";


/**
 * Generate summary with loop of Writer and Reviewer until approved or max iterations reached.
 * Requires the client to send selected descriptions in the request body.
 * No fallback: if no descriptions are provided, no summary is generated. 
*/
export const generateSummary = onWineRequest(async (req, res, user) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method not allowed. Use POST.");
  }

  const q = req.body?.q;
  const descriptionsFromClient = req.body?.descriptions;

  if (!q) {
    logger.info("Missing q in generateSummary", { q });
    return res.status(400).send("Query missing");
  }

  if (!Array.isArray(descriptionsFromClient) || descriptionsFromClient.length === 0) {
    logger.info("No descriptions provided for generateSummary", {
      descriptions: descriptionsFromClient,
    });
    return res.status(400).send(
      "At least one description must be provided to generate a summary."
    );
  }

  const descriptionTexts = descriptionsFromClient.map((d) => {
      if (!d) return "";
      if (typeof d.articleText === "string" && d.articleText.trim().length > 0) {
        return d.articleText.trim();
      }
      if (typeof d.snippet === "string" && d.snippet.trim().length > 0) {
        return d.snippet.trim();
      }
      return "";
    }).filter((t) => t.length > 0);

  if (descriptionTexts.length === 0) {
    logger.info("All provided descriptions were empty", { q });
    return res.status(400).send("Provided descriptions do not contain usable text.");
  }

  let result;
  try {
    result = await buildValidatedSummaryFromDescriptions(descriptionTexts);
  } catch (e) {
    console.error(e);
    logger.error("Failed to generate validated summary", { error: e });
    return res.status(500).send("Failed to generate summary");
  }
  // generate image based on colors embedded into summary
  const image = await generateImage(result.colors);
  result.image = image.toString("base64");
  delete result.colors;

  return res.status(200).send(JSON.stringify(result));
});


/**
 * Operate the agentic writer/reviewer loop. Each iteration asks the reviewer to review the writer's output.
 * If MaxIterationCount is exceeded, the loop is stopped.
 */
const MaxIterationCount = 5;
async function buildValidatedSummaryFromDescriptions(descriptions) {
  if (!Array.isArray(descriptions) || descriptions.length === 0) {
    throw new TypeError("No descriptions available to summarize");
  }

  const start = new Date();
  let obj, review, prev;
  let iteration = 1;

  do {
    prev = obj;
    obj = await runWriterModel(descriptions, review?.feedback, prev);
    review = await runReviewerModel(descriptions, obj);
    logger.info("review", review);
    // Increase the iteration count by one. This prevents us from getting into an infinite loop.
    iteration++;
  } while (!review.approved && iteration < MaxIterationCount);

  const end = new Date();
  logger.info(`Wasted ${(end - start) / 1000} seconds of the user's time in ${iteration} iterations`);

  return {summary: obj.summary, colors: obj.colors, approved: review.approved};
}


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

const WriterModelZod = z.object({
  summary: z.string(),
  colors: (function() {
    const obj = {};
    const colors = z.enum(CSSColors)
    for (const it of WineComponents)
      obj[it] = colors;
    return z.object(obj);
  })()
});
const WriterModelSchema = zodToJsonSchema(WriterModelZod);

/** Writer-AI Agent: generate a summary of descriptions and colors, optionally taking feedback from the Reviewer Agent. */
async function runWriterModel(descriptions, feedback, prevObj) {
  const sourcesText = descriptions.map((d, i) => `Quelle ${i + 1}:\n${d}`).join("\n\n");
  const prompt = `
Du bist ein Wein- und Farbassoziationsexperte und Profi darin, gute, akkurate Weinbeschreibungen zu erstellen.

Hier sind mehrere Beschreibungen eines Weins aus dem Internet:${sourcesText}
${prevObj? `Hier ist der vorheriger Draft der erstellten Zusammenfassung und Farbassoziationen dieser Weine:\n${JSON.stringify(prevObj)}\n` : ""}
${feedback? `Hier hast du Feedback von einer Qualitätskontrolle-KI, das du zur Verbesserung des vorherigen Drafts nutzen sollst:\n${feedback}\n` : ""}

Deine Aufgabe ist es, eine einheitliche, konsistente Zusammenfassung der bereitgestellten Weinbeschreibungen zu erstellen.
Nachdem du die Zusammenfassung erstellt hast, musst du außerdem eine Liste von ENGLISCHEN CSS-Farben erstellen.

Wähle Formulierung und Länge so, wie du es für am besten hältst.

WICHTIG:
- Fasse die wichtigsten Infos zusammen (Stil, Aroma, Herkunft, Charakter, Mineralik/Süße, Komplexität, Holzeinsatz/Ausbaustil, Intensität, Säure, Fruchtcharacter, Nicht-Frucht Komponenten).
- Nutze die bereitgestellten Quellen als einzige Informationsquelle.
- Erfinde keine Fakten, die in den Quellen nicht zumindest implizit angelegt sind.
- Schreibe neutral und informativ.
- Gebe unbedingt die Zusammenfassung erst aus, vor dem du die Farbassoziationen erstellst. Am Ende musst du dann sowohl diese Zusammenfassung als auch die Farbassoziationen ausgeben.
- Die Farbassoziationen sollen gültige CSS-Farben sein.
- Deine Ausgabe MUSS ausschließlich im folgenden JSON-Format sein:

{
  "summary": "DEINE ZUSAMMENFASSUNG HIER",
  "colors": {
    "Holzeinsatz": "FARBE FÜR HOLZEINSATZ/AUSBAUSTIL",
    "Mousseux": "FARBE FÜR MOUSSEUX",
    "Säure": "FARBE FÜR SÄURE",
    "Fruchtcharacter": "FARBE FÜR FRUCHTCHARACTER",
    "Nicht-Frucht-Komponenten": "FARBE FÜR NICHT-FRUCHT-KOMPONENTEN",
    "Körper": "FARBE FÜR KÖRPER/BALANCE",
    "Tannin": "FARBE FÜR TANNIN",
    "Reifearomen": "FARBE FÜR REIFEAROMEN"
  }
}`;
  const ai = await getAi()
  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: WriterModelSchema
    }
  });

  return WriterModelZod.parse(JSON.parse(response.text));
}


const ReviewerModelZod = z.object({
  approved: z.boolean(),
  feedback: z.string(),
});
const ReviewerModelSchema = zodToJsonSchema(ReviewerModelZod);

/** Reviewer-AI Agent: review a summary and colors and provide feedback. */
async function runReviewerModel(descriptions, obj) {
  const sourcesText = descriptions.map((d, i) => `Quelle ${i + 1}:\n${d}`).join("\n\n");
  const prompt = `
Du bist eine unabhängige Qualitätskontrolle-KI für Weinzusammenfassungen und Farbassoziationen.

Hier sind die Quellen der Ursprungsbeschreibungen (Beschreibungen aus dem Web):${sourcesText}

Hier ist die Zusammenfassung mit Farbassoziatonen, die überprüft werden soll:"${JSON.stringify(obj)}"

Deine Aufgabe:
- Prüfe, ob die Zusammenfassung die Kernaussagen der Quellen korrekt und vollständig widerspiegelt.
- Prüfe, ob nichts grob Falsches erfunden wurde.
- Prüfe, ob die Zusammenfassung ausreichend informativ ist.
- Prüfe, ob die Zusammenfassung aussagekräftig und ansprechend formuliert ist.
- Prüfe, ob der Zusammenfassung wichtige Details fehlen.
- Prüfe, ob Stil und Klarheit für eine Weinbeschreibung geeignet sind.
- Prüfe, ob die Farben zu den bestimmten Aspekten des Weines gut passen.
- Gib konstruktives Feedback zur Verbesserung der Zusammenfassung und der Farben, falls nötig.

WICHTIG:
- Wenn die Zusammenfassung in Ordnung ist, stimme zu.
- Wenn die Zusammenfassung Mängel aufweist, lehne ab und gib konkretes Feedback zur Verbesserung.
-  Deine Ausgabe MUSS ausschließlich im folgenden JSON-Format sein:

{
  "approved": true/false,
  "feedback": "Kurze Begründung + konkretes Feedback zur Verbesserung, falls (approved == false)"
}`;
  const ai = await getAi()
  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: [{ text: prompt }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: ReviewerModelSchema
    }
  });

  return ReviewerModelZod.parse(JSON.parse(response.text));
}
