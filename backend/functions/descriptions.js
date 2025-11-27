/* fetch descriptions from web (serpAPi) */

import { onRequest } from "firebase-functions/https";
import logger from "firebase-functions/logger";
import { getSerpKey, admin, searchCollection } from "./config.js";
import { Readability } from "@mozilla/readability";
import { JSDOM } from 'jsdom';


// get descriptions from internet
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
  const serpApiKey = await getSerpKey();
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


// extract only decsription text from serp findings (TODO: maybe AI?)
export async function extractDescriptionsFromSerp(serpObj) {
  const descriptions = [];

  if (!serpObj.organic_results || !Array.isArray(serpObj.organic_results)) {
    return descriptions;
  }
  let maxPages = 1
  serpObj.organic_results = serpObj.organic_results.slice(0, maxPages)

  for (const item of serpObj.organic_results) {
    if (!item.link) continue; // or item.url

    try {
      const res = await fetch(item.link);
      const html = await res.text();

      const dom = new JSDOM(html, {
        url: item.link,
      });

      const reader = new Readability(dom.window.document);
      const article = reader.parse(); 

      descriptions.push({
        title: item.title,
        url: item.link,
        snippet: item.snippet,
        articleTitle: article.title,
        articleText: article.textContent,
      });
    } catch (err) {
      console.error("Fehler bei", item.link, err);
      descriptions.push({
        title: item.title,
        url: item.link,
        snippet: item.snippet,
        articleTitle: null,
        articleText: null,
        error: true,
      });
    }
  }

  return descriptions;
}
