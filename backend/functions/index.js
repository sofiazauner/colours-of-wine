/* Colours of wine backend, designed to run as Google Cloud Functions. */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import logger from "firebase-functions/logger";
import {parseMultipart, getMultipartBoundary} from "@remix-run/multipart-parser/node";
import {GoogleGenAI} from "@google/genai";
import admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";
import {createCanvas, loadImage} from 'canvas';
import {convert, resolve, utils} from '@asamuzakjp/css-color';


/* maximum number of containers that can be running at the same time */
setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();
const db = getFirestore("wine-data");
const searchCollection = db.collection("/search-history");


/* Extract Data from label-images using Gemini.*/
// Parameters for labelextraction
const GeminiModel = "gemini-2.5-flash";
const GeminiURL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GeminiModel}:generateContent`;
const GeminiAPIKey = "AIzaSyC_u49bnxvaObp-2vVXSc0TvSLgQWqyT7c";
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
const ai = new GoogleGenAI({apiKey: GeminiAPIKey});

// Extraction Process
async function labelUserImages(front, back) {
  const contents = [
    { text: GeminiLabelImagesPrompt },
    { inlineData: { mimeType: "image/jpeg", data: front } },
    { inlineData: { mimeType: "image/jpeg", data: back } },
  ];
  const response = await ai.models.generateContent({
    model: GeminiModel,
    contents: contents,
  });
  // try to look up the JSON object inside the response in case we get some other garbage around it 
  const jsonStart = response.text.indexOf("{");
  const jsonEnd = response.text.lastIndexOf("}") + 1;
  const jsonString = response.text.substring(jsonStart, jsonEnd);
  return JSON.parse(jsonString);
}

// analysis process (uses the extraction process)
export const callGemini = onRequest(async (req, res) => {
  /* allow CORS (for testing mainly) */
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    return res.status(204).send('');
  }
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
  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
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


/*SerpApi Functions -->*/
const serpApiKey = "ec05db9a150499c3e869cb95e63a146a5b1dce6257c1042bf89c340bf2c22d1a";   // SerpApi key

/* 1.) Look up wine descriptions in the SERP API. */
export const fetchDescriptions = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  // check parameters
  const q = req.query.q;
  const token = req.query.token;
  const nameParam = req.query.name

   if (!q) {
    logger.info("Wrong q", {q: req.query.q});
    return res.status(400).send("Query missing");
  }
  try {
    await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
  // call SerpApi
  const serpUrl = new URL("https://serpapi.com/search.json"); 
  serpUrl.searchParams.set("q", q); 
  serpUrl.searchParams.set("api_key", serpApiKey); 
  serpUrl.searchParams.set("hl", "en"); 

  const serpRes = await fetch(serpUrl.toString()); 
  const serpText = await serpRes.text(); 

  if (serpRes.status != 200) { 
    logger.info("SERP error", {status: serpRes.status, msg: serpText});
    return res.status(500).send("Error in SERP");
  } 
  // get descriptions and add it to history
  let serpObj
  try {
    serpObj = JSON.parse(serpText);
  } catch (e) {
      logger.error("Failed to parse SERP JSON", { error: e, body: serpText });
  }

  let descriptions;
    if (serpObj) {
      descriptions = await extractDescriptionsFromSerp(serpObj);
    }

  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
  const uid = user.uid;
  const name = nameParam || "No Name was Registered"
  ;

  await searchCollection.add({
      uid: uid,
      name: name,
      descriptions: descriptions,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
   });

  return res.status(200).send(serpText);
});




/* 2.) Generate summary (get descriptions with Serp and summarize with Gemini)*/
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

  const colors = await generateImageColors(result.summary);
  const image = await generateImage(colors);

  /* TODO this ought to be multipart, transporting JPEG as base64 is a joke */
  result.image = image.toString('base64');
  return res.status(200).send(JSON.stringify(result));
});


/* loop of Writer and Reviewer until approved or max iterations reached */
 
/* TODO: waiting for a single iteration is tens of seconds of pain and
 * suffering, 2 is already a stretch.  The original value was 25, but after
 * 25 iterations even the Buddha himself will uninstall the app.
 */
const MaxIterations = 3;
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

/*Writer-AI: generates Summary of descriptions (+ Feedback)*/
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
  });

  const text = response.text ?? response.response?.text?.();

  const jsonStart = text.indexOf("{");
  const jsonEnd = text.lastIndexOf("}") + 1;
  const jsonString = text.substring(jsonStart, jsonEnd);

  const obj = JSON.parse(jsonString);
  if (!obj.summary || typeof obj.summary !== "string") {
    throw new Error("Writer model did not return a valid summary JSON");
  }

  return obj.summary;
}


/*Reviewer-AI: reviews Summary and provides feedback*/
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
  });

  const text = response.text ?? response.response?.text?.();

  const jsonStart = text.indexOf("{");
  const jsonEnd = text.lastIndexOf("}") + 1;
  const jsonString = text.substring(jsonStart, jsonEnd);

  const obj = JSON.parse(jsonString);

  return {
    approved: Boolean(obj.approved),
    feedback: typeof obj.feedback === "string" ? obj.feedback : "",
  };
}



/* Extracts descriptions from serp response */
//(TODO: No only uses snippets, need to find way to use whole descriptions (AI od web scraping?))
// --> Therefore summaries also not really good yet ++ Database also only stores snippets so far

/* Extracts descripiond from serp response*/ 
function extractDescriptionsFromSerp(serpObj) { 
  const descriptions = []; 
  if (serpObj.organic_results && Array.isArray(serpObj.organic_results)) 
    { for (const item of serpObj.organic_results) 
      { if (item.snippet && typeof item.snippet === "string") 
        { descriptions.push(item.snippet); } 
      } 
    } 
  return descriptions; 
}


/* Generate Image */
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

async function generateImageColors(wineSummary) {
  /* Get an array of image colors.
   * TODO: this is ridiculously slow.
   * Why not do it in the same step as the summary??
   */
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

async function generateImage(colors) {
  /* ref. https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
   * I know, I'm a sham, I just copied out the same code that ChatGPT is
   * copying from MDN in the background.
   */
  const canvas = createCanvas(200, 200)
  const ctx = canvas.getContext('2d')
  const gradient = ctx.createRadialGradient(100, 100, 30, 100, 100, 100);
  const len = ImageColorMap.length;
  for (let i = 0, len = ImageColorMap.length; i < len; i++) {
    const color = colors[ImageColorMap[i][0]];
    gradient.addColorStop(i / (len - 1), convert.colorToHex(color));
  }
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 400, 400);
  return canvas.toBuffer("image/jpeg");
};

/* Handle previous searches */

// Retrieves the search history for a user based on their token
export const searchHistory = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  const token = req.query.token;
  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    logger.info("Wrong token", {token: token, error: e});
    return res.status(401).send("Wrong token");
  }
  const uid = user.uid;
  const queryResult = await searchCollection.where("uid", "==", uid).get();
  let docs = [];
  queryResult.forEach((doc) => {
    const data = doc.data();
    docs.push({
      id: doc.id,
      name: data.name ?? "",
      descriptions: Array.isArray(data.descriptions) ? data.descriptions : [],
      createdAt: data.createdAt ? data.createdAt.toMillis() : null,
    });
  });
  return res.status(200).send(JSON.stringify(docs));
});

// Deletes a previous wine search from the user's history
export const deleteSearch = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method !== "POST") {
    return res.status(405).send("Only POST allowed");
  }

  const token = req.query.token;
  const id = req.query.id;

  if (!id) return res.status(400).send("Missing document id");

  let user;
  try {
    user = await admin.auth().verifyIdToken(token);
  } catch (e) {
    return res.status(401).send("Wrong token");
  }

  const uid = user.uid;

  const docRef = searchCollection.doc(id);
  const docSnap = await docRef.get();

  if (!docSnap.exists || docSnap.data().uid !== uid) {
    return res.status(403).send("Forbidden");
  }

  await docRef.delete();
  return res.status(200).send("Deleted");
});



//cd C:\Users\sofia\SoftwarePraktikum\backend\functions
//firebase emulators:start   (needs to run while executing the App)
