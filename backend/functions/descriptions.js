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
  const maxPages = 7;

  if (!q) {
    logger.info("Wrong q", {q: req.query.q});
    return res.status(400).send("Query missing");
  }
  let filteredQuery = `${q} ${SiteFilter}`;
  const serpApiKey = await getSerpKey();
  // call SerpApi (we might have to do two passes)
  for (let i = 0; i < 2; i++) {
    const serpUrl = new URL("https://serpapi.com/search.json"); 
    serpUrl.searchParams.set("q", filteredQuery); 
    serpUrl.searchParams.set("api_key", serpApiKey); 
    serpUrl.searchParams.set("hl", "en"); 

    const serpRes = await fetch(serpUrl.toString()); 
    const serpText = await serpRes.text(); 

    if (serpRes.status != 200) { 
      logger.info("SERP error", {status: serpRes.status, msg: serpText});
      return res.status(500).send("Error in SERP");
    } 
    // get descriptions and add it to history
    let serpObj;
    try {
      serpObj = JSON.parse(serpText);
    } catch (e) {
        logger.error("Failed to parse SERP JSON", { error: e, body: serpText });
    }

    const items = (serpObj.organic_results ?? [])
      .slice(0, maxPages)
      .filter(item => item.link != null);
    if (items.length == 0) {
      console.log(`nothing found for ${filteredQuery}, try again with a more general query`);
      filteredQuery = `${q} review OR beschreibung`;
      continue;
    }
    const descriptions = await Promise.all(items.map(async item => {
      const res = {
        title: item.title || "Untitled",
        url: item.link,
        snippet: item.snippet,
      };
      try {
        const article = await extractSingleDescription(item.link);
        res.articleTitle = article.title;
        res.articleText = article.textContent;
      } catch (err) {
        console.error("Error in", item.link, err);
      }
      return res;
    }));
    return res.status(200).json(descriptions);
  }
  console.log("Nothing found!");
  return res.status(200).json([]);
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
