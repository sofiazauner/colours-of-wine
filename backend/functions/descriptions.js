/* fetch descriptions from web (serpAPi) */

import logger from "firebase-functions/logger";
import { getSerpKey, admin, searchCollection, onWineRequest } from "./config.js";
import { parseMultipart, getMultipartBoundary } from "@remix-run/multipart-parser/node";
import { Readability } from "@mozilla/readability";
import { JSDOM } from 'jsdom';
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';

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

  // Create history entry now (later we will update the same document with summary + image)
  const docRef = await searchCollection.add({
    uid: uid,
    name: name,
    descriptions: descriptions,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Attach created history document id so the client can later persist summary/image into the same entry
  if (serpObj) {
    serpObj.historyId = docRef.id;
  }

  if (Array.isArray(serpObj.organic_results)) {
    const max = Math.min(serpObj.organic_results.length, descriptions.length);
    for (let i = 0; i < max; i++) {
      const it = serpObj.organic_results[i];
      const d = descriptions[i];

      it.articleTitle = d.articleTitle ?? null;
      it.articleText = d.articleText ?? null;
      it.articleSnippet = d.snippet ?? null;
      it.articleUrl = d.url ?? null;
      it.articleError = d.error ?? false;
    }
  }

  return res.status(200).json(serpObj);
});


/* https://stackoverflow.com/a/55263651 */
async function getPageText(pdf, pageNo) {
  const page = await pdf.getPage(pageNo);
  const tokenizedText = await page.getTextContent();
  return tokenizedText.items.map(token => token.str).join("");;
};

async function getPDFText(source) {
  const pdf = await getDocument(source).promise;
  const maxPages = pdf.numPages;
  const pageTextPromises = [];
  for (let pageNo = 1; pageNo <= maxPages; pageNo += 1) {
    pageTextPromises.push(getPageText(pdf, pageNo));
  }
  const pageTexts = await Promise.all(pageTextPromises);
  return pageTexts.join(" ");
};

/** Add custom description. */
export const addFileDescription = onWineRequest(async (req, res, user) => {
  const contentType = req.get("Content-Type");
  if (req.method != "POST" || !contentType) {
    logger.info("Wrong method", {method: req.method, contentType: contentType});
    return res.status(400).send("Wrong request");
  }
  let name, bytes;
  const boundary = getMultipartBoundary(req.get('content-type'));
  for await (const part of parseMultipart(req.rawBody, {boundary: boundary})) {
    name = part.filename;
    bytes = part.arrayBuffer;
  }
  if (!name.toLowerCase().endsWith(".pdf")) {
    return res.status(401).send("only PDF and txt descriptions allowed");
  }
  const text = await getPDFText(bytes);
  return res.status(200).json(text);
});


/** Fetch a single page and extract its text. */
async function extractSingleDescription(url) {
  console.log("fetch", url)
  const res = await fetch(url);
  if (res.status != 200)
    throw new TypeError(`Fetching link returned status code ${res.status}`);

  const html = await res.text();
  const dom = new JSDOM(html, {
    url: url,
  })
  const reader = new Readability(dom.window.document);
  return reader.parse();
}

/** Add custom description from URL. */
export const addURLDescription = onWineRequest(async (req, res, user) => {
  const url = decodeURIComponent(req.query.q);
  let article;
  try {
    article = await extractSingleDescription(url);
  } catch (e) {
    logger.error("Failed to fetch URL", {url: url, error: e});
    return res.status(500).send("Error fetching URL");
  }
  return res.status(200).json({
    title: article.title,
    text: article.textContent,
    snippet: article.excerpt
  });
});


/** Extract only decsription text from serp findings. */
// maxPages limits how many results we process; must match the maximal amount of selectable sources for the user
export async function extractDescriptionsFromSerp(serpObj) {
  if (!serpObj.organic_results || !Array.isArray(serpObj.organic_results)) {
    return [];
  }

  const maxPages = 7;
  const items = serpObj.organic_results.slice(0, maxPages);

  // parallel handling of all websites
  const promises = items.filter(item => item.link != null).map(async (item) => {
    try {
      const article = await extractSingleDescription(item.link);

      return {
        title: item.title,
        url: item.link,
        articleTitle: article.title ?? item.title ?? "",
        articleText: article.textContent ?? "",
        snippet: article.excerpt ?? "",
        error: false
      };
    } catch (err) {
      console.error("Error in", item.link, err);
      return {
        title: item.title,
        url: item.link,
        articleTitle: item.title ?? "",
        articleText: "",
        snippet: "",
        error: true
      };
    }
  });

  const results = await Promise.all(promises);

  // normalize to client structure (Map<String,String>)
  return results.map((r) => {
    return {
      articleTitle: r.articleTitle ?? "",
      articleText: r.articleText ?? "",
      snippet: r.snippet ?? "",
      url: r.url ?? "",
      error: r.error ?? false,
    };
  });
}
