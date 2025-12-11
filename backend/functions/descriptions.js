/* fetch descriptions from web (serpAPi) */

import logger from "firebase-functions/logger";
import { getSerpKey, admin, searchCollection, onWineRequest } from "./config.js";
import { Readability } from "@mozilla/readability";
import { JSDOM } from 'jsdom';


const AllowedDomains = [
  "winefolly.com",
  "decanter.com",
  "wineenthusiast.com",
  "wine.com",
  "vivino.com",
  "wine-searcher.com",
  "jancisrobinson.com",
  "vinous.com",
  "jamessuckling.com",
  "winespectator.com",
  "falstaff.de",
  "wein.plus",
  "cellartracker.com",
  "vicampo.de"
];

const SiteFilter = AllowedDomains.map(x => `site:${x}`).join(" OR ");


/** Get descriptions from the Internet. */
export const fetchDescriptions = onWineRequest(async (req, res, user) => {
  // check parameters
  const q = req.query.q;
  const nameParam = req.query.name;

  if (!q) {
    logger.info("Wrong q", {q: req.query.q});
    return res.status(400).send("Query missing");
  }
  // call SerpApi
  const serpApiKey = await getSerpKey();
  const serpUrl = new URL("https://serpapi.com/search.json"); 
  const filteredQuery = `${q} (${SiteFilter})`;
  serpUrl.searchParams.set("q", filteredQuery ); 
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

  const uid = user.uid;
  const name = nameParam || "No Name was Registered";

  await searchCollection.add({
      uid: uid,
      name: name,
      descriptions: descriptions,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
   });

   if (Array.isArray(serpObj.organic_results)) {
    const max = Math.min(serpObj.organic_results.length, descriptions.length);
    for (let i = 0; i < max; i++) {
      const it = serpObj.organic_results[i];
      const d = descriptions[i];

      it.articleTitle = d.articleTitle ?? null;
      it.articleText = d.articleText ?? null;
      it.articleError = d.error ?? false;
    }
  }

  return res.status(200).json(serpObj);
});


/** Extract only decsription text from serp findings. */
// maxPages limits how many results we process; must match the maximal amount of selectable sources for the user
export async function extractDescriptionsFromSerp(serpObj) {
  if (!serpObj.organic_results || !Array.isArray(serpObj.organic_results)) {
    return [];
  }

  const maxPages = 7;
  const items = serpObj.organic_results.slice(0, maxPages);

  // parallel handling of all 10 websites
  const promises = items.map(async (item) => {
    if (!item.link) {
      return null;
    }

    try {
      const res = await fetch(item.link);
      const html = await res.text();
      const dom = new JSDOM(html, {
        url: item.link,
      })
      const reader = new Readability(dom.window.document);
      const article = reader.parse();

      if (!article) {
        return {
          title: item.title,
          url: item.link,
          snippet: item.snippet,
          articleTitle: null,
          articleText: null,
          error: true,
        };
      }

      return {
        title: item.title,
        url: item.link,
        snippet: item.snippet,
        articleTitle: article.title,
        articleText: article.textContent,
      };
    } catch (err) {
      console.error("Error in", item.link, err);
      return {
        title: item.title,
        url: item.link,
        snippet: item.snippet,
        articleTitle: null,
        articleText: null,
        error: true,
      };
    }
  });

  const results = await Promise.all(promises);

  // filter out null entries
  return results.filter((x) => x !== null);
}
