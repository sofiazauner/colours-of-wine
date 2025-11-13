/* Colours of wine backend, designed to run as Google Cloud Functions. */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import logger from "firebase-functions/logger";
import {parseMultipart, getMultipartBoundary} from "@remix-run/multipart-parser/node";
import {GoogleGenAI} from "@google/genai";
import admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";

/* maximum number of containers that can be running at the same time */
setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

const db = getFirestore("wine-data");
const searchCollection = db.collection("/search-history");

const serpApiKey = "ec05db9a150499c3e869cb95e63a146a5b1dce6257c1042bf89c340bf2c22d1a";   // SerpApi key

/* Look up a wine in the SERP API. */
export const searchWine = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
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
  return res.status(200).send(serpText);
});

/* Get a list of wines searched until now.
 * TODO: I think we can do this directly from flutter too, but anyway
 */
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
  queryResult.forEach(item => {
    docs.push(item.data().label);
  });
  console.log("userHistory", docs);
  return res.status(200).send(JSON.stringify(docs));
});

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

Wenn eine Information NICHT angegeben ist, lasse das Feld LEER!
`;

const ai = new GoogleGenAI({apiKey: GeminiAPIKey});

async function labelUserImages(front, back) {
  const contents = [
    { text: GeminiLabelImagesPrompt },
    { inlineData: { mimeType: "image/jpeg", data: front } },
    { inlineData: { mimeType: "image/jpeg", data: back } },
  ];
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    contents: contents,
  });
  /* try to look up the JSON object inside the response in case we get
     some other garbage around it */
  const jsonStart = response.text.indexOf("{");
  const jsonEnd = response.text.lastIndexOf("}") + 1;
  const jsonString = response.text.substring(jsonStart, jsonEnd);
  return JSON.parse(jsonString);
}

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
  for await (let part of parseMultipart(req.rawBody, {boundary: boundary})) {
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
  const writeResult = await searchCollection.add({
    uid: uid,
    label: obj
  });
  logger.info("Added", {result: writeResult});
  /* send normalized JSON */
  return res.status(200).send(JSON.stringify(obj));
});
